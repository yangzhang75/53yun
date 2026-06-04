//
//  LocalRuleRecommender.swift
//  AICompanionCore
//
//  本地规则引擎兜底：无网络也能给出合理配方。
//  产出标准 `Recipe`（交给 Engine 计算精确兑制），本包不实现度数公式。
//

import Foundation

public struct LocalRuleRecommender: RecipeRecommending {

    /// 各香型基酒原始度数（高度白酒）。
    private static let baseABV: [AromaType: Double] = [
        .jiangxiang: 53, // 53° 雲·酱香
        .nongxiang: 52,
        .qingxiang: 48
    ]

    /// 默认参考基酒体积（mL）。用户在计算器里可调，Engine 据此算稀释液用量。
    private let baseVolumeML: Double

    public init(baseVolumeML: Double = 100) {
        self.baseVolumeML = baseVolumeML
    }

    public func recommend(for query: BartenderQuery) async throws -> Recommendation {
        let trimmed = query.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty || !query.fruitHints.isEmpty else {
            throw BartenderError.emptyQuery
        }
        let intent = NaturalLanguageParser.parse(trimmed)
        return build(from: intent, query: query)
    }

    // MARK: - 规则装配

    func build(from intent: ParsedIntent, query: BartenderQuery) -> Recommendation {
        let aroma = intent.aroma ?? .jiangxiang // 品牌主打酱香兜底
        let base = Self.baseABV[aroma] ?? 53

        // 目标度数：显式 > 口味推断 > 默认
        let targetABV = resolveTargetABV(intent: intent, base: base)

        // 兑法：显式 > 据度数/口味推断
        let method = resolveMethod(intent: intent, targetABV: targetABV, base: base)

        // 风味画像（0~1）
        let flavor = resolveFlavor(intent: intent, targetABV: targetABV, base: base)

        // 组装可载入计算器的标准 Recipe：
        // - 基酒成分（aroma 对应原始度数）
        // - 稀释液成分（abv 0；体积留 0，由 Engine 据 targetABV 计算）
        var components = [Component(volumeML: baseVolumeML, abv: base)]
        if let diluentABV = method.diluentABV {
            components.append(Component(volumeML: 0, abv: diluentABV))
        }
        if !query.fruitHints.isEmpty {
            // 果味为风味点缀，不计入度数（abv 0、体积 0 占位，提示前端可加少量）
            components.append(Component(volumeML: 0, abv: 0))
        }

        let headline = makeHeadline(aroma: aroma, targetABV: targetABV, method: method)
        let recipe = Recipe(
            name: headline,
            aroma: aroma,
            components: components,
            targetABV: targetABV,
            tastingNote: makeTastingNote(aroma: aroma, intent: intent, method: method),
            flavor: flavor
        )

        return Recommendation(
            headline: headline,
            aroma: aroma,
            method: method,
            ratioSummary: estimatedRatio(base: base, target: targetABV, method: method),
            steps: makeSteps(aroma: aroma, base: base, target: targetABV, method: method, fruitHints: query.fruitHints),
            rationale: makeRationale(aroma: aroma, intent: intent, targetABV: targetABV, method: method, query: query),
            recipe: recipe,
            source: .localRules,
            confidence: confidence(for: intent)
        )
    }

    // MARK: - 各维决策

    private func resolveTargetABV(intent: ParsedIntent, base: Double) -> Double {
        if let abv = intent.targetABV { return clampABV(abv, base: base) }
        if intent.wantsLight { return 10 }
        if intent.wantsStrong { return min(base, 45) }
        if intent.wantsMellow { return 20 }
        return 16 // 通用微醺
    }

    /// 目标度数不应超过基酒原始度数（兑制只会降度）。
    private func clampABV(_ abv: Double, base: Double) -> Double {
        min(max(abv, 1), base)
    }

    private func resolveMethod(intent: ParsedIntent, targetABV: Double, base: Double) -> MixingMethod {
        if let m = intent.method { return m }
        if targetABV >= base - 0.5 { return .neat }   // 几乎不降度 → 净饮
        if intent.wantsLight { return targetABV <= 12 ? .soda : .ice }
        if targetABV <= 14 { return .ice }
        return .water
    }

    private func resolveFlavor(intent: ParsedIntent, targetABV: Double, base: Double) -> FlavorProfile {
        // 劲道随目标度数线性升高；绵柔随口味诉求与降度幅度升高。
        let strength = min(1, max(0.05, targetABV / 60))
        var mellow = 0.4 + (1 - targetABV / base) * 0.4
        if intent.wantsMellow { mellow += 0.2 }
        if intent.wantsLight { mellow += 0.1 }
        mellow = min(1, max(0, mellow))
        return FlavorProfile(mellow: mellow, strength: strength)
    }

