import SwiftUI
import DesignSystem

// MARK: - Authenticity 模块入口（Feature Module Contract）
//
// 对主工程暴露统一入口：Tab 元信息 + 根视图。
// AuthenticityView 需要注入一个 AuthenticityViewModel。这里用包内公开的
// MockAuthenticityService 构造一个可独立运行的实例；集成上线时主工程可改注入
// RemoteAuthenticityService。

public enum AuthenticityModule: YunModule {

    public static let tab = YunTab(title: "验真", systemImage: "checkmark.seal.fill")

    public static func rootView() -> AnyView {
        AnyView(AuthenticityView(viewModel: AuthenticityViewModel(service: MockAuthenticityService())))
    }
}
