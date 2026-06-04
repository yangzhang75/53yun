import XCTest
import SwiftUI
import Engine
@testable import ShareCard

@MainActor
final class TastingCardRendererTests: XCTestCase {

    func testPortraitExportsNonEmptyPNG() throws {
        let data = try TastingCardRenderer.png(
            recipe: SampleData.recipe,
            style: .momentsPortrait,
            deepLink: SampleData.previewDeepLink
        )
        XCTAssertGreaterThan(data.count, 0)
        XCTAssertTrue(isPNG(data), "导出数据应为 PNG")
    }

    func testSquareExportsNonEmptyPNG() throws {
        let data = try TastingCardRenderer.png(
            recipe: SampleData.recipe,
            style: .square,
            deepLink: SampleData.previewDeepLink
        )
        XCTAssertTrue(isPNG(data))
    }

    func testHighScaleProducesLargerPixelDimensions() throws {
        let lowData = try TastingCardRenderer.png(
            recipe: SampleData.recipe, style: .square,
            deepLink: SampleData.previewDeepLink, scale: 1
        )
        let highData = try TastingCardRenderer.png(
            recipe: SampleData.recipe, style: .square,
            deepLink: SampleData.previewDeepLink, scale: 3
        )
        // 3x 渲染应显著大于 1x
        XCTAssertGreaterThan(highData.count, lowData.count)
    }

    /// PNG 文件头魔数
    private func isPNG(_ data: Data) -> Bool {
        let signature: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
        guard data.count >= signature.count else { return false }
        return Array(data.prefix(signature.count)) == signature
    }
}
