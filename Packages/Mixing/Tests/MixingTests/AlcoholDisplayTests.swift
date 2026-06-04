import XCTest
import Engine
@testable import Mixing

final class AlcoholDisplayTests: XCTestCase {

    func testTextFromEngineResult() {
        let result = MixResult(addedML: 0, totalML: 100, finalABV: 40,
                               alcoholGrams: 31.6, standardUnits: 3.16)
        let d = AlcoholDisplay(result)
        XCTAssertEqual(d.standardCupText, "本杯≈3.2标准杯酒精")
        XCTAssertEqual(d.pureAlcoholText, "相当于 31.6 克纯酒精")
    }

    func testTrimsTrailingZero() {
        let d = AlcoholDisplay(alcoholGrams: 10, standardUnits: 1)
        XCTAssertEqual(d.standardCupText, "本杯≈1标准杯酒精")
        XCTAssertEqual(d.pureAlcoholText, "相当于 10 克纯酒精")
    }

    func testSummaryCombines() {
        let d = AlcoholDisplay(alcoholGrams: 20, standardUnits: 2)
        XCTAssertEqual(d.summaryText, "本杯≈2标准杯酒精，相当于 20 克纯酒精")
    }
}
