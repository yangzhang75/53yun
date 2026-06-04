import XCTest
@testable import Engine

final class MixEngineTests: XCTestCase {

    private let acc = 1e-6

    // MARK: - 模式一：解加酒量 Va

    func testSolveAddedVolume() throws {
        // Vj=100, Pa=53, Pt=10 → Va = 1000/43 ≈ 23.255814
        let result = try MixEngine.solve(.addedVolume(juiceML: 100, baseABV: 53, targetABV: 10)).get()

        XCTAssertEqual(result.addedML, 1000.0 / 43.0, accuracy: acc)
        XCTAssertEqual(result.totalML, 100 + 1000.0 / 43.0, accuracy: acc)
        XCTAssertEqual(result.actualABV, 10, accuracy: acc, "重算度数应回到目标 10°")

        // 纯酒精：total × 10% × 0.789 g/mL
        let expectedGrams = result.totalML * 0.10 * 0.789
        XCTAssertEqual(result.alcoholGrams, expectedGrams, accuracy: acc)
        XCTAssertEqual(result.standardUnits, expectedGrams / 10.0, accuracy: acc)
    }

    func testSolveAddedVolume_targetZero_needsNoLiquor() throws {
        let result = try MixEngine.solve(.addedVolume(juiceML: 200, baseABV: 53, targetABV: 0)).get()
        XCTAssertEqual(result.addedML, 0, accuracy: acc)
        XCTAssertEqual(result.actualABV, 0, accuracy: acc)
        XCTAssertEqual(result.alcoholGrams, 0, accuracy: acc)
        XCTAssertEqual(result.standardUnits, 0, accuracy: acc)
    }

    func testSolveAddedVolume_unreachable_whenBaseEqualsTarget() {
        let result = MixEngine.solve(.addedVolume(juiceML: 100, baseABV: 10, targetABV: 10))
        assertFailure(result, MixError.targetUnreachable(target: 10, baseABV: 10))
    }

    func testSolveAddedVolume_unreachable_whenBaseBelowTarget() {
        let result = MixEngine.solve(.addedVolume(juiceML: 100, baseABV: 8, targetABV: 12))
        assertFailure(result, MixError.targetUnreachable(target: 12, baseABV: 8))
    }

    // MARK: - 模式二：解最终度数

    func testSolveFinalABV() throws {
        // Vj=100, Va=50, Pa=53 → Pt = 2650/150 ≈ 17.666667
        let result = try MixEngine.solve(.finalABV(juiceML: 100, addedML: 50, baseABV: 53)).get()
        XCTAssertEqual(result.actualABV, 2650.0 / 150.0, accuracy: acc)
        XCTAssertEqual(result.totalML, 150, accuracy: acc)
        XCTAssertEqual(result.addedML, 50, accuracy: acc)

        let expectedGrams = 150 * (2650.0 / 150.0) / 100.0 * 0.789
        XCTAssertEqual(result.alcoholGrams, expectedGrams, accuracy: acc)
    }

    func testSolveFinalABV_zeroTotalVolume() {
        let result = MixEngine.solve(.finalABV(juiceML: 0, addedML: 0, baseABV: 53))
        assertFailure(result, MixError.zeroTotalVolume)
    }

    func testSolveFinalABV_pureLiquor_noJuice() throws {
        // 不加果汁：成品度数应等于原酒度数。
        let result = try MixEngine.solve(.finalABV(juiceML: 0, addedML: 50, baseABV: 53)).get()
        XCTAssertEqual(result.actualABV, 53, accuracy: acc)
    }

    // MARK: - 模式三：反解所需原酒度数

    func testSolveRequiredBaseABV() throws {
        // Vj=100, Va=50, Pt=20 → Pa = 20×150/50 = 60
        let result = try MixEngine.solve(.requiredBaseABV(juiceML: 100, addedML: 50, targetABV: 20)).get()
        XCTAssertEqual(result.actualABV, 20, accuracy: acc)
        XCTAssertEqual(result.totalML, 150, accuracy: acc)
        // 成品纯酒精：150 × 20% × 0.789
        XCTAssertEqual(result.alcoholGrams, 150 * 0.20 * 0.789, accuracy: acc)
    }

    func testSolveRequiredBaseABV_noLiquor_unreachable() {
        let result = MixEngine.solve(.requiredBaseABV(juiceML: 100, addedML: 0, targetABV: 20))
        assertFailure(result, MixError.targetUnreachable(target: 20, baseABV: 0))
    }

