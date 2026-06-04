import XCTest
@testable import AICompanionCore

final class NaturalLanguageParserTests: XCTestCase {

    func testParsesAromaJiangxiang() {
        let intent = NaturalLanguageParser.parse("酱香打底，来一杯")
        XCTAssertEqual(intent.aroma, .jiangxiang)
    }

    func testParsesAromaQingxiangAndNongxiang() {
        XCTAssertEqual(NaturalLanguageParser.parse("清香一点").aroma, .qingxiang)
        XCTAssertEqual(NaturalLanguageParser.parse("浓香窖香").aroma, .nongxiang)
    }

    func testExplicitABV() {
        XCTAssertEqual(NaturalLanguageParser.parse("8 度左右").targetABV, 8)
        XCTAssertEqual(NaturalLanguageParser.parse("想要12.5°的").targetABV, 12.5)
    }

    func testFullWidthDigitABV() {
        // 全角数字 ８ 度
        XCTAssertEqual(NaturalLanguageParser.parse("大概８度").targetABV, 8)
    }

    func testIgnoresOutOfRangeABV() {
        XCTAssertNil(NaturalLanguageParser.parse("999 度").targetABV)
    }

    func testTasteFlags() {
        let light = NaturalLanguageParser.parse("清爽不上头")
        XCTAssertTrue(light.wantsLight)
        let strong = NaturalLanguageParser.parse("够劲带感")
        XCTAssertTrue(strong.wantsStrong)
        let mellow = NaturalLanguageParser.parse("绵柔顺口")
        XCTAssertTrue(mellow.wantsMellow)
    }

    func testMethodDetection() {
        XCTAssertEqual(NaturalLanguageParser.parse("加冰喝").method, .ice)
        XCTAssertEqual(NaturalLanguageParser.parse("来点苏打气泡").method, .soda)
        XCTAssertEqual(NaturalLanguageParser.parse("纯饮就好").method, .neat)
    }

    func testCompoundRequest() {
        let intent = NaturalLanguageParser.parse("清爽不上头、8 度左右、酱香打底")
        XCTAssertEqual(intent.aroma, .jiangxiang)
        XCTAssertEqual(intent.targetABV, 8)
        XCTAssertTrue(intent.wantsLight)
        XCTAssertGreaterThanOrEqual(intent.matchScore, 3)
    }
}
