import Foundation

/// 饮酒摄入量输入。
///
/// 关键边界：本包**不**重算纯酒精摄入量的「公式心脏」。
/// `pureAlcoholGrams`（纯酒精克数）由 Engine 的 `MixResult` 计算并经 App 层注入。
///
/// 集成示例（App 层，依赖 Engine）：
/// ```swift
/// import Engine
/// // 1 标准杯 ≈ 10g 纯酒精（WHO / 中国常用口径）
/// let intake = AlcoholIntake(standardUnits: mixResult.standardUnits,
///                            drinkingDurationHours: 1.5)
/// ```
public struct AlcoholIntake: Equatable, Codable, Sendable {

    /// 纯酒精摄入量（克）。来源：Engine `MixResult`。
    public var pureAlcoholGrams: Double

    /// 饮用时长（小时）：从第一口到最后一口的跨度。
    /// 用于建模酒精的线性吸收过程（时长越长，峰值越低）。
    public var drinkingDurationHours: Double

    public init(pureAlcoholGrams: Double, drinkingDurationHours: Double) {
        self.pureAlcoholGrams = max(0, pureAlcoholGrams)
        self.drinkingDurationHours = max(0, drinkingDurationHours)
    }

    /// 每标准杯对应的纯酒精克数（WHO / 中国常用口径：10g）。
    public static let gramsPerStandardUnit: Double = 10.0

    /// 便捷构造：用「标准杯数」换算。供 Engine `MixResult.standardUnits` 直接接入。
    public init(standardUnits: Double,
                drinkingDurationHours: Double,
                gramsPerStandardUnit: Double = AlcoholIntake.gramsPerStandardUnit) {
        self.init(pureAlcoholGrams: max(0, standardUnits) * gramsPerStandardUnit,
                  drinkingDurationHours: drinkingDurationHours)
    }

    /// 折算的标准杯数（仅用于展示）。
    public var standardUnits: Double {
        guard AlcoholIntake.gramsPerStandardUnit > 0 else { return 0 }
        return pureAlcoholGrams / AlcoholIntake.gramsPerStandardUnit
    }

    /// 是否有有效摄入（>0）。
    public var hasIntake: Bool { pureAlcoholGrams > 0 }
}
