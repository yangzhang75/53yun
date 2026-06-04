import XCTest
import Engine
@testable import ShareCard

final class DeepLinkBuilderTests: XCTestCase {

    private var recipe: Recipe { SampleData.recipe }

    func testCustomSchemeURLFormat() throws {
        let url = try DeepLinkBuilder.customSchemeURL(for: recipe)
        XCTAssertEqual(url.scheme, "yun")
        XCTAssertEqual(url.host, "recipe")
        XCTAssertTrue(url.absoluteString.hasPrefix("yun://recipe?c="),
                      "实际: \(url.absoluteString)")
    }

    func testUniversalLinkFormat() throws {
        let url = try XCTUnwrap(DeepLinkBuilder.universalLink(for: recipe))
        XCTAssertEqual(url.absoluteString,
                       "https://yun53.com/r/\(recipe.id.uuidString)")
    }

    func testCodeIsURLSafeBase64() throws {
        let code = try DeepLinkBuilder.encode(recipe)
        // base64url 不应包含标准 base64 的 +、/、=
        XCTAssertFalse(code.contains("+"))
        XCTAssertFalse(code.contains("/"))
        XCTAssertFalse(code.contains("="))
        XCTAssertFalse(code.isEmpty)
    }

    func testEncodeDecodeRoundTrip() throws {
        let code = try DeepLinkBuilder.encode(recipe)
        let restored = try DeepLinkBuilder.decode(code: code)
        XCTAssertEqual(restored, recipe)
    }

    func testRecipeFromURLRoundTrip() throws {
        let url = try DeepLinkBuilder.customSchemeURL(for: recipe)
        let restored = try DeepLinkBuilder.recipe(from: url)
        XCTAssertEqual(restored, recipe)
    }

    func testEncodingIsDeterministic() throws {
        let a = try DeepLinkBuilder.encode(recipe)
        let b = try DeepLinkBuilder.encode(recipe)
        XCTAssertEqual(a, b, "sortedKeys 应保证编码稳定")
    }

    func testRejectsUnsupportedScheme() {
        let url = URL(string: "https://example.com/x")!
        XCTAssertThrowsError(try DeepLinkBuilder.recipe(from: url)) { error in
            XCTAssertEqual(error as? DeepLinkError, .unsupportedURL)
        }
    }

    func testRejectsMissingCode() {
        let url = URL(string: "yun://recipe")!
        XCTAssertThrowsError(try DeepLinkBuilder.recipe(from: url)) { error in
            XCTAssertEqual(error as? DeepLinkError, .missingCode)
        }
    }

    func testRejectsInvalidBase64() {
        XCTAssertThrowsError(try DeepLinkBuilder.decode(code: "!!!not-base64!!!"))
    }
}
