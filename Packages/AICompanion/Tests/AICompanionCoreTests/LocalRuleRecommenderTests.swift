import XCTest
@testable import AICompanionCore

final class LocalRuleRecommenderTests: XCTestCase {

    private let recommender = LocalRuleRecommender()

    func testEmptyQueryThrows() async {
        do {
            _ = try await recommender.recommend(for: BartenderQuery(text: "   "))
            XCTFail("应抛出 emptyQuery")
        } catch let error as BartenderError {
            XCTAssertEqual(error, .emptyQuery)
        } catch {
            XCTFail("错误类型不符: \(error)")
        }
    }

    func testCanonicalRequest() async throws {
        let rec = try await recommender.recommend(
            for: BartenderQuery(text: "清爽不上头、8 度左右、酱香打底")
        )
        XCTAssertEqual(rec.aroma, .jiangxiang)
        XCTAssertEqual(rec.recipe.targetABV, 8)
        XCTAssertEqual(rec.source, .localRules)
        // 标准 Recipe：基酒成分度数为酱香 53°
        XCTAssertEqual(rec.recipe.components.first?.abv, 53)
        // 含一份 abv 0 的稀释液（加冰）
        XCTAssertTrue(rec.recipe.components.contains { $0.abv == 0 })
        XCTAssertFalse(rec.steps.isEmpty)
        XCTAssertFalse(rec.ratioSummary.isEmpty)
    }

    func testTargetABVNeverExceedsBase() async throws {
        // 要求 60 度但清香基酒 48 → 应被夹到 48
        let rec = try await recommender.recommend(for: BartenderQuery(text: "清香 60 度"))
        XCTAssertLessThanOrEqual(rec.recipe.targetABV, 48)
    }

    func testStrongRequestStaysHigh() async throws {
        let rec = try await recommender.recommend(for: BartenderQuery(text: "够劲的酱香纯饮"))
        XCTAssertGreaterThanOrEqual(rec.recipe.targetABV, 40)
        XCTAssertEqual(rec.method, .neat)
    }

    func testLightRequestIsLowABV() async throws {
        let rec = try await recommender.recommend(for: BartenderQuery(text: "清爽解腻的喝法"))
        XCTAssertLessThanOrEqual(rec.recipe.targetABV, 12)
    }

    func testDefaultsWhenVague() async throws {
        // 完全模糊：仍给出合理兜底（品牌主打酱香 + 微醺度数）
        let rec = try await recommender.recommend(for: BartenderQuery(text: "随便给我来一杯"))
        XCTAssertEqual(rec.aroma, .jiangxiang)
        XCTAssertGreaterThan(rec.recipe.targetABV, 0)
        XCTAssertLessThan(rec.confidence, 0.6) // 命中少 → 置信度低
    }

    func testFlavorProfileInRange() async throws {
        let rec = try await recommender.recommend(for: BartenderQuery(text: "绵柔顺口浓香加冰"))
        XCTAssertTrue((0...1).contains(rec.recipe.flavor.mellow))
        XCTAssertTrue((0...1).contains(rec.recipe.flavor.strength))
    }

    func testFruitHintsAppearInSteps() async throws {
        let rec = try await recommender.recommend(
            for: BartenderQuery(text: "清爽低度", fruitHints: ["青梅"])
        )
        XCTAssertTrue(rec.steps.contains { $0.contains("青梅") })
    }
}
