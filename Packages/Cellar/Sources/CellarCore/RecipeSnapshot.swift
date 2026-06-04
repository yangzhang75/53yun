//  RecipeSnapshot.swift
//  Recipe ↔ 持久化字段 的纯映射层。
//
//  SwiftData 的 @Model 只存原始列（String / Double / Data 等）。
//  这里把 Engine 的 `Recipe`（值类型，含嵌套数组与枚举）压成可直接落库的快照，
//  以及反向还原。所有逻辑纯函数，便于单测，且与 SwiftData 解耦。

import Foundation

/// 配方的持久化快照：字段都是基础类型 / Data，可直接映射到 @Model 列。
public struct RecipeSnapshot: Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var aromaRaw: String
    public var targetABV: Double
    public var tastingNote: String
    public var componentsData: Data   // [Component] 的 JSON
    public var flavorData: Data       // FlavorProfile 的 JSON

    public init(id: UUID, name: String, aromaRaw: String, targetABV: Double,
                tastingNote: String, componentsData: Data, flavorData: Data) {
        self.id = id
        self.name = name
        self.aromaRaw = aromaRaw
        self.targetABV = targetABV
        self.tastingNote = tastingNote
        self.componentsData = componentsData
        self.flavorData = flavorData
    }
}

/// Recipe ↔ RecipeSnapshot 的双向映射器。
public enum RecipeMapper {
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    /// Recipe → 快照（用于落库）
    public static func snapshot(from recipe: Recipe) -> RecipeSnapshot {
        let components = (try? encoder.encode(recipe.components)) ?? Data("[]".utf8)
        let flavor = (try? encoder.encode(recipe.flavor)) ?? Data()
        return RecipeSnapshot(
            id: recipe.id,
            name: recipe.name,
            aromaRaw: recipe.aroma.rawValue,
            targetABV: recipe.targetABV,
            tastingNote: recipe.tastingNote,
            componentsData: components,
            flavorData: flavor
        )
    }

    /// 快照 → Recipe（用于「一键载入」触发计算）
    public static func recipe(from snapshot: RecipeSnapshot) -> Recipe {
        let components = (try? decoder.decode([Component].self, from: snapshot.componentsData)) ?? []
        let flavor = (try? decoder.decode(FlavorProfile.self, from: snapshot.flavorData)) ?? .zero
        let aroma = AromaType(rawValue: snapshot.aromaRaw) ?? .nongxiang
        return Recipe(
            id: snapshot.id,
            name: snapshot.name,
            aroma: aroma,
            components: components,
            targetABV: snapshot.targetABV,
            tastingNote: snapshot.tastingNote,
            flavor: flavor
        )
    }
}
