import XCTest
import SwiftUI
@testable import DesignSystem

final class DesignSystemTests: XCTestCase {

    func testHexParsingRGB() {
        let c = Color(hex: "#C4A463")
        // 通过 resolve 校验通道值（iOS 17 / macOS 14+）
        let resolved = c.resolve(in: EnvironmentValues())
        XCTAssertEqual(Double(resolved.red), 0xC4 / 255.0, accuracy: 0.01)
        XCTAssertEqual(Double(resolved.green), 0xA4 / 255.0, accuracy: 0.01)
        XCTAssertEqual(Double(resolved.blue), 0x63 / 255.0, accuracy: 0.01)
    }

    func testHexParsingWithoutHash() {
        let a = Color(hex: "0A0A0C").resolve(in: EnvironmentValues())
        let b = Color(hex: "#0A0A0C").resolve(in: EnvironmentValues())
        XCTAssertEqual(a.red, b.red, accuracy: 0.001)
        XCTAssertEqual(a.blue, b.blue, accuracy: 0.001)
    }

    func testTabContract() {
        let tab = YunTab(title: "调制", systemImage: "drop.fill")
        XCTAssertEqual(tab.title, "调制")
        XCTAssertEqual(tab.systemImage, "drop.fill")
    }
}
