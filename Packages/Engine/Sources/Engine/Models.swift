import Foundation

// MARK: - 香型

/// 白酒香型：清香 / 酱香 / 浓香。
/// 使用 `String` 原始值，便于 Codable 持久化与深链编码后保持稳定。
public enum AromaType: String, Codable, CaseIterable, Sendable, Hashable {
    case qingxiang  // 清香
    case jiangxiang // 酱香
    case nongxiang  // 浓香

    /// 中文展示名（UI 层可直接使用）。
    public var displayName: String {
        switch self {
        case .qingxiang: return "清香"
        case .jiangxiang: return "酱香"
        case .nongxiang:  return "浓香"
        }
    }
}

// MARK: - 组分

/// 调制中的单个组分（如：原酒、果汁、冰等）。
/// `abv` 为该组分自身的酒精度（百分比，0~100）；果汁等无醇组分 abv = 0。
public struct Component: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    /// 组分名称，例如「53° 原酒」「鲜榨橙汁」。
    public var name: String
    /// 体积（mL）。
    public var volumeML: Double
    /// 该组分酒精度（百分比，0~100）。
    public var abv: Double

    public init(id: UUID = UUID(), name: String = "", volumeML: Double, abv: Double) {
        self.id = id
        self.name = name
        self.volumeML = volumeML
        self.abv = abv
    }
}

// MARK: - 调制结果

/// 一次调制的计算结果。所有数值均为原始 `Double`，由 UI 层自行决定四舍五入与展示精度。
public struct MixResult: Codable, Hashable, Sendable {
    /// 加入的「含酒组分」体积（mL）。
    /// 三向解算场景下即「加酒量 Va」；多组分场景下为所有 abv>0 组分的体积之和。
    public var addedML: Double
    /// 混合后总体积（mL）。
    public var totalML: Double
    /// 混合后实际酒精度（百分比，0~100）。
    public var actualABV: Double
    /// 每份成品所含纯酒精克数（g）。
    public var alcoholGrams: Double
    /// 折合标准酒精单位（见 `EngineConstants.gramsPerStandardUnit`）。
    public var standardUnits: Double

    public init(addedML: Double,
                totalML: Double,
                actualABV: Double,
                alcoholGrams: Double,
                standardUnits: Double) {
        self.addedML = addedML
        self.totalML = totalML
        self.actualABV = actualABV
        self.alcoholGrams = alcoholGrams
        self.standardUnits = standardUnits
    }
}

// MARK: - 风味画像

/// 风味画像，各维度取值 0~1。用于雷达图等可视化。
public struct FlavorProfile: Codable, Hashable, Sendable {
    public var mellow: Double      // 醇厚
    public var strength: Double    // 力度
    public var crisp: Double       // 爽净
    public var sweet: Double       // 甘甜
    public var complexity: Double  // 层次

    public init(mellow: Double = 0,
                strength: Double = 0,
                crisp: Double = 0,
                sweet: Double = 0,
                complexity: Double = 0) {
        self.mellow = mellow
        self.strength = strength
        self.crisp = crisp
        self.sweet = sweet
        self.complexity = complexity
    }
}

// MARK: - 配方

/// 一份完整配方。可 Codable 以支持持久化（SwiftData/JSON）与深链分享。
public struct Recipe: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var aroma: AromaType
    public var components: [Component]
    /// 目标酒精度（百分比，0~100）。
    public var targetABV: Double
    public var tastingNote: String
    public var flavor: FlavorProfile

    public init(id: UUID = UUID(),
                name: String,
                aroma: AromaType,
                components: [Component],
                targetABV: Double,
                tastingNote: String = "",
                flavor: FlavorProfile = FlavorProfile()) {
        self.id = id
        self.name = name
        self.aroma = aroma
        self.components = components
        self.targetABV = targetABV
        self.tastingNote = tastingNote
        self.flavor = flavor
    }
}
