import SwiftUI
import Engine
import DesignSystem

// MARK: - 调制台
// App 核心界面：输入基液体积 + 原酒度数 + 目标度数，实时算出需加酒量、混合总量、
// 实际度数与酒精摄入。支持单位换算与加冰稀释；可由配方「一键载入」预填。

public struct MixingCalculatorView: View {

    @State private var juiceText: String
    @State private var unit: VolumeUnit = .milliliter
    @State private var baseABVText: String
    @State private var targetText: String
    @State private var ice: IceLevel = .none

    private let service = MixingService()
    private let loadedName: String?

    /// - Parameter recipe: 若由配方「一键载入」进入，则用其成分预填。
    public init(recipe: Recipe? = nil) {
        if let recipe {
            let juiceML = recipe.components.filter { $0.abv <= 0 }.reduce(0.0) { $0 + $1.volumeML }
            let spiritABV = recipe.components.map(\.abv).max() ?? 53
            _juiceText = State(initialValue: Self.fmt(juiceML > 0 ? juiceML : 90))
            _baseABVText = State(initialValue: Self.fmt(spiritABV > 0 ? spiritABV : 53))
            _targetText = State(initialValue: Self.fmt(recipe.targetABV))
            loadedName = recipe.name
        } else {
            _juiceText = State(initialValue: "500")
            _baseABVText = State(initialValue: "53")
            _targetText = State(initialValue: "8")
            loadedName = nil
        }
    }

    private static func fmt(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v)
    }

    // MARK: - 计算

    private var juice: Double? { Double(juiceText) }
    private var baseABV: Double? { Double(baseABVText) }
    private var target: Double? { Double(targetText) }

    private var errorText: String? {
        guard let v = juice, v >= 0 else { return "请输入有效体积（≥ 0）。" }
        guard let pa = baseABV, pa > 0, pa <= 100 else { return "原酒度数需在 0–100 之间。" }
        guard let pt = target, pt >= 0, pt <= 100 else { return "目标度数需在 0–100 之间。" }
        guard pt < pa else { return "无法达成：目标度数需低于原酒度数。" }
        return nil
    }

    private var outcome: MixingOutcome? {
        guard errorText == nil, let v = juice, let pa = baseABV, let pt = target else { return nil }
        return service.solveAddition(
            base: [(VolumeMeasurement(value: v, unit: unit), 0)],
            spiritABV: pa,
            targetABV: pt,
            ice: ice
        )
    }

    // MARK: - Body

    public var body: some View {
        ZStack {
            MistBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: YunMetrics.spacingM) {
                    header
                    inputCard
                    iceCard
                    resultCard
                    ResponsibleDrinkingBanner()
                        .padding(.top, YunMetrics.spacingS)
                }
                .padding(YunMetrics.spacingM)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("53° 雲 · 调制台")
                .font(.yunBody(.caption)).tracking(2)
                .foregroundStyle(YunColor.gold)
            Text("微醺之度")
                .font(.yunTitle(30, weight: .semibold))
                .foregroundStyle(YunColor.cream)
            if let loadedName {
                Text("已载入配方 · \(loadedName)")
                    .font(.yunBody(.footnote))
                    .foregroundStyle(YunColor.creamSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var inputCard: some View {
        YunCard {
            VStack(alignment: .leading, spacing: YunMetrics.spacingM) {
                field(label: "基液体积（果汁 / 调和液）", text: $juiceText, placeholder: "例如 500")
                Picker("单位", selection: $unit) {
                    ForEach(VolumeUnit.allCases) { u in Text(u.displayName).tag(u) }
                }
                .pickerStyle(.segmented)
                .onChange(of: unit) { oldUnit, newUnit in
                    // 切单位时换算数值，保持真实体积不变（500毫升 → 62.5盖，仍是 500ml）。
                    guard let v = Double(juiceText) else { return }
                    let ml = v * oldUnit.milliliters(per: service.config)
                    let perNew = newUnit.milliliters(per: service.config)
                    if perNew > 0 { juiceText = Self.fmt(ml / perNew) }
                }
                Text("毫升 1 · 标准杯 30 · 分酒器 15 · 盖 8（ml）")
                    .font(.yunBody(.caption))
                    .foregroundStyle(YunColor.creamSecondary)

                field(label: "原酒度数 · %vol", text: $baseABVText, placeholder: "例如 53")
                aromaChips

                field(label: "目标度数 · %vol", text: $targetText, placeholder: "例如 8")
            }
        }
    }

    @ViewBuilder
    private func field(label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: YunMetrics.spacingXS) {
            Text(label)
                .font(.yunBody(.footnote))
                .foregroundStyle(YunColor.creamSecondary)
            TextField(placeholder, text: text)
                #if os(iOS)
                .keyboardType(.decimalPad)
                #endif
                .font(.yunTitle(20, weight: .semibold))
                .foregroundStyle(YunColor.cream)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.25)))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(YunColor.hairline, lineWidth: 1))
        }
    }

    private var aromaChips: some View {
        HStack(spacing: YunMetrics.spacingS) {
            YunChip("清香 53°", isSelected: baseABVText == "53") { baseABVText = "53" }
            YunChip("浓香 52°", isSelected: baseABVText == "52") { baseABVText = "52" }
            YunChip("酱香 53°", isSelected: baseABVText == "53") { baseABVText = "53" }
        }
    }

    private var iceCard: some View {
        YunCard {
            VStack(alignment: .leading, spacing: YunMetrics.spacingS) {
                Text("加冰稀释")
                    .font(.yunBody(.footnote))
                    .foregroundStyle(YunColor.creamSecondary)
                Picker("加冰", selection: $ice) {
                    ForEach(IceLevel.allCases) { lvl in Text(lvl.displayName).tag(lvl) }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var resultCard: some View {
        YunCard {
            VStack(alignment: .leading, spacing: YunMetrics.spacingM) {
                Text("结果")
                    .font(.yunBody(.headline))
                    .foregroundStyle(YunColor.gold)

                if let o = outcome {
                    HStack(alignment: .top, spacing: YunMetrics.spacingS) {
                        YunStat(title: "需加该酒", value: Self.fmt(o.engineResult.addedML), unit: "ml")
                        YunStat(title: "混合总量", value: Self.fmt(o.finalTotalML), unit: "ml")
                        YunStat(title: "实际度数", value: String(format: "%.1f", o.finalABV), unit: "%vol")
                    }
                    Text(o.display.summaryText)
                        .font(.yunBody(.footnote))
                        .foregroundStyle(YunColor.creamSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(errorText ?? "请输入参数。")
                        .font(.yunBody(.callout))
                        .foregroundStyle(YunColor.gold.opacity(0.9))
                }
            }
        }
    }
}

#Preview("调制台") {
    MixingCalculatorView()
        .preferredColorScheme(.dark)
}
