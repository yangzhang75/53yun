import SwiftUI
import Engine
import DesignSystem

// MARK: - 配方详情页
//
// 暗金高端排版：标题 / 风味雷达 / 成分配比 / 品鉴文案 / 一键载入到调制器。
// 「载入」通过 `onLoadIntoMixer` 回调把 Recipe 传出去，由员工①（主工程）负责路由到调制器。

public struct RecipeDetailView: View {
    private let recipe: Recipe
    private let onLoadIntoMixer: ((Recipe) -> Void)?

    public init(recipe: Recipe, onLoadIntoMixer: ((Recipe) -> Void)? = nil) {
        self.recipe = recipe
        self.onLoadIntoMixer = onLoadIntoMixer
    }

    public var body: some View {
        ZStack {
            MistBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: YunMetrics.spacingL) {
                    header
                        .yunEntrance(index: 0)

                    YunCard {
                        VStack(spacing: YunMetrics.spacingS) {
                            sectionTitle("风味雷达")
                            FlavorRadarChart(profile: recipe.flavor)
                                .frame(height: 260)
                        }
                    }
                    .yunEntrance(index: 1)

                    componentsCard
                        .yunEntrance(index: 2)

                    tastingCard
                        .yunEntrance(index: 3)

                    ResponsibleDrinkingBanner()
                        .padding(.top, YunMetrics.spacingS)

                    // 底部留白，避免被悬浮按钮遮挡
                    Color.clear.frame(height: 88)
                }
                .padding(YunMetrics.spacingM)
            }

            // 悬浮的「一键载入」主按钮
            if onLoadIntoMixer != nil {
                VStack {
                    Spacer()
                    loadButton
                        .padding(.horizontal, YunMetrics.spacingM)
                        .padding(.bottom, YunMetrics.spacingS)
                }
            }
        }
        .navigationTitle(recipe.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    // MARK: - 区块

    private var header: some View {
        VStack(alignment: .leading, spacing: YunMetrics.spacingS) {
            HStack(spacing: YunMetrics.spacingS) {
                Image(systemName: recipe.aroma.symbolName)
                    .foregroundStyle(YunColor.goldGradient)
                AromaBadge(aroma: recipe.aroma)
                Spacer()
                YunStat(title: "目标度数", value: abvText(recipe.targetABV), unit: "%vol")
                    .frame(maxWidth: 150)
            }
            Text(recipe.name)
                .font(.yunTitle(34, weight: .semibold))
                .foregroundStyle(YunColor.cream)
            Text(recipe.aroma.tagline)
                .font(.yunSerifLatin(18))
                .foregroundStyle(YunColor.gold)
        }
    }

    private var componentsCard: some View {
        YunCard {
            VStack(alignment: .leading, spacing: YunMetrics.spacingS) {
                sectionTitle("成分配比")
                ForEach(Array(recipe.components.enumerated()), id: \.offset) { _, c in
                    HStack {
                        Text(c.abv > 0 ? "酒体 · \(abvText(c.abv))%vol" : "调和液 · 无醇")
                            .font(.yunBody(.subheadline))
                            .foregroundStyle(YunColor.creamSecondary)
                        Spacer()
                        Text("\(abvText(c.volumeML)) ml")
                            .font(.yunBody(.subheadline))
                            .foregroundStyle(YunColor.cream)
                    }
                    proportionBar(for: c)
                }
                Divider().overlay(YunColor.hairline)
                HStack {
                    Text("合计体积")
                        .font(.yunBody(.subheadline))
                        .foregroundStyle(YunColor.gold)
                    Spacer()
                    Text("\(abvText(totalVolume)) ml")
                        .font(.yunBody(.headline))
                        .foregroundStyle(YunColor.goldBright)
                }
            }
        }
    }

    private func proportionBar(for component: Component) -> some View {
        GeometryReader { geo in
            let frac = totalVolume > 0 ? component.volumeML / totalVolume : 0
            ZStack(alignment: .leading) {
                Capsule().fill(YunColor.ink.opacity(0.6))
                Capsule()
                    .fill(component.abv > 0 ? YunColor.goldGradient
                          : LinearGradient(colors: [YunColor.creamSecondary], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(2, geo.size.width * frac))
            }
        }
        .frame(height: 6)
    }

    private var tastingCard: some View {
        YunCard {
            VStack(alignment: .leading, spacing: YunMetrics.spacingS) {
                sectionTitle("品鉴")
                Text("「\(recipe.tastingNote)」")
                    .font(.yunTitle(18))
                    .foregroundStyle(YunColor.cream)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(4)
            }
        }
    }

    private var loadButton: some View {
        YunButton("一键载入到调制器", icon: "wand.and.stars") {
            onLoadIntoMixer?(recipe)
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.yunBody(.caption))
            .tracking(2)
            .foregroundStyle(YunColor.gold)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 辅助

    private var totalVolume: Double { recipe.components.reduce(0) { $0 + $1.volumeML } }

    private func abvText(_ v: Double) -> String {
        v.rounded() == v ? String(Int(v)) : String(format: "%.1f", v)
    }
}

#Preview("配方详情") {
    NavigationStack {
        RecipeDetailView(recipe: RecipeLibrary.all.first { $0.aroma == .jiangxiang } ?? RecipeLibrary.all[0]) { recipe in
            print("载入到调制器：\(recipe.name)")
        }
    }
    .preferredColorScheme(.dark)
}
