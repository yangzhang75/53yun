//  CellarStore.swift
//  酒柜业务门面：封装 SwiftData 的增删改查 + 微醺积分发放。
//
//  作为 @Observable ViewModel 注入视图。所有写操作都走这里，保证
//  「收藏即计分」「调制即计分」的一致性。

import Foundation
import SwiftData
import CellarCore

@MainActor
@Observable
public final class CellarStore {
    private let context: ModelContext
    /// 强引用持有容器，防止内存容器被提前释放导致 context 失效而崩溃。
    private let retainedContainer: ModelContainer?
    public let merit: MeritEngine

    public init(context: ModelContext,
                container: ModelContainer? = nil,
                merit: MeritEngine = MeritEngine()) {
        self.context = context
        self.retainedContainer = container
        self.merit = merit
    }

    // MARK: - 读取

    public func savedRecipes() -> [SavedRecipe] {
        let descriptor = FetchDescriptor<SavedRecipe>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    public func savedSpirits() -> [SavedSpirit] {
        let descriptor = FetchDescriptor<SavedSpirit>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    public func meritRecords() -> [MeritRecord] {
        let descriptor = FetchDescriptor<MeritRecord>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    public func favoritesCount() -> Int {
        (try? context.fetchCount(FetchDescriptor<SavedRecipe>())) ?? 0
    }

    // MARK: - 积分 / 等级

    public func totalMerit() -> Int {
        meritRecords().reduce(0) { $0 + $1.points }
    }

    public func currentLevel() -> MeritLevel {
        merit.level(for: totalMerit())
    }

    public func currentProgress() -> MeritProgress {
        merit.progress(for: totalMerit())
    }

    /// 记一次积分事件
    @discardableResult
    public func award(_ kind: MeritKind, note: String = "") -> MeritRecord {
        let record = MeritRecord(kind: kind, points: merit.points(for: kind), note: note)
        context.insert(record)
        save()
        return record
    }

    // MARK: - 收藏配方（收藏即计分）

    /// 收藏 / 更新一个配方。已存在（同 recipeID）则覆盖编辑，不重复计分。
    @discardableResult
    public func saveRecipe(_ recipe: Recipe, customName: String? = nil) -> SavedRecipe {
        if let existing = find(recipeID: recipe.id) {
            existing.update(from: recipe)
            if let customName { existing.name = customName }
            save()
            return existing
        }
        let snapshot = RecipeMapper.snapshot(from: recipe)
        let saved = SavedRecipe(snapshot: snapshot)
        if let customName { saved.name = customName }
        context.insert(saved)
        award(.favorite, note: saved.name) // 新收藏计一分
        save()
        return saved
    }

    /// 重命名
    public func rename(_ saved: SavedRecipe, to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        saved.name = trimmed
        saved.updatedAt = .now
        save()
    }

    /// 删除收藏（删除不扣分，积分明细不可逆）
    public func delete(_ saved: SavedRecipe) {
        context.delete(saved)
        save()
    }

    /// 「一键载入」：还原为 Recipe，交由 Engine / Mixing 触发计算。
    /// 载入视为一次「调制」，计调制分。
    public func load(_ saved: SavedRecipe) -> Recipe {
        award(.mix, note: saved.name)
        return saved.recipe
    }

    public func find(recipeID: UUID) -> SavedRecipe? {
        let descriptor = FetchDescriptor<SavedRecipe>(
            predicate: #Predicate { $0.recipeID == recipeID }
        )
        return try? context.fetch(descriptor).first
    }

    public func isFavorited(_ recipe: Recipe) -> Bool {
        find(recipeID: recipe.id) != nil
    }

    // MARK: - 常用原酒

    @discardableResult
    public func addSpirit(name: String, abv: Double, stockML: Double = 0,
                          aroma: AromaType = .nongxiang) -> SavedSpirit {
        let spirit = SavedSpirit(name: name, abv: abv, stockML: stockML, aroma: aroma)
        context.insert(spirit)
        save()
        return spirit
    }

    public func delete(_ spirit: SavedSpirit) {
        context.delete(spirit)
        save()
    }

    public func updateSpirit(_ spirit: SavedSpirit, name: String, abv: Double, stockML: Double) {
        spirit.name = name
        spirit.abv = abv
        spirit.stockML = stockML
        save()
    }

    // MARK: - 持久化

    private func save() {
        do {
            try context.save()
        } catch {
            // SwiftData 在 autosave 下通常无需显式 save；保存失败仅记录，不崩溃。
            print("⚠️ Cellar 保存失败: \(error)")
        }
    }
}
