import XCTest
@testable import Mixing

final class IceDilutionTests: XCTestCase {

    func testNoIceUnchanged() {
        let r = IceDilution.apply(abv: 40, totalML: 100, ice: .none)
        XCTAssertEqual(r.dilutedABV, 40, accuracy: 1e-9)
        XCTAssertEqual(r.dilutedTotalML, 100, accuracy: 1e-9)
        XCTAssertFalse(r.isEstimate)
    }

    func testCubeDilutionLowersABV() {
        // 默认 +15%：40 / 1.15
        let r = IceDilution.apply(abv: 40, totalML: 100, ice: .cube)
        XCTAssertEqual(r.dilutedABV, 40 / 1.15, accuracy: 1e-9)
        XCTAssertEqual(r.dilutedTotalML, 115, accuracy: 1e-9)
        XCTAssertTrue(r.isEstimate)
    }

    func testBigBallLessDilutionThanCube() {
        let cube = IceDilution.apply(abv: 50, totalML: 100, ice: .cube)
        let ball = IceDilution.apply(abv: 50, totalML: 100, ice: .bigBall)
        // 大冰球稀释更少 => 度数更高
        XCTAssertGreaterThan(ball.dilutedABV, cube.dilutedABV)
        XCTAssertEqual(ball.dilutedABV, 50 / 1.08, accuracy: 1e-9)
    }

    func testConfigurableDilution() {
        let config = MixingConfig(cubeDilution: 0.25)
        let r = IceDilution.apply(abv: 40, totalML: 100, ice: .cube, config: config)
        XCTAssertEqual(r.dilutedABV, 40 / 1.25, accuracy: 1e-9)
    }
}
