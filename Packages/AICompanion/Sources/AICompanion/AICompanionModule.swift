import SwiftUI
import DesignSystem
import AICompanionCore

// MARK: - AICompanion 模块入口（Feature Module Contract）
//
// 对主工程暴露统一入口：Tab 元信息 + 根视图。
// BartenderChatView 的主初始化器所有参数都有默认值（默认本地兜底 BartenderService、
// 空的 onLoadRecipe 回调），因此可零参构造。集成时主工程可改用带 onLoadRecipe
// 回调的初始化器，把推荐配方路由到 Mixing 计算器。

public enum AICompanionModule: YunModule {

    public static let tab = YunTab(title: "AI 调酒师", systemImage: "sparkles")

    public static func rootView() -> AnyView {
        AnyView(BartenderChatView())
    }
}
