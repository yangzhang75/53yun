import SwiftUI
import Engine
import DesignSystem

// MARK: - Recipes 模块入口（Feature Module Contract）
//
// 对主工程（员工①）暴露统一入口：Tab 元信息 + 根视图。
// 由于「一键载入到调制器」需要回调路由，主工程应优先使用 `rootView(onLoadIntoMixer:)`，
// 把选中的 Recipe 路由到 Mixing 模块。无回调的 `rootView()` 仅用于纯浏览 / 占位。

public enum RecipesModule: YunModule {

    public static let tab = YunTab(title: "配方", systemImage: "list.bullet.rectangle.portrait")

    /// YunModule 协议要求的无参根视图（纯浏览，无载入路由）。
    public static func rootView() -> AnyView {
        AnyView(RecipeMenuView())
    }

    /// 带「一键载入到调制器」回调的根视图（主工程集成时使用）。
    @MainActor
    public static func rootView(onLoadIntoMixer: @escaping (Recipe) -> Void) -> AnyView {
        AnyView(RecipeMenuView(onLoadIntoMixer: onLoadIntoMixer))
    }
}
