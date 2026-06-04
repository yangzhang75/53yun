import SwiftUI
import DesignSystem
import Engine
import Mixing
import Recipes
import Cellar
import Authenticity

// MARK: - 底部 TabBar
// 五个入口：调制 / 配方 / 我的酒柜 / 验真 / 我的。
// 前四个直接复用功能包的 YunModule.rootView()；「我的」为主工程页面。

enum AppTab: Hashable {
    case mixing, recipes, cellar, authenticity, me
}

struct RootTabView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            // 调制台：核心计算器，可接收配方「一键载入」预填（pendingRecipe 变化即重建）。
            NavigationStack {
                MixingCalculatorView(recipe: appState.pendingRecipe)
                    .id(appState.pendingRecipe?.id)
                    .navigationTitle("调制")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem { Label("调制", systemImage: "drop.fill") }
            .tag(AppTab.mixing)

            // 配方菜单：自带 NavigationStack，不再外套；点击「一键载入」→ 路由到调制台。
            RecipeMenuView(onLoadIntoMixer: { recipe in
                appState.pendingRecipe = recipe
                appState.selectedTab = .mixing
            })
            .tabItem { Label("配方", systemImage: "list.bullet.rectangle.portrait") }
            .tag(AppTab.recipes)

            // 我的酒柜：点「载入」→ 桥接成 Engine.Recipe 路由到调制台。
            NavigationStack {
                CellarTab()
                    .navigationTitle("我的酒柜")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem { Label("我的酒柜", systemImage: "archivebox.fill") }
            .tag(AppTab.cellar)

            tab(.authenticity, module: AuthenticityModule.self)

            NavigationStack { MeView() }
                .tabItem { Label("我的", systemImage: "person.crop.circle") }
                .tag(AppTab.me)
        }
    }

    @ViewBuilder
    private func tab<M: YunModule>(_ tag: AppTab, module: M.Type) -> some View {
        NavigationStack {
            module.rootView()
                .navigationTitle(module.tab.title)
                .navigationBarTitleDisplayMode(.inline)
        }
        .tabItem { Label(module.tab.title, systemImage: module.tab.systemImage) }
        .tag(tag)
    }
}

#Preview("RootTab") {
    RootTabView().environmentObject(AppState())
}
