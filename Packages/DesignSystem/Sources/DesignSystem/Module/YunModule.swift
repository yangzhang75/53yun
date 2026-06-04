import SwiftUI

// MARK: - 模块入口协议（Feature Module Contract）
//
// 全员约定：每个功能包对外暴露一个遵循 `YunModule` 的类型，提供 Tab 元信息与根视图。
// 员工①（主工程）只依赖本协议来拼装 TabBar / 导航，不关心各模块内部实现。
//
// 用法示例（在功能包里）：
//   public enum MixingModule: YunModule {
//       public static let tab = YunTab(title: "调制", systemImage: "drop.fill")
//       public static func rootView() -> AnyView { AnyView(MixingHomeView()) }
//   }

/// Tab / 入口元信息
public struct YunTab: Hashable, Sendable {
    public let title: String
    public let systemImage: String

    public init(title: String, systemImage: String) {
        self.title = title
        self.systemImage = systemImage
    }
}

/// 功能模块入口协议
@MainActor
public protocol YunModule {
    /// Tab / 入口的标题与图标
    static var tab: YunTab { get }
    /// 模块根视图（类型擦除，便于主工程统一拼装）
    static func rootView() -> AnyView
}
