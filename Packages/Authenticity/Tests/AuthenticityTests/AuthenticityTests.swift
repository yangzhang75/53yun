import XCTest
@testable import Authenticity

final class AuthenticityTests: XCTestCase {

    // MARK: - 防伪码校验

    func testValidatorNormalize() {
        XCTAssertEqual(AuthCodeValidator.normalize(" yun-2018 jx0427a "), "YUN2018JX0427A")
    }

    func testValidatorAcceptsWellFormedCode() {
        XCTAssertTrue(AuthCodeValidator.isValid("YUN2018JX0427A"))
        XCTAssertTrue(AuthCodeValidator.isValid("yun-2018-jx-0427-a"))  // 规范化后合法
    }

    func testValidatorRejectsTooShortAndIllegalChars() {
        XCTAssertFalse(AuthCodeValidator.isValid("YUN001"))           // 太短
        XCTAssertFalse(AuthCodeValidator.isValid("YUN_2018#JX0427A"))  // 非法字符
        XCTAssertFalse(AuthCodeValidator.isValid(""))                 // 空
    }

    // MARK: - Mock 服务行为

    func testMockReturnsAuthenticWithFullTimeline() async throws {
        let service = MockAuthenticityService(latency: .zero)
        let result = try await service.verify(code: "YUN2018JX0427A", channel: .scan)

        XCTAssertEqual(result.status, .authentic)
        XCTAssertTrue(result.status.isAuthentic)
        XCTAssertEqual(result.product?.aroma, .jiangxiang)
        XCTAssertEqual(result.trace.count, 3)
        XCTAssertEqual(result.trace.map(\.stage), ["酿造", "封坛", "出厂"])
    }

    func testMockReturnsCounterfeit() async throws {
        let service = MockAuthenticityService(latency: .zero)
        let result = try await service.verify(code: "FAKE000000000000", channel: .manual)
        XCTAssertEqual(result.status, .counterfeit)
        XCTAssertFalse(result.status.isAuthentic)
        XCTAssertNil(result.product)
    }

    func testMockReturnsUnknownForUnseenValidCode() async throws {
        let service = MockAuthenticityService(latency: .zero)
        let result = try await service.verify(code: "YUN0000NOTFOUND9", channel: .manual)
        XCTAssertEqual(result.status, .unknown)
    }

    func testMockReturnsAlreadyScannedWithCount() async throws {
        let service = MockAuthenticityService(latency: .zero)
        let result = try await service.verify(code: "YUN9999RESCAN001", channel: .scan)
        XCTAssertEqual(result.status, .alreadyScanned)
        XCTAssertGreaterThan(result.scanCount, 1)
        XCTAssertNotNil(result.product)  // 仍展示产品信息
    }

    func testMockThrowsOnEmptyCode() async {
        let service = MockAuthenticityService(latency: .zero)
        await assertThrows(.emptyCode) {
            _ = try await service.verify(code: "   ", channel: .manual)
        }
    }

    func testMockThrowsOnMalformedCode() async {
        let service = MockAuthenticityService(latency: .zero)
        await assertThrows(.malformedCode) {
            _ = try await service.verify(code: "ABC", channel: .manual)
        }
    }

    // MARK: - 解码（验证后端协议契约）

    func testDecodeVerificationResultFromJSON() throws {
        let json = """
        {
          "status": "authentic",
          "code": "YUN2018JX0427A",
          "product": {
            "name": "53° 雲 · 酱香典藏",
            "batch": "JX-20180917-0427",
            "vintage": 2018,
            "aroma": "jiangxiang",
            "abv": 53,
            "net_volume_ml": 500,
            "distillery": "赤水河畔 · 雲酒坊",
            "story": "古法酿艺。"
          },
          "trace": [
            {"stage":"酿造","title":"端午制曲","date":"2018-09-17","location":"赤水河谷","detail":"投粮。"}
          ],
          "scan_count": 1,
          "first_scanned_at": "2026-06-03 20:14",
          "verified_at": "2026-06-03 20:14"
        }
        """.data(using: .utf8)!

        let result = try JSONDecoder().decode(VerificationResult.self, from: json)
        XCTAssertEqual(result.status, .authentic)
        XCTAssertEqual(result.product?.netVolumeML, 500)
        XCTAssertEqual(result.product?.aroma, .jiangxiang)
        XCTAssertEqual(result.scanCount, 1)
        XCTAssertEqual(result.trace.first?.stage, "酿造")
        XCTAssertNotNil(result.trace.first?.id)  // id 缺省时本地生成
    }

    func testDecodeUnknownAromaFallsBackGracefully() throws {
        let json = #"{"status":"authentic","code":"YUN2018XX0427A","product":{"name":"x","batch":"b","vintage":2020,"aroma":"future_aroma","abv":53,"net_volume_ml":500,"distillery":"d","story":"s"},"trace":[]}"#
            .data(using: .utf8)!
        let result = try JSONDecoder().decode(VerificationResult.self, from: json)
        XCTAssertEqual(result.product?.aroma, .unknown)  // 未知香型兜底
    }

    func testEncodeRequestUsesExpectedKeys() throws {
        let req = VerificationRequest(code: "YUN2018JX0427A", channel: .scan)
        let data = try JSONEncoder().encode(req)
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(obj?["code"] as? String, "YUN2018JX0427A")
        XCTAssertEqual(obj?["channel"] as? String, "scan")
    }

    // MARK: - ViewModel

    @MainActor
    func testViewModelTransitionsToResultOnAuthentic() async {
        let vm = AuthenticityViewModel(service: MockAuthenticityService(latency: .zero))
        vm.code = "YUN2018JX0427A"
        XCTAssertTrue(vm.canSubmit)
        vm.verify(channel: .manual)
        await settle()
        guard case .result(let r) = vm.phase else {
            return XCTFail("应进入 result 阶段，实际：\(vm.phase)")
        }
        XCTAssertEqual(r.status, .authentic)
    }

    @MainActor
    func testViewModelCanSubmitFalseForBadInput() {
        let vm = AuthenticityViewModel(service: MockAuthenticityService(latency: .zero))
        vm.code = "abc"
        XCTAssertFalse(vm.canSubmit)
    }

    @MainActor
    func testViewModelClearResetsState() async {
        let vm = AuthenticityViewModel(service: MockAuthenticityService(latency: .zero))
        vm.code = "YUN2018JX0427A"
        vm.verify(channel: .manual)
        await settle()
        vm.clear()
        XCTAssertEqual(vm.code, "")
        guard case .idle = vm.phase else { return XCTFail("clear 后应回到 idle") }
    }

    // MARK: - Helpers

    private func assertThrows(_ expected: AuthenticityError,
                              _ body: () async throws -> Void,
                              file: StaticString = #filePath, line: UInt = #line) async {
        do {
            try await body()
            XCTFail("应抛出 \(expected)", file: file, line: line)
        } catch let error as AuthenticityError {
            XCTAssertEqual(error, expected, file: file, line: line)
        } catch {
            XCTFail("抛出了非预期错误：\(error)", file: file, line: line)
        }
    }

    /// 让 ViewModel 内部的 Task 完成。
    @MainActor
    private func settle() async {
        for _ in 0..<50 {
            await Task.yield()
            try? await Task.sleep(for: .milliseconds(5))
        }
    }
}
