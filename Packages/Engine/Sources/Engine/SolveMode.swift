import Foundation

/// 三向自由解算模式。用关联值携带各模式所需输入，保证「缺哪个解哪个」类型安全。
///
/// 物理模型：果汁视为 0% 无醇基底，向其中加入度数为 `baseABV` 的原酒。
/// 最终度数 = (Va × Pa) / (Va + Vj)，其中 Va = 加酒量，Vj = 果汁体积，Pa = 原酒度数。
public enum SolveMode: Equatable, Sendable {

    /// 已知 果汁体积 Vj + 原酒度数 Pa + 目标度数 Pt → 解「加酒量 Va」。
    /// 公式：Va = (Pt × Vj) / (Pa − Pt)
    case addedVolume(juiceML: Double, baseABV: Double, targetABV: Double)

    /// 已知 果汁体积 Vj + 加酒量 Va + 原酒度数 Pa → 解「最终度数」。
    /// 公式：Pt = (Va × Pa) / (Va + Vj)
    case finalABV(juiceML: Double, addedML: Double, baseABV: Double)

    /// 已知 果汁体积 Vj + 加酒量 Va + 目标度数 Pt → 反解「所需原酒度数 Pa」。
    /// 公式：Pa = Pt × (Va + Vj) / Va
    case requiredBaseABV(juiceML: Double, addedML: Double, targetABV: Double)
}
