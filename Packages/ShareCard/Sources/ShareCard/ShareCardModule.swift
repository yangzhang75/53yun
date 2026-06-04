import SwiftUI
import Engine
import DesignSystem

// MARK: - ShareCard 模块入口（Feature Module Contract）
//
// 对主工程暴露统一入口：Tab 元信息 + 根视图。
// ShareCardView 需要一个 Recipe；这里用包内公开的 SampleData.recipe 构造可独立
// 运行的实例（QR 槽位由 ShareCardView 的便捷初始化器用 QRCodeSlot 填充）。
// 集成时主工程可传入真实选中的 Recipe。

public enum ShareCardModule: YunModule {

    public static let tab = YunTab(title: "品鉴卡", systemImage: "rectangle.portrait.on.rectangle.portrait.fill")

    public static func rootView() -> AnyView {
        AnyView(ShareCardView(recipe: SampleData.recipe))
    }
}
