//  UnitIcePickerView.swift
//  「单位 / 冰量选择器」组件，使用 DesignSystem 墨黑 + 烫金样式。

import SwiftUI
import DesignSystem

/// 单位 / 冰量选择器。
/// 通过绑定输出当前选择的体积单位与冰量档位，配置驱动换算提示文案。
public struct UnitIcePickerView: View {
    @Binding var unit: VolumeUnit
    @Binding var ice: IceLevel
    let config: MixingConfig

    public init(unit: Binding<VolumeUnit>,
                ice: Binding<IceLevel>,
                config: MixingConfig = .default) {
        self._unit = unit
        self._ice = ice
        self.config = config
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            section(title: "单位") {
                segmented(VolumeUnit.allCases, selection: $unit) { $0.displayName }
                Text(unitHint)
                    .font(YunFont.body(12))
                    .foregroundStyle(YunColor.textSecondary)
            }

            section(title: "冰量") {
                segmented(IceLevel.allCases, selection: $ice) { $0.displayName }
                Text(iceHint)
                    .font(YunFont.body(12))
                    .foregroundStyle(YunColor.textSecondary)
            }
        }
        .yunCard()
    }

    // MARK: 子视图

    @ViewBuilder
    private func section<Content: View>(title: String,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(YunFont.serifTitle(16))
                .foregroundStyle(YunColor.textPrimary)
            content()
        }
    }

    private func segmented<T: Identifiable & Equatable>(
        _ items: [T],
        selection: Binding<T>,
        label: @escaping (T) -> String
    ) -> some View {
        HStack(spacing: 8) {
            ForEach(items) { item in
                let selected = selection.wrappedValue == item
                Button {
                    selection.wrappedValue = item
                } label: {
                    Text(label(item))
                        .font(YunFont.body(14))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(selected ? YunColor.ink : YunColor.textPrimary)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(selected ? YunColor.gold : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(YunColor.gold.opacity(selected ? 0 : 0.4),
                                              lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: 提示文案

    private func trimmed(_ v: Double) -> String {
        let s = String(format: "%.1f", v)
        return s.hasSuffix(".0") ? String(s.dropLast(2)) : s
    }

    private var unitHint: String {
        switch unit {
        case .milliliter:  return "以毫升直接计量"
        default:           return "1\(unit.displayName) ≈ \(trimmed(unit.milliliters(per: config)))ml"
        }
    }

    private var iceHint: String {
        let f = ice.dilutionFactor(config)
        if f == 0 { return "无稀释" }
        return "经验估算：约稀释 \(trimmed(f * 100))%（最终度数随之降低）"
    }
}

// MARK: - Preview
//
// 采用 PreviewProvider（而非 #Preview 宏）：两者都能在 Xcode 画布实时预览，
// 但 PreviewProvider 不依赖随完整 Xcode 才提供的宏插件，可在纯命令行工具链下编译。

struct UnitIcePickerView_Previews: PreviewProvider {
    static var previews: some View {
        PickerPreviewHost()
            .padding()
            .background(YunColor.ink)
            .previewDisplayName("单位/冰量选择器")
    }
}

/// Preview / 宿主用的有状态包装。
private struct PickerPreviewHost: View {
    @State private var unit: VolumeUnit = .standardCup
    @State private var ice: IceLevel = .cube

    var body: some View {
        VStack(spacing: 16) {
            UnitIcePickerView(unit: $unit, ice: $ice)
            Text("当前：\(unit.displayName) · \(ice.displayName)")
                .font(YunFont.body(13))
                .foregroundStyle(YunColor.textSecondary)
        }
    }
}
