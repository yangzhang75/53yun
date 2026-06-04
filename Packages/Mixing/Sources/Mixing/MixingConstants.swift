//  MixingConstants.swift
//  Mixing 包的可配置经验常量集中地。
//  ⚠️ 冰融稀释系数为「经验估算值」，非精确测量；可在此统一调整。

import Foundation

/// Mixing 包统一配置。承载所有可配置项（分酒器/盖容量、稀释系数等）。
public struct MixingConfig: Equatable, Sendable {

    // MARK: 单位换算配置

    /// 一「标准杯」体积（ml）。约定 30ml（shot）。
    public var standardCupML: Double

    /// 一个「分酒器」体积（ml）。常见 15ml，可配置。
    public var jiggerML: Double

    /// 一「盖」体积（ml）。瓶盖估算，可配置。
    public var capML: Double

    // MARK: 冰融稀释配置（经验估算）

    /// 冰块（碎/小块）造成的稀释比例，默认 +15%。
    public var cubeDilution: Double

    /// 大冰球造成的稀释比例，默认 +8%。
    public var bigBallDilution: Double

    public init(standardCupML: Double = 30,
                jiggerML: Double = 15,
                capML: Double = 8,
                cubeDilution: Double = 0.15,
                bigBallDilution: Double = 0.08) {
        self.standardCupML = standardCupML
        self.jiggerML = jiggerML
        self.capML = capML
        self.cubeDilution = cubeDilution
        self.bigBallDilution = bigBallDilution
    }

    /// 默认配置。
    public static let `default` = MixingConfig()
}
