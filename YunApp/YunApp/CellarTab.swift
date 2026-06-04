import SwiftUI
import Engine
import CellarCore
import Cellar

// MARK: - 酒柜 Tab 包装
//
// 解决两件事：
// 1) CellarStore 用 @State 持有一次，避免每次刷新都重建（之前 rootView() 内联构造会反复重建）。
// 2) 把酒柜的「载入」回调接到调制台：CellarCore.Recipe（standin）→ Engine.Recipe，
//    写入 appState.pendingRecipe 并切到调制 Tab。

struct CellarTab: View {
    @EnvironmentObject private var appState: AppState
    @State private var store = CellarSample.makeStore()

    var body: some View {
        CellarView(onLoad: { cellarRecipe in
            appState.pendingRecipe = Self.toEngine(cellarRecipe)
            appState.selectedTab = .mixing
        })
        .environment(store)
    }

    /// CellarCore 的 standin Recipe → Engine.Recipe（字段同名直转；风味维度按语义对齐）。
    static func toEngine(_ r: CellarCore.Recipe) -> Engine.Recipe {
        Engine.Recipe(
            id: r.id,
            name: r.name,
            aroma: Engine.AromaType(rawValue: r.aroma.rawValue) ?? .nongxiang,
            components: r.components.map { Engine.Component(volumeML: $0.volumeML, abv: $0.abv) },
            targetABV: r.targetABV,
            tastingNote: r.tastingNote,
            flavor: Engine.FlavorProfile(
                mellow: r.flavor.mellow,
                strength: r.flavor.strength,
                crisp: r.flavor.finish,
                sweet: r.flavor.sweet,
                complexity: r.flavor.aroma
            )
        )
    }
}
