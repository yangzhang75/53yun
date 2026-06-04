//  UnitConversion.swift
//  单位换算层：毫升 / 标准杯 / 分酒器 / 盖数 互相换算，统一落到 ml 后交给 Engine。

import Foundation

/// 体积单位。分酒器/盖的实际容量来自 `MixingConfig`（可配置）。
public enum VolumeUnit: String, CaseIterable, Identifiable, Sendable {
    case milliliter   // 毫升
    case standardCup  // 标准杯(约 30ml)
    case jigger       // 分酒器(可配置)
    case cap          // 盖数(可配置)

    public var id: String { rawValue }

    /// 中文显示名。
    public var displayName: String {
        switch self {
        case .milliliter:  return "毫升"
        case .standardCup: return "标准杯"
        case .jigger:      return "分酒器"
        case .cap:         return "盖"
        }
    }

    /// 单位简写（用于结果文案）。
    public var shortName: String {
        switch self {
        case .milliliter:  return "ml"
        case .standardCup: return "杯"
        case .jigger:      return "器"
        case .cap:         return "盖"
        }
    }

    /// 在给定配置下，1 个该单位等于多少毫升。
    public func milliliters(per config: MixingConfig) -> Double {
        switch self {
        case .milliliter:  return 1
        case .standardCup: return config.standardCupML
        case .jigger:      return config.jiggerML
        case .cap:         return config.capML
        }
    }
}

/// 一次「带单位的体积输入」。
public struct VolumeMeasurement: Equatable, Sendable {
    public var value: Double
    public var unit: VolumeUnit

    public init(value: Double, unit: VolumeUnit) {
        self.value = value
        self.unit = unit
    }
}

public extension VolumeMeasurement {
    /// 换算为毫升。
    func toMilliliters(_ config: MixingConfig = .default) -> Double {
        value * unit.milliliters(per: config)
    }

    /// 换算为另一种单位（返回新的 measurement）。
    func converted(to target: VolumeUnit, _ config: MixingConfig = .default) -> VolumeMeasurement {
        let ml = toMilliliters(config)
        let perTarget = target.milliliters(per: config)
        let newValue = perTarget != 0 ? ml / perTarget : 0
        return VolumeMeasurement(value: newValue, unit: target)
    }
}

/// 单位换算工具（无状态便捷函数）。
public enum UnitConverter {
    /// 毫升 → 指定单位的数量。
    public static func count(ofMilliliters ml: Double,
                             in unit: VolumeUnit,
                             config: MixingConfig = .default) -> Double {
        let per = unit.milliliters(per: config)
        return per != 0 ? ml / per : 0
    }

    /// 指定单位数量 → 毫升。
    public static func milliliters(of value: Double,
                                   in unit: VolumeUnit,
                                   config: MixingConfig = .default) -> Double {
        value * unit.milliliters(per: config)
    }
}
