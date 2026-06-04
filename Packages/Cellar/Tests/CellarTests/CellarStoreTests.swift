//  CellarStoreTests.swift
//  SwiftData 持久化 + 积分集成测试。
//
//  注意：依赖 SwiftData 宏，需在 Xcode / 完整 SDK 下运行（命令行 CommandLineTools 无宏插件）。

import XCTest
import SwiftData
@testable import Cellar
@testable import CellarCore

@MainActor
final class CellarStoreTests: XCTestCase {

    private func makeStore() throws -> (CellarStore, ModelContainer) {
        let container = try CellarSchema.makeContainer(inMemory: true)
        return (CellarStore(context: container.mainContext), container)
    }

    func testSaveRecipeAwardsFavoritePointAndPersists() throws {
        let (store, _) = try makeStore()
        XCTAssertEqual(store.favoritesCount(), 0)
        XCTAssertEqual(store.totalMerit(), 0)

        store.saveRecipe(CellarSample.recipes[0])

        XCTAssertEqual(store.favoritesCount(), 1)
        XCTAssertEqual(store.totalMerit(), 10)            // 收藏 +10
        XCTAssertEqual(store.currentLevel(), .bronze)
    }

    func testSaveSameRecipeTwiceDoesNotDuplicateOrDoubleCount() throws {
        let (store, _) = try makeStore()
        let r = CellarSample.recipes[1]
        store.saveRecipe(r)
        store.saveRecipe(r)                               // 同 id 再存 = 编辑
        XCTAssertEqual(store.favoritesCount(), 1)
        XCTAssertEqual(store.totalMerit(), 10)            // 只计一次
    }

    func testLoadReturnsRecipeAndAwardsMixPoint() throws {
        let (store, _) = try makeStore()
        let saved = store.saveRecipe(CellarSample.recipes[0])
        let loaded = store.load(saved)
        XCTAssertEqual(loaded.id, CellarSample.recipes[0].id)
        XCTAssertEqual(loaded.components, CellarSample.recipes[0].components) // 可触发计算
        XCTAssertEqual(store.totalMerit(), 10 + 20)       // 收藏 + 载入(调制)
    }

    func testRenameAndDelete() throws {
        let (store, _) = try makeStore()
        let saved = store.saveRecipe(CellarSample.recipes[0])
        store.rename(saved, to: "夏夜特调")
        XCTAssertEqual(store.savedRecipes().first?.name, "夏夜特调")
        store.rename(saved, to: "   ")                    // 空白名忽略
        XCTAssertEqual(store.savedRecipes().first?.name, "夏夜特调")

        store.delete(saved)
        XCTAssertEqual(store.favoritesCount(), 0)
        XCTAssertEqual(store.totalMerit(), 10)            // 删除不扣分
    }

    func testLevelReachesSilverAndGold() throws {
        let (store, _) = try makeStore()
        for _ in 0..<5 { store.award(.mix) }              // 100 分
        XCTAssertEqual(store.currentLevel(), .silver)
        for _ in 0..<10 { store.award(.mix) }             // +200 = 300
        XCTAssertEqual(store.currentLevel(), .gold)
    }

    func testEditedNameSurvivesRoundTripIntoRecipe() throws {
        let (store, _) = try makeStore()
        let saved = store.saveRecipe(CellarSample.recipes[0], customName: "我的命名")
        XCTAssertEqual(saved.recipe.name, "我的命名")
    }

    // MARK: 重启后数据仍在（同一磁盘文件的两个 container 实例）

    func testDataPersistsAcrossContainerReopen() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("cellar-persist-\(UUID().uuidString).store")
        let schema = Schema(CellarSchema.models)
        let config = ModelConfiguration(schema: schema, url: url)

        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            let store = CellarStore(context: container.mainContext)
            store.saveRecipe(CellarSample.recipes[2], customName: "持久化测试")
            store.award(.mix)
        }
        // 重新打开同一文件
        let container2 = try ModelContainer(for: schema, configurations: [config])
        let store2 = CellarStore(context: container2.mainContext)
        XCTAssertEqual(store2.favoritesCount(), 1)
        XCTAssertEqual(store2.savedRecipes().first?.name, "持久化测试")
        XCTAssertEqual(store2.totalMerit(), 10 + 20)       // 收藏 + 调制

        try? FileManager.default.removeItem(at: url)
    }
}
