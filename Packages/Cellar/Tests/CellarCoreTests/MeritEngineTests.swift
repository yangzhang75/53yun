import XCTest
@testable import CellarCore

final class MeritEngineTests: XCTestCase {

    // MARK: 等级判定

    func testLevelBoundaries_defaultThresholds() {
        let engine = MeritEngine() // silver 100 / gold 300 / collector 800
        XCTAssertEqual(engine.level(for: 0), .bronze)
        XCTAssertEqual(engine.level(for: 99), .bronze)
        XCTAssertEqual(engine.level(for: 100), .silver)   // 恰好达标即升级
        XCTAssertEqual(engine.level(for: 299), .silver)
        XCTAssertEqual(engine.level(for: 300), .gold)
        XCTAssertEqual(engine.level(for: 799), .gold)
        XCTAssertEqual(engine.level(for: 800), .collector)
        XCTAssertEqual(engine.level(for: 99_999), .collector) // 封顶
    }

    func testLevel_negativePointsClampToBronze() {
        let engine = MeritEngine()
        XCTAssertEqual(engine.level(for: -50), .bronze)
        XCTAssertEqual(engine.progress(for: -50).points, 0)
    }

    func testConfigurableThresholds() {
        let engine = MeritEngine(thresholds: .init(silver: 10, gold: 20, collector: 30))
        XCTAssertEqual(engine.level(for: 9), .bronze)
        XCTAssertEqual(engine.level(for: 10), .silver)
        XCTAssertEqual(engine.level(for: 25), .gold)
        XCTAssertEqual(engine.level(for: 30), .collector)
    }

    // MARK: 计分

    func testPointsPerKind_default() {
        let engine = MeritEngine()
        XCTAssertEqual(engine.points(for: .mix), 20)
        XCTAssertEqual(engine.points(for: .favorite), 10)
    }

    func testPointsPerKind_configurable() {
        let engine = MeritEngine(points: .init(mix: 5, favorite: 3))
        XCTAssertEqual(engine.points(for: .mix), 5)
        XCTAssertEqual(engine.points(for: .favorite), 3)
    }

    // MARK: 进度

    func testProgress_midLevel() {
        let engine = MeritEngine() // silver 100 / gold 300
        let p = engine.progress(for: 200) // 白银区间 [100,300)
        XCTAssertEqual(p.level, .silver)
        XCTAssertEqual(p.next, .gold)
        XCTAssertEqual(p.pointsIntoLevel, 100)   // 200 - 100
        XCTAssertEqual(p.pointsForNext, 100)     // 300 - 200
        XCTAssertEqual(p.fraction, 0.5, accuracy: 0.0001)
    }

    func testProgress_atCollectorIsCapped() {
        let engine = MeritEngine()
        let p = engine.progress(for: 1000)
        XCTAssertEqual(p.level, .collector)
        XCTAssertNil(p.next)
        XCTAssertNil(p.pointsForNext)
        XCTAssertEqual(p.fraction, 1, accuracy: 0.0001)
    }

    func testProgress_atExactBoundaryIsZeroIntoNewLevel() {
        let engine = MeritEngine()
        let p = engine.progress(for: 300) // 刚升黄金
        XCTAssertEqual(p.level, .gold)
        XCTAssertEqual(p.pointsIntoLevel, 0)
        XCTAssertEqual(p.fraction, 0, accuracy: 0.0001)
    }

    // MARK: 等级元数据

    func testLevelOrderingAndTitles() {
        XCTAssertTrue(MeritLevel.bronze < MeritLevel.collector)
        XCTAssertEqual(MeritLevel.bronze.title, "青铜")
        XCTAssertEqual(MeritLevel.silver.title, "白银")
        XCTAssertEqual(MeritLevel.gold.title, "黄金")
        XCTAssertEqual(MeritLevel.collector.title, "典藏")
        XCTAssertNil(MeritLevel.collector.next)
        XCTAssertEqual(MeritLevel.bronze.next, .silver)
    }

    func testThresholdValidation() {
        XCTAssertTrue(MeritThresholds.default.isValid)
        XCTAssertFalse(MeritThresholds(silver: 100, gold: 50, collector: 80).isValid)
        XCTAssertFalse(MeritThresholds(silver: 0, gold: 10, collector: 20).isValid)
    }
}
