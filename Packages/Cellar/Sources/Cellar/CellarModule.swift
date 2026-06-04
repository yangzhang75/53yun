import SwiftUI
import DesignSystem
import CellarCore

// MARK: - Cellar 模块入口（Feature Module Contract）
//
// 对主工程暴露统一入口：Tab 元信息 + 根视图。
// CellarView 通过 @Environment(CellarStore.self) 读取数据，因此 rootView() 需注入
// 一个 CellarStore。这里用包内公开的 CellarSample.makeStore() 构造一个内存示例
// Store，使根视图可零参独立运行；集成时主工程可改注入真实持久化 Store。

public enum CellarModule: YunModule {

    public static let tab = YunTab(title: "我的酒柜", systemImage: "archivebox.fill")

    public static func rootView() -> AnyView {
        AnyView(CellarView().environment(CellarSample.makeStore()))
    }
}
