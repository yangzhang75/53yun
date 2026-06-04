import SwiftUI
import DesignSystem
import Engine

// MARK: - Health 模块入口
// 归属：员工⑦。当前为地基占位（员工① 提供），接手后把 `rootView()` 换成真实根视图即可。

public enum HealthModule: YunModule {
    public static let tab = YunTab(title: "微醺曲线", systemImage: "waveform.path.ecg")

    public static func rootView() -> AnyView {
        AnyView(HealthHomeView())
    }
}

struct HealthHomeView: View {
    var body: some View {
        FeaturePlaceholder(
            title: "微醺曲线",
            systemImage: "waveform.path.ecg",
            owner: "员工⑦",
            summary: "BAC 微醺曲线，敬请期待。"
        )
    }
}
