import XCTest
@testable import Engine

final class ModelsTests: XCTestCase {

    func testRecipeCodableRoundTrip() throws {
        let recipe = Recipe(
            name: "金桂微醺",
            aroma: .jiangxiang,
            components: [
                Component(name: "53° 原酒", volumeML: 40, abv: 53),
                Component(name: "桂花蜜", volumeML: 10, abv: 0),
                Component(name: "鲜橙汁", volumeML: 150, abv: 0)
            ],
            targetABV: 10.6,
            tastingNote: "酱香打底，桂花回甘，请理性饮酒。",
            flavor: FlavorProfile(mellow: 0.8, strength: 0.4, crisp: 0.6, sweet: 0.7, complexity: 0.9)
        )

        let data = try JSONEncoder().encode(recipe)
        let decoded = try JSONDecoder().decode(Recipe.self, from: data)

        XCTAssertEqual(decoded, recipe, "Recipe 编解码应保持完全一致")
    }

    func testAromaTypeStableRawValues() {
        // 原始值用于持久化与深链编码，必须保持稳定。
        XCTAssertEqual(AromaType.qingxiang.rawValue, "qingxiang")
        XCTAssertEqual(AromaType.jiangxiang.rawValue, "jiangxiang")
        XCTAssertEqual(AromaType.nongxiang.rawValue, "nongxiang")
        XCTAssertEqual(AromaType.allCases.count, 3)
    }

    func testAromaDisplayNames() {
        XCTAssertEqual(AromaType.qingxiang.displayName, "清香")
        XCTAssertEqual(AromaType.jiangxiang.displayName, "酱香")
        XCTAssertEqual(AromaType.nongxiang.displayName, "浓香")
    }
}
