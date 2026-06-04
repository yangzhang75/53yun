//
//  NaturalLanguageParser.swift
//  AICompanionCore
//
//  轻量中文诉求解析（关键词 + 正则），供本地规则引擎使用。
//  不依赖网络、不依赖模型，断网可用。
//

import Foundation

/// 从一句中文诉求里解析出的结构化意图。
public struct ParsedIntent: Equatable, Sendable {
    /// 香型（未识别则 nil → 引擎给默认）。
    public var aroma: AromaType?
    /// 目标度数（未识别则 nil → 引擎据「轻/重」给默认）。
    public var targetABV: Double?
    /// 兑法（未识别则 nil → 引擎据度数/口味给默认）。
    public var method: MixingMethod?
    /// 口味倾向。
    public var wantsLight: Bool      // 清爽 / 不上头 / 解腻
    public var wantsMellow: Bool     // 绵柔 / 顺口
    public var wantsStrong: Bool     // 够劲 / 上头 / 烈
    /// 命中的关键词数量（用于估算置信度）。
    public var matchScore: Int

    public init(
        aroma: AromaType? = nil,
        targetABV: Double? = nil,
        method: MixingMethod? = nil,
        wantsLight: Bool = false,
        wantsMellow: Bool = false,
        wantsStrong: Bool = false,
        matchScore: Int = 0
    ) {
        self.aroma = aroma
        self.targetABV = targetABV
        self.method = method
        self.wantsLight = wantsLight
        self.wantsMellow = wantsMellow
        self.wantsStrong = wantsStrong
        self.matchScore = matchScore
    }
}

public enum NaturalLanguageParser {

    public static func parse(_ raw: String) -> ParsedIntent {
        let text = normalize(raw)
        var intent = ParsedIntent()
        var score = 0

        // 1) 香型
        if containsAny(text, ["酱香", "酱味", "茅", "坤沙", "回沙"]) {
            intent.aroma = .jiangxiang; score += 1
        } else if containsAny(text, ["清香", "清雅", "汾", "二锅头", "小曲"]) {
            intent.aroma = .qingxiang; score += 1
        } else if containsAny(text, ["浓香", "窖香", "五粮", "泸州", "剑南", "洋河"]) {
            intent.aroma = .nongxiang; score += 1
        }

        // 2) 度数：显式数字优先
        if let abv = explicitABV(text) {
            intent.targetABV = abv; score += 1
        }

        // 3) 口味倾向
        if containsAny(text, ["清爽", "不上头", "解腻", "好入口", "顺口不冲", "清淡", "微醺", "低度", "度数低"]) {
            intent.wantsLight = true; score += 1
        }
        if containsAny(text, ["绵柔", "柔和", "顺口", "丝滑", "回甘", "温润", "醇厚", "醇和"]) {
            intent.wantsMellow = true; score += 1
        }
        if containsAny(text, ["够劲", "上头", "带劲", "烈", "原浆", "高度", "够味", "刺激"]) {
            intent.wantsStrong = true; score += 1
        }

        // 4) 兑法
        if containsAny(text, ["加冰", "冰镇", "冰饮", "on the rock", "冰块"]) {
            intent.method = .ice; score += 1
        } else if containsAny(text, ["苏打", "气泡", "汽水", "highball", "嗨棒"]) {
            intent.method = .soda; score += 1
        } else if containsAny(text, ["兑茶", "淡茶", "茶水", "茶味"]) {
            intent.method = .tea; score += 1
        } else if containsAny(text, ["温饮", "烫", "温酒", "热饮"]) {
            intent.method = .warm; score += 1
        } else if containsAny(text, ["兑水", "加水", "纯净水", "稀释"]) {
            intent.method = .water; score += 1
        } else if containsAny(text, ["纯饮", "净饮", "不兑", "原味"]) {
            intent.method = .neat; score += 1
        }

        intent.matchScore = score
        return intent
    }

    // MARK: - 私有

    /// 归一化：去空格、全角数字转半角、转小写（英文）。
    private static func normalize(_ s: String) -> String {
        let lower = s.lowercased()
        var out = ""
        out.reserveCapacity(lower.count)
        for ch in lower {
            if let scalar = ch.unicodeScalars.first,
               scalar.value >= 0xFF10, scalar.value <= 0xFF19 {
                // 全角 ０-９ → 半角
                out.unicodeScalars.append(Unicode.Scalar(scalar.value - 0xFF10 + 0x30)!)
            } else if ch == "．" {
                out.append(".")
            } else {
                out.append(ch)
            }
        }
        return out
    }

    private static func containsAny(_ text: String, _ keywords: [String]) -> Bool {
        for k in keywords where text.contains(k) { return true }
        return false
    }

    /// 解析显式度数：「8 度」「8度左右」「12.5°」「45 度」。限定 1~70 合理区间。
    private static func explicitABV(_ text: String) -> Double? {
        // 匹配 数字(可带小数) 后跟 度 / °
        let pattern = "([0-9]+(?:\\.[0-9]+)?)\\s*(?:度|°)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              let r = Range(match.range(at: 1), in: text),
              let value = Double(text[r]) else { return nil }
        guard (1...70).contains(value) else { return nil }
        return value
    }
}
