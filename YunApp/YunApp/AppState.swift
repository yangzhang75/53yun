import SwiftUI
import DeepLink
import Engine

// MARK: - 全局 App 状态
// 负责：年龄确认门状态、深链路由转发、被选中的配方（待各模块消费）。

@MainActor
final class AppState: ObservableObject {
    /// 年龄确认门的持久化 key（实际读写在 View 层用 @AppStorage，确保 SwiftUI 正确刷新）。
    static let ageVerifiedKey = "yun.ageVerified"

    /// 当前选中 Tab
    @Published var selectedTab: AppTab = .mixing

    /// 由深链还原的待处理配方（模块接手后消费）
    @Published var pendingRecipe: Recipe?
    /// 由深链拿到、待按 id 取回的配方标识
    @Published var pendingRecipeID: String?

    func handle(deepLink: YunDeepLink) {
        switch deepLink {
        case .recipe(let recipe):
            pendingRecipe = recipe
            selectedTab = .mixing
        case .recipeID(let id):
            pendingRecipeID = id
            selectedTab = .recipes
        case .unknown:
            break
        }
    }
}
