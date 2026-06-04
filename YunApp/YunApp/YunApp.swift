import SwiftUI
import DesignSystem
import DeepLink

// MARK: - App 入口
// 微醺之度（53° 雲）。最低 iOS 17，SwiftUI 生命周期。

@main
struct YunApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(appState)
                .preferredColorScheme(.dark) // 墨黑底调性，固定深色
                .tint(YunColor.gold)
                .onOpenURL { url in
                    appState.handle(deepLink: DeepLinkRouter().resolve(url))
                }
        }
    }
}
