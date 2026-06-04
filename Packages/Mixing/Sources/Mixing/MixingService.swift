//  MixingService.swift
//  Mixing 包对外门面：单位换算 → 交给 Engine 计算 → 冰融稀释修正 → 生成展示文案。
//  绝不修改 Engine 公式，只做前后换算。

import Foundation
import Engine

/// 一次调制的完整结果（贴近真实饮用场景）。
public struct MixingOutcome: Equatable, Sendable {
    /// Engine 原始计算结果（未受冰融影响：克数/标准单位以此为准）。
    public let engineResult: MixResult
    /// 冰融稀释修正。
    public let dilution: DilutionResult
    /// 酒精摄入展示模型。
    public let display: AlcoholDisplay

    /// 入口处推荐展示的「最终度数」——已含冰融修正。
    public var finalABV: Double { dilution.dilutedABV }
    /// 入口处推荐展示的「最终总量」——已含冰融体积。
    public var finalTotalML: Double { dilution.dilutedTotalML }

    public init(engineResult: MixResult, dilution: DilutionResult, display: AlcoholDisplay) {
        self.engineResult = engineResult
        self.dilution = dilution
        self.display = display
    }
}

/// Mixing 门面服务。
public struct MixingService: Sendable {
    public var config: MixingConfig

    public init(config: MixingConfig = .default) {
        self.config = config
    }

    /// 把若干「带单位 + 度数」的成分混合，按冰量档位修正后输出完整结果。
    ///
    /// - Parameters:
    ///   - components: 每项为（带单位体积, 该段酒精度）。
    ///   - ice: 冰量档位。
    public func mix(components: [(volume: VolumeMeasurement, abv: Double)],
                    ice: IceLevel = .none) -> MixingOutcome {
        // 1) 单位换算层：统一落到 ml，构造 Engine.Component
        let engineComponents = components.map { item in
            Component(volumeML: item.volume.toMilliliters(config), abv: item.abv)
        }

        // 2) 交给 Engine 计算（不改公式）
        let result = MixEngine.combine(engineComponents)

        // 3) 冰融稀释修正（仅修正度数/体积，纯酒精克数不变）
        let dilution = IceDilution.apply(abv: result.finalABV,
                                         totalML: result.totalML,
                                         ice: ice,
                                         config: config)

        // 4) 展示封装
        let display = AlcoholDisplay(result)

        return MixingOutcome(engineResult: result, dilution: dilution, display: display)
    }

    /// 调兑计算器：在基底上加入某酒体达到目标度数（带单位输入），并按冰量修正。
    public func solveAddition(base: [(volume: VolumeMeasurement, abv: Double)],
                              spiritABV: Double,
                              targetABV: Double,
                              ice: IceLevel = .none) -> MixingOutcome {
        let baseComponents = base.map {
            Component(volumeML: $0.volume.toMilliliters(config), abv: $0.abv)
        }
        let result = MixEngine.solveAddition(base: baseComponents,
                                             spiritABV: spiritABV,
                                             targetABV: targetABV)
        let dilution = IceDilution.apply(abv: result.finalABV,
                                         totalML: result.totalML,
                                         ice: ice,
                                         config: config)
        return MixingOutcome(engineResult: result,
                             dilution: dilution,
                             display: AlcoholDisplay(result))
    }
}
