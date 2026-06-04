import SwiftUI
import DesignSystem

// MARK: - Health 模块入口（Feature Module Contract）
//
// 对主工程暴露统一入口：Tab 元信息 + 根视图。
// BACDashboardView 提供便捷初始化器，可直接传入纯酒精克数（集成时由 Engine
// MixResult 提供）。这里用一个示例值构造可独立运行的实例；集成后主工程改用真实
// 纯酒精摄入量。

public enum HealthModule: YunModule {

    public static let tab = YunTab(title: "微醺曲线", systemImage: "waveform.path.ecg")

    public static func rootView() -> AnyView {
        AnyView(BACDashboardView(pureAlcoholGrams: 24, drinkingDurationHours: 1.5))
    }
}
