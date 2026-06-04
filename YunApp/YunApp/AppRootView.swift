import SwiftUI
import DesignSystem

// MARK: - 根视图
// 未通过年龄确认门时，主内容不可进入，覆盖全屏的 AgeGateView。
// 年龄标记用 @AppStorage 放在 View 层，保证确认后 SwiftUI 即时刷新并关闭门。

struct AppRootView: View {
    @AppStorage(AppState.ageVerifiedKey) private var ageVerified: Bool = false

    var body: some View {
        RootTabView()
            .fullScreenCover(isPresented: Binding(get: { !ageVerified }, set: { _ in })) {
                AgeGateView(ageVerified: $ageVerified)
            }
    }
}
