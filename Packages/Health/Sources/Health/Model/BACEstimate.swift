import Foundation

/// 当前 BAC 所处的风险等级（仅用于温柔提示与配色，非医学判定）。
public enum BACLevel: String, Codable, Sendable {
    /// 已清醒或接近清醒（< 饮酒驾车阈值）。
    case sober
    /// 已达「饮酒驾车」区间（≥ 20，< 80 mg/100mL）。
    case driving
    /// 已达「醉酒」区间（≥ 80 mg/100mL）。
    case intoxicated

    public var displayName: String {
        switch self {
        case .sober: return "清醒区"
        case .driving: return "微醺·已不宜驾车"
        case .intoxicated: return "醉意明显"
        }
    }
}

/// Widmark 估算的完整结果。纯数据，无任何 UI 依赖，可直接单元测试。
public struct BACEstimate: Equatable, Sendable {

    /// 完整的「BAC 随时间衰减」曲线（自第一口起，至回落到 0）。
    public let curve: [BACSample]

    /// 当前（= 饮用结束时刻）估算 BAC（mg/100mL）。
    public let currentBACMgPer100mL: Double

    /// 峰值 BAC（mg/100mL）。
    public let peakBACMgPer100mL: Double

    /// 距「完全清醒（BAC=0）」尚需的小时数（从当前时刻起）。
    public let hoursUntilSober: Double

    /// 距「低于饮酒驾车阈值（20mg/100mL）」尚需的小时数（从当前时刻起）。
    /// 若当前已低于阈值，则为 0。
    public let hoursUntilLegalDriving: Double

    /// 当前风险等级。
    public let level: BACLevel

    public init(curve: [BACSample],
                currentBACMgPer100mL: Double,
                peakBACMgPer100mL: Double,
                hoursUntilSober: Double,
                hoursUntilLegalDriving: Double,
                level: BACLevel) {
        self.curve = curve
        self.currentBACMgPer100mL = currentBACMgPer100mL
        self.peakBACMgPer100mL = peakBACMgPer100mL
        self.hoursUntilSober = hoursUntilSober
        self.hoursUntilLegalDriving = hoursUntilLegalDriving
        self.level = level
    }

    /// 全 0 的空结果（无摄入时）。
    public static let empty = BACEstimate(
        curve: [BACSample(hoursSinceStart: 0, bacMgPer100mL: 0)],
        currentBACMgPer100mL: 0,
        peakBACMgPer100mL: 0,
        hoursUntilSober: 0,
        hoursUntilLegalDriving: 0,
        level: .sober
    )
}
