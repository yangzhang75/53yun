import XCTest
import Engine
@testable import Recipes

final class RecipeLibraryTests: XCTestCase {

    func testLoadsFromResourceWithoutThrowing() throws {
        let recipes = try RecipeLibrary.load()
        XCTAssertFalse(recipes.isEmpty, "应能从 recipes.json 解码出配方")
    }

    func testAtLeastEightOfficialRecipes() {
        XCTAssertGreaterThanOrEqual(RecipeLibrary.all.count, 8, "至少内置 8 款官方配方")
    }

    func testCoversAllThreeAromaTypes() {
        let aromas = Set(RecipeLibrary.all.map(\.aroma))
        XCTAssertTrue(aromas.contains(.qingxiang), "需覆盖清香")
        XCTAssertTrue(aromas.contains(.jiangxiang), "需覆盖酱香")
        XCTAssertTrue(aromas.contains(.nongxiang), "需覆盖浓香")
    }

    func testEveryRecipeIsComplete() {
        for r in RecipeLibrary.all {
            XCTAssertFalse(r.name.isEmpty, "配方需有名称")
            XCTAssertFalse(r.tastingNote.isEmpty, "配方需有品鉴文案：\(r.name)")
            XCTAssertFalse(r.components.isEmpty, "配方需有成分：\(r.name)")
            XCTAssertGreaterThan(r.targetABV, 0, "目标度数需 > 0：\(r.name)")
            XCTAssertLessThanOrEqual(r.targetABV, 100, "目标度数需 <= 100：\(r.name)")
        }
    }

    func testFlavorValuesWithinUnitRange() {
        for r in RecipeLibrary.all {
            for (axis, value) in zip(FlavorAxis.allCases, r.flavor.axisValues) {
                XCTAssertTrue((0...1).contains(value),
                              "\(r.name) 的 \(axis.displayName) 应在 0~1，实际 \(value)")
            }
        }
    }

    func testRecipeIDsAreUnique() {
        let ids = RecipeLibrary.all.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "配方 id 不应重复")
    }

    func testTargetABVRoughlyMatchesComponents() {
        // 目标度数应与成分配比大致吻合（容差 3 个百分点），保证数据自洽。
        for r in RecipeLibrary.all {
            let totalML = r.components.reduce(0) { $0 + $1.volumeML }
            let alcoholML = r.components.reduce(0) { $0 + $1.volumeML * $1.abv / 100.0 }
            guard totalML > 0 else { continue }
            let computed = alcoholML / totalML * 100.0
            XCTAssertEqual(computed, r.targetABV, accuracy: 3.0,
                           "\(r.name) 的成分配比(\(computed))应与目标度数(\(r.targetABV))大致吻合")
        }
    }

    func testGroupedPreservesAromaOrder() {
        let grouped = RecipeLibrary.grouped()
        let order = grouped.map(\.aroma)
        XCTAssertEqual(order, [.qingxiang, .jiangxiang, .nongxiang].filter { aroma in
            RecipeLibrary.all.contains { $0.aroma == aroma }
        })
    }
}
