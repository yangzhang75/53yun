import Foundation
import Engine

// MARK: - 风味五维轴（Flavor Axes）
//
// 雷达图的五个维度，顺序固定（顺时针，从正上方开始）：
// 醇厚 / 酒劲 / 净爽 / 回甘 / 层次。
// 每个轴从 `FlavorProfile` 取对应的 0~1 数值，UI 层与测试都引用这里，避免顺序/取值散落。

public enum FlavorAxis: Int, CaseIterable, Identifiable, Sendable {
    case mellow      // 醇厚
    case strength    // 酒劲
    case crisp       // 净爽
    case sweet       // 回甘
    case complexity  // 层次

    public var id: Int { rawValue }

    /// 中文展示名（雷达图顶点标签）。
    public var displayName: String {
        switch self {
        case .mellow:     return "醇厚"
        case .strength:   return "酒劲"
        case .crisp:      return "净爽"
        case .sweet:      return "回甘"
        case .complexity: return "层次"
        }
    }

    /// 从风味画像取出本轴的取值，已 clamp 到 0~1。
    public func value(in profile: FlavorProfile) -> Double {
        let raw: Double
        switch self {
        case .mellow:     raw = profile.mellow
        case .strength:   raw = profile.strength
        case .crisp:      raw = profile.crisp
        case .sweet:      raw = profile.sweet
        case .complexity: raw = profile.complexity
        }
        return min(1, max(0, raw))
    }
}

public extension FlavorProfile {
    /// 按 `FlavorAxis.allCases` 顺序展开的五维数组（均 clamp 到 0~1）。
    var axisValues: [Double] {
        FlavorAxis.allCases.map { $0.value(in: self) }
    }
}
