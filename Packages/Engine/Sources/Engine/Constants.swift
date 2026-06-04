import Foundation

/// 引擎共享常量。集中管理「物理/换算」口径，避免散落在各处出现魔法数字。
public enum EngineConstants {

    /// 乙醇密度（g/mL，约 20℃）。用于把「纯酒精体积」换算为「纯酒精克数」。
    public static let ethanolDensityGramsPerML: Double = 0.789

    /// 一个「标准酒精单位」对应的纯酒精克数。
    /// 采用 WHO / 中国常用口径：1 标准单位 = 10 g 纯酒精。
    public static let gramsPerStandardUnit: Double = 10.0

    /// 合法酒精度区间（百分比，0~100）。
    public static let abvRange: ClosedRange<Double> = 0.0...100.0
}
