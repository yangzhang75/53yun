import XCTest
@testable import Mixing

final class MixingServiceTests: XCTestCase {

    func testMixWithUnitsAndNoIce() {
        let service = MixingService()
        // 2 标准杯(60ml)@53% + 100ml 果汁@0%
        let outcome = service.mix(components: [
            (VolumeMeasurement(value: 2, unit: .standardCup), 53),
            (VolumeMeasurement(value: 100, unit: .milliliter), 0)
        ], ice: .none)

        XCTAssertEqual(outcome.engineResult.totalML, 160, accuracy: 1e-9)
        // 酒精ml = 60*0.53 = 31.8；度数 = 31.8/160*100
        XCTAssertEqual(outcome.finalABV, 31.8 / 160 * 100, accuracy: 1e-6)
    }

    func testIceLowersFinalABVButNotGrams() {
        let service = MixingService()
        let base: [(VolumeMeasurement, Double)] = [
            (VolumeMeasurement(value: 100, unit: .milliliter), 40)
        ]
        let dry = service.mix(components: base, ice: .none)
        let iced = service.mix(components: base, ice: .cube)

        // 加冰后度数更低
        XCTAssertLessThan(iced.finalABV, dry.finalABV)
        // 但纯酒精克数不变（只是加水）
        XCTAssertEqual(iced.engineResult.alcoholGrams,
                       dry.engineResult.alcoholGrams, accuracy: 1e-9)
        // 加冰后总量更大
        XCTAssertGreaterThan(iced.finalTotalML, dry.finalTotalML)
    }

    func testSolveAdditionReachesTarget() {
        let service = MixingService()
        let outcome = service.solveAddition(
            base: [(VolumeMeasurement(value: 100, unit: .milliliter), 0)],
            spiritABV: 53,
            targetABV: 20,
            ice: .none)
        XCTAssertEqual(outcome.engineResult.finalABV, 20, accuracy: 1e-6)
        XCTAssertGreaterThan(outcome.engineResult.addedML, 0)
    }

    func testDisplayTextProduced() {
        let service = MixingService()
        let outcome = service.mix(components: [
            (VolumeMeasurement(value: 100, unit: .milliliter), 40)
        ])
        XCTAssertTrue(outcome.display.standardCupText.contains("标准杯酒精"))
        XCTAssertTrue(outcome.display.pureAlcoholText.contains("克纯酒精"))
    }
}
