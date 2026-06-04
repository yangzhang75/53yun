//  IceDilution.swift
//  冰融稀释模型：不加冰 / 冰块 / 大冰球 三档，按经验稀释系数修正最终度数。
//  ⚠️ 稀释系数为经验估算（冰块约 +15%、大冰球约 +8%），数值在 MixingConfig 配置。
//
//  物理模型：冰融化加入比例为 f 的水，总体积变为 V*(1+f)，纯酒精体积不变，
//  故最终度数 = abv / (1 + f)，总体积 = totalML * (1 + f)。
//  Mixing 只在 Engine 计算结果之后做这层修正，不改动 Engine 公式。

import Foundation

/// 冰量档位。
public enum IceLevel: String, CaseIterable, Identifiable, Sendable {
    case none     // 不加冰
    case cube     // 冰块
    case bigBall  // 大冰球

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .none:    return "不加冰"
        case .cube:    return "冰块"
        case .bigBall: return "大冰球"
        }
    }

    /// 在给定配置下的稀释比例（0 表示不稀释）。
    public func dilutionFactor(_ config: MixingConfig = .default) -> Double {
        switch self {
        case .none:    return 0
        case .cube:    return config.cubeDilution
        case .bigBall: return config.bigBallDilution
        }
    }
}

/// 冰融稀释修正结果。
public struct DilutionResult: Equatable, Sendable {
    /// 修正前度数（%vol）。
    public var originalABV: Double
    /// 稀释后度数（%vol）。
    public var dilutedABV: Double
    /// 稀释后总体积（ml）。
    public var dilutedTotalML: Double
    /// 实际采用的稀释比例。
    public var factor: Double

    /// 这是估算值标记，UI 可据此提示「≈」。
    public var isEstimate: Bool { factor > 0 }

    public init(originalABV: Double, dilutedABV: Double, dilutedTotalML: Double, factor: Double) {
        self.originalABV = originalABV
        self.dilutedABV = dilutedABV
        self.dilutedTotalML = dilutedTotalML
        self.factor = factor
    }
}

public enum IceDilution {
    /// 按冰量档位修正度数与总体积。
    public static func apply(abv: Double,
                             totalML: Double,
                             ice: IceLevel,
                             config: MixingConfig = .default) -> DilutionResult {
        let f = ice.dilutionFactor(config)
        let dilutedABV = abv / (1 + f)
        let dilutedML = totalML * (1 + f)
        return DilutionResult(originalABV: abv,
                              dilutedABV: dilutedABV,
                              dilutedTotalML: dilutedML,
                              factor: f)
    }
}