    func testSolveRequiredBaseABV_requiresOver100_unreachable() {
        // Vj=100, Va=10, Pt=20 → Pa = 20×110/10 = 220 > 100
        let result = MixEngine.solve(.requiredBaseABV(juiceML: 100, addedML: 10, targetABV: 20))
        assertFailure(result, MixError.targetUnreachable(target: 20, baseABV: 220))
    }

    func testSolveRequiredBaseABV_targetZero() throws {
        let result = try MixEngine.solve(.requiredBaseABV(juiceML: 100, addedML: 50, targetABV: 0)).get()
        XCTAssertEqual(result.actualABV, 0, accuracy: acc)
    }

    // MARK: - 输入校验（边界）

    func testNegativeVolume_invalidInput() {
        switch MixEngine.solve(.addedVolume(juiceML: -10, baseABV: 53, targetABV: 10)) {
        case .success: XCTFail("负体积应失败")
        case .failure(let e):
            guard case .invalidInput = e else { return XCTFail("应为 invalidInput，实际 \(e)") }
        }
    }

    func testABVOutOfRange() {
        assertFailure(MixEngine.solve(.addedVolume(juiceML: 100, baseABV: 120, targetABV: 10)),
                      MixError.abvOutOfRange(value: 120))
        assertFailure(MixEngine.solve(.addedVolume(juiceML: 100, baseABV: -1, targetABV: 10)),
                      MixError.abvOutOfRange(value: -1))
    }

    func testNonFiniteInput_invalidInput() {
        switch MixEngine.solve(.finalABV(juiceML: .nan, addedML: 50, baseABV: 53)) {
        case .success: XCTFail("NaN 应失败")
        case .failure(let e):
            guard case .invalidInput = e else { return XCTFail("应为 invalidInput，实际 \(e)") }
        }
    }

    // MARK: - 多组分混调

    func testMixMultipleComponents() throws {
        let components = [
            Component(name: "鲜榨橙汁", volumeML: 100, abv: 0),
            Component(name: "53° 原酒", volumeML: 50, abv: 53)
        ]
        let result = try MixEngine.mix(components).get()

        XCTAssertEqual(result.totalML, 150, accuracy: acc)
        XCTAssertEqual(result.actualABV, 2650.0 / 150.0, accuracy: acc) // 加权度数
        XCTAssertEqual(result.addedML, 50, accuracy: acc)               // 仅含酒组分
        XCTAssertEqual(result.alcoholGrams, 50 * 0.53 * 0.789, accuracy: acc)
    }

    func testMixThreeComponents_weightedABV() throws {
        let components = [
            Component(name: "清香原酒", volumeML: 30, abv: 60),
            Component(name: "浓香原酒", volumeML: 30, abv: 40),
            Component(name: "纯净水", volumeML: 40, abv: 0)
        ]
        let result = try MixEngine.mix(components).get()
        // Σ(vol×abv) = 30×60 + 30×40 = 3000；total=100 → 30%
        XCTAssertEqual(result.actualABV, 30, accuracy: acc)
        XCTAssertEqual(result.addedML, 60, accuracy: acc)
    }

    func testMixEmpty() {
        assertFailure(MixEngine.mix([]), MixError.emptyComponents)
    }

    func testMixAllZeroVolume_zeroTotal() {
        let result = MixEngine.mix([Component(name: "x", volumeML: 0, abv: 53)])
        assertFailure(result, MixError.zeroTotalVolume)
    }

    func testMixRejectsInvalidComponent() {
        let result = MixEngine.mix([Component(name: "坏组分", volumeML: 10, abv: 200)])
        assertFailure(result, MixError.abvOutOfRange(value: 200))
    }

    // MARK: - 错误文案可读

    func testErrorMessagesAreReadable() {
        XCTAssertNotNil(MixError.emptyComponents.errorDescription)
        XCTAssertTrue(MixError.targetUnreachable(target: 12, baseABV: 8).errorDescription?.contains("不可达") ?? false)
    }

    // MARK: - 工具

    private func assertFailure(_ result: Result<MixResult, MixError>,
                               _ expected: MixError,
                               file: StaticString = #filePath,
                               line: UInt = #line) {
        switch result {
        case .success:
            XCTFail("预期失败 \(expected)，但成功了", file: file, line: line)
        case .failure(let e):
            XCTAssertEqual(e, expected, file: file, line: line)
        }
    }
}
