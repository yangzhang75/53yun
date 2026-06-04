import SwiftUI
import DesignSystem
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
            tab(.mixing, module: MixingModule.self)
            tab(.recipes, module: RecipesModule.self)
            tab(.cellar, module: CellarModule.self)
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