    private func confidence(for intent: ParsedIntent) -> Double {
        // 命中越多越自信；本地引擎上限 0.85，给云端留余地。
        min(0.85, 0.4 + Double(intent.matchScore) * 0.1)
    }

    // MARK: - 文案

    private func makeHeadline(aroma: AromaType, targetABV: Double, method: MixingMethod) -> String {
        let degree: String
        switch targetABV {
        case ..<13: degree = "低度"
        case ..<28: degree = "中度"
        default: degree = "高度"
        }
        return "\(aroma.displayName)\(degree)·\(method.displayName)"
    }

    /// 展示用估算配比（基酒 : 稀释液）。**仅供参考**，精确体积/标准杯由 Engine 计算。
    private func estimatedRatio(base: Double, target: Double, method: MixingMethod) -> String {
        guard method.diluentABV != nil, target < base, target > 0 else {
            return "净饮 · 不稀释（精确数据以计算器为准）"
        }
        // 估算：稀释液份数 = (base - target) / target（基酒 1 份）。
        let parts = (base - target) / target
        let rounded = (parts * 10).rounded() / 10
        return "约 基酒 1 : \(method == .ice ? "冰/水" : method.displayName) \(formatNumber(rounded))（估算，精确值以计算器为准）"
    }

    private func makeSteps(aroma: AromaType, base: Double, target: Double, method: MixingMethod, fruitHints: [String]) -> [String] {
        var steps: [String] = []
        steps.append("取 \(aroma.displayName)基酒（约 \(formatNumber(base))°）。")
        switch method {
        case .neat:
            steps.append("常温净饮，小口慢品，感受\(aroma.displayName)本味。")
        case .water:
            steps.append("缓缓兑入常温纯净水，至口感约 \(formatNumber(target))°（精确用量见计算器）。")
        case .ice:
            steps.append("杯中加 2~3 颗大冰球，倒入基酒，静置 30 秒待其降温化开。")
            steps.append("目标约 \(formatNumber(target))°，化冰会进一步柔化口感。")
        case .soda:
            steps.append("基酒入杯，沿杯壁缓注冰苏打水，轻搅一下保留气泡。")
            steps.append("目标约 \(formatNumber(target))°，清爽不上头。")
        case .tea:
            steps.append("以淡茶（乌龙 / 绿茶）替代部分水兑入，增添回甘。")
        case .warm:
            steps.append("隔水温至 38~42℃ 净饮，香气更舒展。")
        }
        if !fruitHints.isEmpty {
            steps.append("点缀：加入少量\(fruitHints.joined(separator: "、"))提味（不影响度数）。")
        }
        steps.append("点「载入计算器」可由引擎算出精确兑制比例与标准杯数。")
        return steps
    }

    private func makeTastingNote(aroma: AromaType, intent: ParsedIntent, method: MixingMethod) -> String {
        let bodyByAroma: String
        switch aroma {
        case .jiangxiang: bodyByAroma = "酱香幽雅、空杯留香"
        case .qingxiang: bodyByAroma = "清香纯正、入口柔净"
        case .nongxiang: bodyByAroma = "窖香浓郁、绵甜爽净"
        }
        var note = bodyByAroma
        if intent.wantsLight || method == .ice || method == .soda {
            note += "，经兑制后清爽易饮、负担更轻"
        } else if intent.wantsMellow {
            note += "，整体温润顺口、回甘悠长"
        }
        return note + "。"
    }

    private func makeRationale(aroma: AromaType, intent: ParsedIntent, targetABV: Double, method: MixingMethod, query: BartenderQuery) -> String {
        var parts: [String] = []
        if intent.aroma != nil {
            parts.append("你点名了\(aroma.displayName)")
        } else {
            parts.append("未指定香型，默认以品牌主打\(aroma.displayName)打底")
        }
        if intent.targetABV != nil {
            parts.append("锁定约 \(formatNumber(targetABV))° ")
        } else if intent.wantsLight {
            parts.append("「清爽不上头」→ 降到约 \(formatNumber(targetABV))° ")
        } else if intent.wantsStrong {
            parts.append("「够劲」→ 保留约 \(formatNumber(targetABV))° ")
        } else {
            parts.append("给出约 \(formatNumber(targetABV))° 的微醺取向")
        }
        parts.append("配以\(method.displayName)")
        return parts.joined(separator: "，") + "，可一键载入计算器精确调制。"
    }

    private func formatNumber(_ v: Double) -> String {
        if v == v.rounded() { return String(Int(v)) }
        return String(format: "%.1f", v)
    }
}
