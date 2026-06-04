//  CellarModels.swift
//  「我的酒柜」SwiftData 数据模型 schema（本包拥有）。
//
//  与 Engine 的 Recipe 做映射，不修改 Engine 模型本身：
//  SavedRecipe 通过 CellarCore.RecipeSnapshot/RecipeMapper 与 Recipe 互转。

import Foundation
import SwiftData
import CellarCore

/// 收藏的配方（可命名 / 编辑 / 删除 / 一键载入）
@Model
public final class SavedRecipe {
    /// 对应 Engine.Recipe.id，保证去重与回链
    @Attribute(.unique) public var recipeID: UUID
    /// 用户可编辑的展示名（默认取配方名）
    public var name: String
    public var aromaRaw: String
    public var targetABV: Double
    public var tastingNote: String
    /// [Component] 的 JSON（见 RecipeMapper）
    public var componentsData: Data
    /// FlavorProfile 的 JSON
    public var flavorData: Data
    public var createdAt: Date
    public var updatedAt: Date

    public init(snapshot: RecipeSnapshot, createdAt: Date = .now) {
        self.recipeID = snapshot.id
        self.name = snapshot.name
        self.aromaRaw = snapshot.aromaRaw
        self.targetABV = snapshot.targetABV
        self.tastingNote = snapshot.tastingNote
        self.componentsData = snapshot.componentsData
        self.flavorData = snapshot.flavorData
        self.createdAt = createdAt
        self.updatedAt = createdAt
    }

    /// 当前持久化字段的快照
    public var snapshot: RecipeSnapshot {
        RecipeSnapshot(
            id: recipeID, name: name, aromaRaw: aromaRaw, targetABV: targetABV,
            tastingNote: tastingNote, componentsData: componentsData, flavorData: flavorData
        )
    }

    /// 还原为 Engine.Recipe（用于「一键载入」触发计算）。
    /// 注意：name 用用户编辑后的名字回写到 Recipe.name。
    public var recipe: Recipe {
        var r = RecipeMapper.recipe(from: snapshot)
        r.name = name
        return r
    }

    /// 用新的 Recipe 覆盖（编辑场景）
    public func update(from recipe: Recipe, now: Date = .now) {
        let snap = RecipeMapper.snapshot(from: recipe)
        self.aromaRaw = snap.aromaRaw
        self.targetABV = snap.targetABV
        self.tastingNote = snap.tastingNote
        self.componentsData = snap.componentsData
        self.flavorData = snap.flavorData
        self.updatedAt = now
    }
}

/// 常用原酒（用户的「自带酒库」，调制时可快速选用）
@Model
public final class SavedSpirit {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var abv: Double
    /// 常备库存体积（mL），用于调制预填
    public var stockML: Double
    public var aromaRaw: String
    public var createdAt: Date

    public init(id: UUID = UUID(), name: String, abv: Double, stockML: Double = 0,
                aroma: AromaType = .nongxiang, createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.abv = abv
        self.stockML = stockML
        self.aromaRaw = aroma.rawValue
        self.createdAt = createdAt
    }

    public var aroma: AromaType {
        get { AromaType(rawValue: aromaRaw) ?? .nongxiang }
        set { aromaRaw = newValue.rawValue }
    }

    /// 作为一种成分参与调制
    public var component: Component {
        Component(volumeML: stockML, abv: abv)
    }
}

/// 微醺积分明细：每完成一次调制 / 收藏记一条
@Model
public final class MeritRecord {
    @Attribute(.unique) public var id: UUID
    public var kindRaw: String
    public var points: Int
    public var note: String
    public var timestamp: Date

    public init(id: UUID = UUID(), kind: MeritKind, points: Int, note: String = "", timestamp: Date = .now) {
        self.id = id
        self.kindRaw = kind.rawValue
        self.points = points
        self.note = note
        self.timestamp = timestamp
    }

    public var kind: MeritKind {
        MeritKind(rawValue: kindRaw) ?? .favorite
    }
}

/// 本包拥有的 SwiftData schema 集合
public enum CellarSchema {
    public static let models: [any PersistentModel.Type] = [
        SavedRecipe.self,
        SavedSpirit.self,
        MeritRecord.self,
    ]

    /// 构造 ModelContainer（App 端集成时调用；inMemory 供预览 / 测试）
    public static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema(models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: schema, configurations: [config])
    }
}
