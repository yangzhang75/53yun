import XCTest
@testable import Mixing

final class UnitConversionTests: XCTestCase {

    func testStandardCupToMilliliters() {
        let m = VolumeMeasurement(value: 2, unit: .standardCup)
        XCTAssertEqual(m.toMilliliters(), 60, accuracy: 1e-9) // 2 * 30
    }

    func testJiggerConfigurable() {
        let config = MixingConfig(jiggerML: 20)
        let m = VolumeMeasurement(value: 3, unit: .jigger)
        XCTAssertEqual(m.toMilliliters(config), 60, accuracy: 1e-9)
    }

    func testCapConfigurable() {
        let config = MixingConfig(capML: 10)
        XCTAssertEqual(UnitConverter.milliliters(of: 5, in: .cap, config: config), 50, accuracy: 1e-9)
    }

    func testRoundTripConversion() {
        // 90ml -> 标准杯 -> 回 ml
        let ml = VolumeMeasurement(value: 90, unit: .milliliter)
        let cups = ml.converted(to: .standardCup)
        XCTAssertEqual(cups.value, 3, accuracy: 1e-9)
        XCTAssertEqual(cups.toMilliliters(), 90, accuracy: 1e-9)
    }

    func testCrossUnitConversion() {
        // 1 标准杯(30) = 2 分酒器(15)
        let cup = VolumeMeasurement(value: 1, unit: .standardCup)
        let jiggers = cup.converted(to: .jigger)
        XCTAssertEqual(jiggers.value, 2, accuracy: 1e-9)
    }
}
