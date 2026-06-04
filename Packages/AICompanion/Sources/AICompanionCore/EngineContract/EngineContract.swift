//
//  EngineContract.swift
//  AICompanionCore
//
//  共享数据契约（由员工② 在 Engine 包中定义，全员引用）。
//
//  ⚠️ 集成约定：
//  - 工程中存在 Engine 包时，下方 `@_exported import Engine` 生效，本文件的兜底类型自动失效，
//    AICompanion 直接产出 *Engine 的* Recipe，零改动。
//  - Engine 不在场（独立开发 / 命令行单测）时，使用本文件中的同名兜底契约。
//
//  本包**不实现度数公式**：兑法精确配比由 Engine 负责（见 BartenderService.mixPreview 注入点）。
//

#if canImport(Engine)

@_exported import Engine

#else

import Foundation

// MARK: - 兜底契约（与 Engine 的 public 定义保持字段一致）

/// 香型：清香 / 酱香 / 浓香
public enum AromaType: String, Codable, CaseIterable, Sendable {
    case qingxiang   // 清香
    case jiangxiang  // 酱香
    case nongxiang   // 浓香

    /// 中文展示名
    public var displayName: String {
        switch self {
        case .qingxiang: return "清香"
        case .jiangxiang: return "酱香"
        case .nongxiang: return "浓香"
        }
    }
}

/// 一种成分（一段液体）
public struct Component: Codable, Hashable, Sendable {
    public var volumeML: Double
    public var abv: Double

    public init(volumeML: Double, abv: Double) {
        self.volumeML = volumeML
        self.abv = abv
    }
}

/// 兑制结果（由 Engine 计算；本包仅作展示，不自行实现公式）
public struct MixResult: Codable, Hashable, Sendable {
    public var addedML: Double
    public var totalML: Double
    public var standardUnits: Double

    public init(addedML: Double, totalML: Double, standardUnits: Double) {
        self.addedML = addedML
        self.totalML = totalML
        self.standardUnits = standardUnits
    }
}

/// 风味画像（各维 0~1），供风味雷达使用
public struct FlavorProfile: Codable, Hashable, Sendable {
    public var mellow: Double   // 绵柔
    public var strength: Double // 劲道

    public init(mellow: Double, strength: Double) {
        self.mellow = mellow
        self.strength = strength
    }
}

/// 标准配方对象 —— 全员共享，AICompanion 的最终产出。
public struct Recipe: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var aroma: AromaType
    public var components: [Component]
    public var targetABV: Double
    public var tastingNote: String
    public var flavor: FlavorProfile

    public init(
        id: UUID = UUID(),
        name: String,
        aroma: AromaType,
        components: [Component],
        targetABV: Double,
        tastingNote: String,
        flavor: FlavorProfile
    ) {
        self.id = id
        self.name = name
        self.aroma = aroma
        self.components = components
        self.targetABV = targetABV
        self.tastingNote = tastingNote
        self.flavor = flavor
    }
}

#endif
