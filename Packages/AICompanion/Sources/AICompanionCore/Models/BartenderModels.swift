//
//  BartenderModels.swift
//  AICompanionCore
//
//  「AI 调酒师」对外的请求 / 推荐数据模型。
//

import Foundation

// MARK: - 用户诉求

/// 一次自然语言诉求，例如「清爽不上头、8 度左右、酱香打底」。
public struct BartenderQuery: Equatable, Sendable {
    /// 用户自然语言输入。
    public var text: String
    /// 可选：附带的果味识别标签（加分项·拍照识果输出），如 ["青梅", "陈皮"]。
    public var fruitHints: [String]

    public init(text: String, fruitHints: [String] = []) {
        self.text = text
        self.fruitHints = fruitHints
    }
}

// MARK: - 兑法方式

/// 兑法（如何稀释 / 调和）。
public enum MixingMethod: String, Codable, CaseIterable, Sendable {
    case neat       // 净饮（不兑）
    case water      // 纯净水
    case ice        // 加冰
    case soda       // 苏打 / 气泡水
    case tea        // 淡茶
    case warm       // 温饮

    public var displayName: String {
        switch self {
        case .neat: return "净饮"
        case .water: return "纯净水兑制"
        case .ice:  return "加冰"
        case .soda: return "苏打 / 气泡水"
        case .tea:  return "淡茶兑制"
        case .warm: return "温饮"
        }
    }

    /// 该兑法引入的稀释液 ABV（净饮 / 温饮无稀释液 → nil）。
    public var diluentABV: Double? {
        switch self {
        case .neat, .warm: return nil
        case .water, .ice, .tea: return 0
        case .soda: return 0
        }
    }
}

// MARK: - 推荐来源

/// 推荐由谁产生 —— 用于在 UI 上诚实标注（合规：让用户知情）。
public enum RecommendationSource: String, Codable, Sendable {
    case llm          // 大模型（云端 / 服务端代理）
    case localRules   // 本地规则引擎兜底

    public var displayName: String {
        switch self {
        case .llm: return "云端 AI"
        case .localRules: return "本地推荐"
        }
    }
}

// MARK: - 推荐结果

/// 一条调酒推荐：包含可一键载入计算器的标准 `Recipe`，以及给用户看的解释。
public struct Recommendation: Identifiable, Sendable {
    public let id: UUID
    /// 一句话标题，如「酱香低度·清爽冰饮」。
    public var headline: String
    /// 推荐香型。
    public var aroma: AromaType
    /// 兑法。
    public var method: MixingMethod
    /// 配比文字（展示用；精确体积/标准杯由 Engine 计算）。
    public var ratioSummary: String
    /// 兑法分步说明。
    public var steps: [String]
    /// 推荐理由 / 风味描述。
    public var rationale: String
    /// **可一键载入计算器的标准配方对象（交给 Engine 计算）。**
    public var recipe: Recipe
    /// 推荐来源（诚实标注）。
    public var source: RecommendationSource
    /// 置信度 0~1（本地规则引擎据匹配度估算；LLM 由模型返回或默认）。
    public var confidence: Double

    public init(
        id: UUID = UUID(),
        headline: String,
        aroma: AromaType,
        method: MixingMethod,
        ratioSummary: String,
        steps: [String],
        rationale: String,
        recipe: Recipe,
        source: RecommendationSource,
        confidence: Double
    ) {
        self.id = id
        self.headline = headline
        self.aroma = aroma
        self.method = method
        self.ratioSummary = ratioSummary
        self.steps = steps
        self.rationale = rationale
        self.recipe = recipe
        self.source = source
        self.confidence = confidence
    }
}

// MARK: - 错误

public enum BartenderError: Error, LocalizedError, Equatable {
    case emptyQuery
    case llmDisabled
    case llmUnreachable(String)
    case llmBadResponse(String)
    case notConfigured

    public var errorDescription: String? {
        switch self {
        case .emptyQuery: return "请先描述你的口味诉求。"
        case .llmDisabled: return "云端 AI 未启用。"
        case .llmUnreachable(let m): return "云端连接失败：\(m)"
        case .llmBadResponse(let m): return "云端返回无法解析：\(m)"
        case .notConfigured: return "AI 调酒师尚未配置接口。"
        }
    }
}
