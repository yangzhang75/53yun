import SwiftUI
import DesignSystem

// MARK: - Mixing 模块入口（Feature Module Contract）
//
// 对主工程暴露统一入口：Tab 元信息 + 根视图。
//
// 说明：本包当前只导出了纯逻辑计算服务（MixingService）与一个「单位 / 冰量选择器」
// 组件（UnitIcePickerView），尚无成型的「调制主页」View。为满足 YunModule 的零参
// rootView() 契约，这里提供一个自包含的占位主页 MixingHomeView，使用 DesignSystem
// 的真实色彩 / 字体令牌，可零参独立运行；集成后由真正的调制器界面替换。
//
// 历史说明：UnitIcePickerView.swift 早期引用过 DesignSystem 中已不存在的字体 /
// 次级文字色令牌，现已统一迁移到 Font.yunBody / Font.yunTitle 与 YunColor.cream /
// YunColor.creamSecondary 等真实令牌。本入口仍刻意不嵌入 UnitIcePickerView，
// 保持占位主页的最小依赖。

public enum MixingModule: YunModule {

    public static let tab = YunTab(title: "调制", systemImage: "drop.fill")

    public static func rootView() -> AnyView {
        AnyView(MixingHomeView())
    }
}

/// 自包含的调制入口占位主页（仅使用 DesignSystem 真实令牌）。
struct MixingHomeView: View {
    var body: some View {
        ZStack {
            MistBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: YunMetrics.spacingM) {
                    YunCard {
                        VStack(alignment: .leading, spacing: YunMetrics.spacingS) {
                            Text("调制台")
                                .font(.yunTitle(22, weight: .semibold))
                                .foregroundStyle(YunColor.cream)
                            Text("度数计算 · 加冰稀释 · 单位换算")
                                .font(.yunBody(.footnote))
                                .foregroundStyle(YunColor.creamSecondary)
                        }
                    }
                    Text("选择基酒与配料，雲 调制引擎将实时估算最终度数与纯酒精摄入量。")
                        .font(.yunBody(.callout))
                        .foregroundStyle(YunColor.creamSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(YunMetrics.spacingM)
            }
        }
    }
}
