import SwiftUI

/// 微醺曲线模块主界面（员工⑦ 对外暴露的核心 View）。
///
/// 组成：免责声明 → 当前状态 → BAC 衰减曲线 → 关键指标（清醒时间等）→ 温柔提示 → 一键代驾。
/// 全程墨黑底 + 烫金点缀；全程显著免责声明。
public struct BACDashboardView: View {

    @State private var viewModel: BACViewModel
    @Environment(\.openURL) private var openURL

    /// 是否提供 HealthKit 体重导入入口（默认仅 iOS 提供）。
    private let allowsHealthImport: Bool

    /// 主初始化器。
    /// - Parameters:
    ///   - viewModel: 预置的视图模型（通常由 App 层用 Engine `MixResult` 构造）。
    ///   - allowsHealthImport: 是否显示「从健康读取体重」。
    public init(viewModel: BACViewModel,
                allowsHealthImport: Bool = BACDashboardView.defaultAllowsHealthImport) {
        _viewModel = State(initialValue: viewModel)
        self.allowsHealthImport = allowsHealthImport
    }

    /// 便捷初始化器：直接传入纯酒精克数（来自 Engine MixResult）。
    public init(pureAlcoholGrams: Double,
                drinkingDurationHours: Double = 1.0,
                profile: BiometricProfile = .default,
                weightProvider: BodyWeightProviding = ManualWeightProvider(),
                allowsHealthImport: Bool = BACDashboardView.defaultAllowsHealthImport) {
        let vm = BACViewModel(pureAlcoholGrams: pureAlcoholGrams,
                              drinkingDurationHours: drinkingDurationHours,
                              profile: profile,
                              weightProvider: weightProvider)
        _viewModel = State(initialValue: vm)
        self.allowsHealthImport = allowsHealthImport
    }

    public static var defaultAllowsHealthImport: Bool {
        #if os(iOS)
        return true
        #else
        return false
        #endif
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                DisclaimerBanner()
                statusCard
                chartCard
                metricsRow
                inputCard
                tipsCard
                driverCard
                footerNote
            }
            .padding(20)
        }
        .background(HealthTheme.ink.ignoresSafeArea())
        .tint(HealthTheme.gold)
    }

    // MARK: - 区块

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("微醺之度")
                .font(HealthTheme.serifLarge())
                .foregroundStyle(HealthTheme.textPrimary)
            Text("BAC 微醺曲线 · 健康估算")
                .font(.subheadline)
                .foregroundStyle(HealthTheme.textSecondary)
        }
    }

    private var statusCard: some View {
        let level = viewModel.estimate.level
        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(viewModel.currentBACText)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(HealthTheme.tint(for: level))
                Text("mg/100mL")
                    .font(.subheadline)
                    .foregroundStyle(HealthTheme.textSecondary)
                Spacer()
                Text(level.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(HealthTheme.tint(for: level))
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Capsule().fill(HealthTheme.tint(for: level).opacity(0.15)))
            }
            Text(viewModel.headline)
                .font(.footnote)
                .foregroundStyle(HealthTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardBackground())
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("BAC 随时间衰减")
            BACCurveChart(estimate: viewModel.estimate,
                          nowHour: viewModel.drinkingDurationHours)
        }
        .modifier(CardBackground())
    }

    private var metricsRow: some View {
        HStack(spacing: 12) {
            metricTile(title: "预计清醒", value: viewModel.soberCountdownText, system: "moon.zzz")
            metricTile(title: "低于驾车阈值", value: viewModel.legalDrivingCountdownText, system: "car")
        }
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("调整输入")
            BACInputView(viewModel: viewModel, allowsHealthImport: allowsHealthImport)
            Text("折算约 \(viewModel.standardUnitsText) 标准杯 · 纯酒精量由调制引擎提供")
                .font(.caption2)
                .foregroundStyle(HealthTheme.textSecondary)
        }
        .modifier(CardBackground())
    }

    private var tipsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("适饮节奏 · 温柔提示")
            ForEach(viewModel.tips) { tip in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(tone(tip.tone))
                        .frame(width: 7, height: 7)
                        .padding(.top, 6)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tip.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(HealthTheme.textPrimary)
                        Text(tip.message)
                            .font(.footnote)
                            .foregroundStyle(HealthTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardBackground())
    }

    private var driverCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("一键叫代驾")
            ForEach(viewModel.driverService.options) { option in
                Button {
                    if let url = option.deepLink { openURL(url) }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(option.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(HealthTheme.ink)
                            Text(option.subtitle)
                                .font(.caption2)
                                .foregroundStyle(HealthTheme.ink.opacity(0.7))
                        }
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .foregroundStyle(HealthTheme.ink)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 12).fill(HealthTheme.gold))
                }
                .buttonStyle(.plain)
            }
            Text(DesignatedDriverService.fallbackHint)
                .font(.caption2)
                .foregroundStyle(HealthTheme.textSecondary)
        }
        .modifier(CardBackground())
    }

    private var footerNote: some View {
        Text(HealthDisclaimer.neverDriveDrunk + " " + HealthDisclaimer.privacy)
            .font(.caption2)
            .foregroundStyle(HealthTheme.textSecondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 4)
    }

    // MARK: - 小组件

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(HealthTheme.serifTitle(18))
            .foregroundStyle(HealthTheme.textPrimary)
    }

    private func metricTile(title: String, value: String, system: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: system)
                .font(.caption)
                .foregroundStyle(HealthTheme.textSecondary)
            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundStyle(HealthTheme.gold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardBackground())
    }

    private func tone(_ tone: PaceTip.Tone) -> Color {
        switch tone {
        case .calm: return HealthTheme.gold
        case .caution: return HealthTheme.tint(for: .driving)
        case .strong: return HealthTheme.tint(for: .intoxicated)
        }
    }
}

/// 统一的卡片背景修饰。
private struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(HealthTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(HealthTheme.gold.opacity(0.18), lineWidth: 1)
                    )
            )
    }
}

// MARK: - Previews

#if DEBUG
struct BACDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            BACDashboardView(pureAlcoholGrams: 40, drinkingDurationHours: 2,
                             profile: .default, allowsHealthImport: false)
                .previewDisplayName("微醺曲线 · 4 标准杯")

            BACDashboardView(pureAlcoholGrams: 12, drinkingDurationHours: 1.5,
                             profile: BiometricProfile(weightKilograms: 60, sex: .female),
                             allowsHealthImport: false)
                .previewDisplayName("少量 · 接近清醒")
        }
    }
}
#endif
