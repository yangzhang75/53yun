import XCTest
@testable import Health

final class HealthTests: XCTestCase {
    @MainActor
    func testModuleTabMetadata() {
        XCTAssertEqual(HealthModule.tab.title, "微醺曲线")
        XCTAssertEqual(HealthModule.tab.systemImage, "waveform.path.ecg")
    }
    // TODO(员工⑦): 在此补齐核心逻辑的单元测试。
}
