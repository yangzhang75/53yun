import SwiftUI
import Engine
import DesignSystem

// MARK: - DeepLink 模块入口（Feature Module Contract）
//
// 对主工程暴露统一入口：Tab 元信息 + 根视图。
// 「扫码点单」桌牌 ScanToOrderView 需要一个 Recipe；这里用 Engine 的公开初始化器
// 构造一个示例配方，使根视图可零参独立运行。集成时主工程可传入真实选中的 Recipe。

public enum DeepLinkModule: YunModule {

    public static let tab = YunTab(title: "扫码点单", systemImage: "qrcode")

    public static func rootView() -> AnyView {
        AnyView(ScanToOrderView(recipe: sampleRecipe))
    }

    /// 入口展示用的示例配方（自包含，不依赖测试夹具）。
    private static let sampleRecipe = Recipe(
        name: "清露·八度",
        aroma: .qingxiang,
        components: [
            Component(volumeML: 500, abv: 0),
            Component(volumeML: 125, abv: 53)
        ],
        targetABV: 8,
        tastingNote: "清冽回甘，柑橘尾韵，佐餐怡人。"
    )
}
