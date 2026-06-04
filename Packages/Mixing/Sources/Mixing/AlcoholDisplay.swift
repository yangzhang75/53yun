//  AlcoholDisplay.swift
//  标准酒精单位换算的展示封装：把 Engine 的 alcoholGrams / standardUnits 转成可读文案。

import Foundation
import Engine

/// 把 Engine 结果转成中文可读文案的展示模型。
public struct AlcoholDisplay: Equatable, Sendable {
    public let alcoholGrams: Double
    public let standardUnits: Double

    public init(alcoholGrams: Double, standardUnits: Double) {
        self.alcoholGrams = alcoholGrams
        self.standardUnits = standardUnits
    }

    /// 直接从 Engine 的 MixResult 构造。
    public init(_ result: MixResult) {
        self.alcoholGrams = result.alcoholGrams
        self.standardUnits = result.standardUnits
    }

    private static func trimmed(_ v: Double, _ digits: Int) -> String {
        let s = String(format: "%.\(digits)f", v)
        // 去掉末尾多余的 0 与小数点
        if s.contains(".") {
            var t = s
            while t.hasSuffix("0") { t.removeLast() }
            if t.hasSuffix(".") { t.removeLast() }
            return t
        }
        return s
    }

    /// 「本杯≈X标准杯酒精」
    public var standardCupText: String {
        "本杯≈\(Self.trimmed(standardUnits, 1))标准杯酒精"
    }

    /// 「相当于 Y 克纯酒精」
    public var pureAlcoholText: String {
        "相当于 \(Self.trimmed(alcoholGrams, 1)) 克纯酒精"
    }

    /// 合并一行文案。
    public var summaryText: String {
        "\(standardCupText)，\(pureAlcoholText)"
    }
}
