//  EngineContract_Standin.swift
//
//  ⚠️ 临时占位 —— 集成时删除本文件 ⚠️
//
//  这些类型是「共享数据契约」，真正的归属在 Engine 包（员工②）。
//  按照分工约定，全员都应 `import Engine` 引用，不要各自重造。
//
//  但本 Cellar 包在独立分支上开发时，Engine 包尚未在工程内落地，
//  为了让本包能够独立编译 / 单测 / 预览，这里临时内联一份与契约一致的副本。
//
//  集成步骤（员工①）：
//    1. 删除本文件；
//    2. 在 CellarCore 的 Package.swift 中加入对 Engine 的依赖；
//    3. 在用到这些类型的文件顶部 `import Engine`。
//
//  字段命名严格遵循《共享数据契约》。原始契约文本有截断，这里按白酒业务语义补全。

import Foundation

/// 香型（清香 / 酱香 / 浓香）
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

/// 一种成分（某种酒体的体积与度数）
public struct Component: Codable, Hashable, Sendable {
    public var volumeML: Double
    public var abv: Double

    public init(volumeML: Double, abv: Double) {
        self.volumeML = volumeML
        self.abv = abv
    }
}

/// 调制计算结果
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

/// 风味雷达（各维度 0~1）
public struct FlavorProfile: Codable, Hashable, Sendable {
    public var mellow: Double    // 绵柔
    public var strength: Double  // 烈度
    public var sweet: Double     // 回甜
    public var aroma: Double     // 香气
    public var finish: Double    // 余味

    public init(mellow: Double, strength: Double, sweet: Double, aroma: Double, finish: Double) {
        self.mellow = mellow
        self.strength = strength
        self.sweet = sweet
        self.aroma = aroma
        self.finish = finish
    }

    public static let zero = FlavorProfile(mellow: 0, strength: 0, sweet: 0, aroma: 0, finish: 0)
}

/// 配方（共享契约核心类型）
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
        tastingNote: String = "",
        flavor: FlavorProfile = .zero
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
