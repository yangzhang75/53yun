import XCTest
@testable import CellarCore

final class RecipeMapperTests: XCTestCase {

    private func sampleRecipe() -> Recipe {
        Recipe(
            id: UUID(),
            name: "清露·八度",
            aroma: .qingxiang,
            components: [
                Component(volumeML: 500, abv: 0),     // 果汁/水
                Component(volumeML: 125, abv: 53),    // 53° 原酒
            ],
            targetABV: 8,
            tastingNote: "清冽回甘，适合佐餐。",
            flavor: FlavorProfile(mellow: 0.8, strength: 0.3, sweet: 0.6, aroma: 0.7, finish: 0.5)
        )
    }

    func testRoundTrip_preservesAllFields() {
        let original = sampleRecipe()
        let snapshot = RecipeMapper.snapshot(from: original)
        let restored = RecipeMapper.recipe(from: snapshot)

        XCTAssertEqual(restored.id, original.id)
        XCTAssertEqual(restored.name, original.name)
        XCTAssertEqual(restored.aroma, original.aroma)
        XCTAssertEqual(restored.targetABV, original.targetABV)
        XCTAssertEqual(restored.tastingNote, original.tastingNote)
        XCTAssertEqual(restored.components, original.components)
        XCTAssertEqual(restored.flavor, original.flavor)
        XCTAssertEqual(restored, original)
    }

    func testSnapshotStoresAromaAsRawString() {
        let snapshot = RecipeMapper.snapshot(from: sampleRecipe())
        XCTAssertEqual(snapshot.aromaRaw, "qingxiang")
    }

    func testRecipeFromCorruptSnapshot_fallsBackGracefully() {
        // 模拟脏数据 / 旧版本：components 与 flavor 无法解码，香型未知
        let bad = RecipeSnapshot(
            id: UUID(), name: "脏数据", aromaRaw: "unknown",
            targetABV: 12, tastingNote: "",
            componentsData: Data("not json".utf8),
            flavorData: Data()
        )
        let recipe = RecipeMapper.recipe(from: bad)
        XCTAssertEqual(recipe.components, [])        // 容错为空
        XCTAssertEqual(recipe.flavor, .zero)         // 容错为零向量
        XCTAssertEqual(recipe.aroma, .nongxiang)     // 未知香型回退
        XCTAssertEqual(recipe.name, "脏数据")
    }

    func testEmptyComponentsRoundTrip() {
        let r = Recipe(name: "空", aroma: .jiangxiang, components: [], targetABV: 53)
        let restored = RecipeMapper.recipe(from: RecipeMapper.snapshot(from: r))
        XCTAssertEqual(restored.components, [])
        XCTAssertEqual(restored.aroma, .jiangxiang)
    }
}
