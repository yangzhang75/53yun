import Foundation

/// Widmark 模型参数与法定阈值。
///
/// 全部以 **mg/100mL**（毫克/百毫升）为内部统一单位，与中国《车辆驾驶人员血液、呼气
/// 酒精含量阈值与检验》(GB19522) 的口径一致：
/// - 饮酒驾车：BAC ≥ 20 mg/100mL
/// - 醉酒驾车：BAC ≥ 80 mg/100mL
///
/// 注：这些阈值仅用于「温柔提示」与教育目的，**不构成任何法律或医学依据**。
public struct BACParameters: Equatable, Codable, Sendable {

    /// Widmark 体液分布系数 r（男）。经典经验值。
    public var distributionRatioMale: Double

    /// Widmark 体液分布系数 r（女）。经典经验值。
    public var distributionRatioFemale: Double

    /// 酒精消除速率 β（mg/100mL / 小时）。
    /// 常见区间 10–20；默认取保守偏低值 15，使「清醒时间」估计偏保守（更安全）。
    public var eliminationRatePerHour: Double

    public init(distributionRatioMale: Double = 0.68,
                distributionRatioFemale: Double = 0.55,
                eliminationRatePerHour: Double = 15.0) {
        self.distributionRatioMale = distributionRatioMale
        self.distributionRatioFemale = distributionRatioFemale
        self.eliminationRatePerHour = eliminationRatePerHour
    }

    public static let `default` = BACParameters()

    /// 按性别取分布系数 r。
    public func distributionRatio(for sex: BiologicalSex) -> Double {
        switch sex {
        case .male: return distributionRatioMale
        case .female: return distributionRatioFemale
        }
    }

    // MARK: - 法定/参考阈值（mg/100mL）

    /// 饮酒驾车阈值：20 mg/100mL。低于此值在国标下不属于「饮酒驾车」。
    public static let drivingLimit: Double = 20

    /// 醉酒驾车阈值：80 mg/100mL。
    public static let intoxicatedLimit: Double = 80

    /// 完全清醒（BAC = 0）。
    public static let sober: Double = 0
}
