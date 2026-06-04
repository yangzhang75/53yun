import Foundation

/// 生理性别。Widmark 体液分布系数（r）按性别取经验值。
/// 注：此处仅为 BAC 估算所需的生理参数，非身份认定。
public enum BiologicalSex: String, Codable, CaseIterable, Sendable, Identifiable {
    case male
    case female

    public var id: String { rawValue }

    /// 中文展示名。
    public var displayName: String {
        switch self {
        case .male: return "男"
        case .female: return "女"
        }
    }
}

/// 用户生理信息：体重 + 性别。用于 Widmark 公式估算。
/// 数据默认仅在本地参与计算，不上传（隐私友好）。
public struct BiometricProfile: Equatable, Codable, Sendable {

    /// 体重（公斤）。
    public var weightKilograms: Double

    /// 生理性别。
    public var sex: BiologicalSex

    public init(weightKilograms: Double, sex: BiologicalSex) {
        self.weightKilograms = weightKilograms
        self.sex = sex
    }

    /// 体重合法范围（公斤）。用于输入校验与 UI 滑杆边界。
    public static let weightRange: ClosedRange<Double> = 30...200

    /// 默认占位档案（成年人常见体重，男）。
    public static let `default` = BiometricProfile(weightKilograms: 70, sex: .male)

    /// 体重是否在合理范围内。
    public var isWeightValid: Bool {
        BiometricProfile.weightRange.contains(weightKilograms)
    }

    /// 限制在合法范围内的体重（用于稳健计算）。
    public var clampedWeightKilograms: Double {
        min(max(weightKilograms, BiometricProfile.weightRange.lowerBound),
            BiometricProfile.weightRange.upperBound)
    }
}
