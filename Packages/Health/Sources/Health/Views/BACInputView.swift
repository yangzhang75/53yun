import SwiftUI

/// 输入面板：体重 / 性别 / 饮用时长（+ 可选 HealthKit 导入体重）。
struct BACInputView: View {

    @Bindable var viewModel: BACViewModel
    /// 是否提供 HealthKit 导入按钮（由上层根据平台/集成情况决定）。
    var allowsHealthImport: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            sexPicker
            weightSlider
            durationSlider
        }
    }

    private var sexPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("性别（用于体液分布系数）")
            Picker("性别", selection: $viewModel.sex) {
                ForEach(BiologicalSex.allCases) { sex in
                    Text(sex.displayName).tag(sex)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var weightSlider: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                fieldLabel("体重")
                Spacer()
                Text("\(Int(viewModel.weightKilograms)) kg")
                    .font(.headline)
                    .foregroundStyle(HealthTheme.gold)
                if viewModel.weightFromHealthKit {
                    Text("来自健康")
                        .font(.caption2)
                        .foregroundStyle(HealthTheme.textSecondary)
                }
            }
            Slider(value: $viewModel.weightKilograms,
                   in: BiometricProfile.weightRange,
                   step: 1)
            .tint(HealthTheme.gold)

            if allowsHealthImport {
                Button {
                    Task { await viewModel.importWeightFromHealth() }
                } label: {
                    Label("从「健康」读取体重", systemImage: "heart.text.square")
                        .font(.caption)
                }
                .tint(HealthTheme.gold)
            }
        }
    }

    private var durationSlider: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                fieldLabel("饮用时长")
                Spacer()
                Text(durationLabel)
                    .font(.headline)
                    .foregroundStyle(HealthTheme.gold)
            }
            Slider(value: $viewModel.drinkingDurationHours,
                   in: 0.5...8,
                   step: 0.5)
            .tint(HealthTheme.gold)
        }
    }

    private var durationLabel: String {
        let h = viewModel.drinkingDurationHours
        if h < 1 { return "\(Int(h * 60)) 分钟" }
        return h.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(h)) 小时"
            : String(format: "%.1f 小时", h)
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(HealthTheme.textSecondary)
    }
}
