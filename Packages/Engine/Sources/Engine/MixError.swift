import Foundation

/// 调制解算错误。所有错误都带有可读的中文说明（`errorDescription`），可直接呈现给用户。
public enum MixError: Error, Equatable, LocalizedError, Sendable {

    /// 非法输入：体积为负、数值非有限（NaN / 无穷）等。
    case invalidInput(String)

    /// 酒精度超出 0~100 合法区间。
    case abvOutOfRange(value: Double)

    /// 目标度数不可达。
    /// 例如原酒度数 `baseABV` ≤ 目标度数 `target`（无论加多少酒都无法升到目标），
    /// 或反解所需原酒度数 > 100%。
    case targetUnreachable(target: Double, baseABV: Double)

    /// 总体积为零，无法计算度数。
    case zeroTotalVolume

    /// 多组分混调时组分列表为空。
    case emptyComponents

    public var errorDescription: String? {
        switch self {
        case .invalidInput(let reason):
            return "输入不合法：\(reason)"
        case .abvOutOfRange(let value):
            return "酒精度 \(format(value)) 超出有效范围（0~100）。"
        case .targetUnreachable(let target, let baseABV):
            return "目标度数 \(format(target))° 不可达：原酒度数为 \(format(baseABV))°，无法通过加酒达到该目标。"
        case .zeroTotalVolume:
            return "总体积为 0，无法计算酒精度。"
        case .emptyComponents:
            return "组分为空，请至少加入一种组分。"
        }
    }

    private func format(_ value: Double) -> String {
        String(format: "%g", value)
    }
}
