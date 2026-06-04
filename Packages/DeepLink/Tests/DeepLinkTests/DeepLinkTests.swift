import XCTest
import CoreGraphics
@testable import DeepLink
import Engine

final class RecipeCodecTests: XCTestCase {

    func testEncodeDecodeRoundTrip() throws {
        let payload = try RecipeCodec.encode(.sample)
        let decoded = try RecipeCodec.decode(payload: payload)
        XCTAssertEqual(decoded, Recipe.sample)
    }

    func testPayloadIsBase64URLSafe() throws {
        let payload = try RecipeCodec.encode(.sample)
        // base64url 不应包含 +、/、= ——否则塞进 URL 会被转义破坏。
        XCTAssertFalse(payload.contains("+"))
        XCTAssertFalse(payload.contains("/"))
        XCTAssertFalse(payload.contains("="))
    }

    func testDecodeIsDeterministic() throws {
        // sortedKeys 保证同一配方 → 同一载荷（利于二维码缓存 / 比对）。
        XCTAssertEqual(try RecipeCodec.encode(.sample), try RecipeCodec.encode(.sample))
    }

    func testEmptyPayloadThrows() {
        XCTAssertThrowsError(try RecipeCodec.decode(payload: "   ")) { error in
            XCTAssertEqual(error as? DeepLinkError, .emptyPayload)
        }
    }

    func testMalformedBase64Throws() {
        XCTAssertThrowsError(try RecipeCodec.decode(payload: "@@@not base64@@@")) { error in
            XCTAssertEqual(error as? DeepLinkError, .malformedBase64)
        }
    }

    func testValidBase64ButInvalidJSONThrows() {
        let notJSON = Base64URL.encode(Data("hello world".utf8))
        XCTAssertThrowsError(try RecipeCodec.decode(payload: notJSON)) { error in
            guard case .invalidJSON = (error as? DeepLinkError) else {
                return XCTFail("应为 invalidJSON，实际：\(error)")
            }
        }
    }

    // MARK: 容错

    func testToleratesStandardBase64() throws {
        // 用标准 base64（带 +//=）也应能解出。
        let json = try JSONEncoder().encode(Recipe.sample)
        let standard = json.base64EncodedString() // 标准 base64，可能含 + / =
        let decoded = try RecipeCodec.decode(payload: standard)
        XCTAssertEqual(decoded, Recipe.sample)
    }

    func testToleratesWhitespaceAndNewlines() throws {
        var payload = try RecipeCodec.encode(.sample)
        // 模拟排版软件把长串折行 + 首尾空格。
        let mid = payload.index(payload.startIndex, offsetBy: payload.count / 2)
        payload.insert(contentsOf: "\n  ", at: mid)
        let decoded = try RecipeCodec.decode(payload: " \(payload) ")
        XCTAssertEqual(decoded, Recipe.sample)
    }

    func testToleratesPercentEncodedPayload() throws {
        let raw = try RecipeCodec.encode(.sample)
        let percent = raw.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? raw
        let decoded = try RecipeCodec.decode(payload: percent)
        XCTAssertEqual(decoded, Recipe.sample)
    }
}

final class DeepLinkParserTests: XCTestCase {

    func testResolveCustomScheme() throws {
        let url = try RecipeCodec.customSchemeURL(for: .sample)
        XCTAssertEqual(url.scheme, "yun")
        guard case .recipe(let r) = DeepLinkParser.resolve(url) else {
            return XCTFail("应解析为 recipe")
        }
        XCTAssertEqual(r, Recipe.sample)
    }

    func testResolveUniversalLink() throws {
        let url = try RecipeCodec.universalLinkURL(for: .sample)
        XCTAssertEqual(url.scheme, "https")
        XCTAssertEqual(url.host, "yun53.com")
        XCTAssertTrue(url.path.hasPrefix("/r/"))
        guard case .recipe(let r) = DeepLinkParser.resolve(url) else {
            return XCTFail("应解析为 recipe")
        }
        XCTAssertEqual(r, Recipe.sample)
    }

    func testUniversalLinkWithQueryOverridesPath() throws {
        // /r/<旧token>?c=<新载荷> —— 应以 c 为准。
        let payload = try RecipeCodec.encode(.sample)
        let url = URL(string: "https://yun53.com/r/OLDID?c=\(payload)")!
        guard case .recipe(let r) = DeepLinkParser.resolve(url) else {
            return XCTFail("应解析为 recipe")
        }
        XCTAssertEqual(r, Recipe.sample)
    }

    func testShortIDFallsBackToLookup() {
        let url = URL(string: "https://yun53.com/r/abc123")!
        guard case .needsLookup(let id) = DeepLinkParser.resolve(url) else {
            return XCTFail("短 id 应走 needsLookup")
        }
        XCTAssertEqual(id, "abc123")
    }

    func testWWWHostAllowed() throws {
        let payload = try RecipeCodec.encode(.sample)
        let url = URL(string: "https://www.yun53.com/r/\(payload)")!
        guard case .recipe = DeepLinkParser.resolve(url) else {
            return XCTFail("www. 主机应被允许")
        }
    }

    func testUnsupportedSchemeFails() {
        let url = URL(string: "ftp://whatever/x")!
        guard case .failed(.unsupportedScheme) = DeepLinkParser.resolve(url) else {
            return XCTFail("应为 unsupportedScheme")
        }
    }

    func testUnsupportedHostFails() {
        let url = URL(string: "https://evil.example.com/r/abc")!
        guard case .failed(.unsupportedHost) = DeepLinkParser.resolve(url) else {
            return XCTFail("应为 unsupportedHost")
        }
    }

    func testCanHandle() throws {
        XCTAssertTrue(DeepLinkParser.canHandle(URL(string: "yun://recipe?c=x")!))
        XCTAssertTrue(DeepLinkParser.canHandle(URL(string: "https://yun53.com/r/x")!))
        XCTAssertFalse(DeepLinkParser.canHandle(URL(string: "https://apple.com")!))
    }
}

final class DeepLinkRouterTests: XCTestCase {
    @MainActor
    func testRouterInvokesRecipeCallback() throws {
        var received: Recipe?
        let router = DeepLinkRouter(onRecipe: { received = $0 })
        let url = try RecipeCodec.customSchemeURL(for: .sample)
        router.handle(url)
        XCTAssertEqual(received, Recipe.sample)
        XCTAssertEqual(router.lastResolution, .recipe(.sample))
    }

    @MainActor
    func testRouterInvokesFailureCallback() {
        var failure: DeepLinkError?
        let router = DeepLinkRouter(onFailure: { failure = $0 })
        router.handle(URL(string: "ftp://nope")!)
        guard case .unsupportedScheme = failure else {
            return XCTFail("应回调 unsupportedScheme")
        }
    }
}

final class GildedQRCodeTests: XCTestCase {
    func testGeneratesScannableImage() {
        let img = GildedQRCode.cgImage(from: "https://yun53.com/r/abc", size: 300)
        let cg = try? XCTUnwrap(img)
        // 放大后应接近请求尺寸（整数倍逻辑），且非空。
        XCTAssertNotNil(cg)
        if let cg { XCTAssertGreaterThan(cg.width, 0) }
    }

    func testGeneratesFromRecipe() {
        XCTAssertNotNil(GildedQRCode.cgImage(for: .sample, size: 256))
    }

    func testEmptyStringReturnsNil() {
        XCTAssertNil(GildedQRCode.cgImage(from: "", size: 200))
    }
}
