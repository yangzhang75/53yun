import SwiftUI
import Engine
import DesignSystem

// MARK: - 配方列表行（暗金卡片）
// 香型图标 + 名称（衬线）+ 一句品鉴文案 + 目标度数徽标。

struct RecipeRowView: View {
    let recipe: Recipe

    var body: some View {
        YunCard {
            HStack(alignment: .top, spacing: YunMetrics.spacingM) {
                Image(systemName: recipe.aroma.symbolName)
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(YunColor.goldGradient)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: YunMetrics.spacingXS) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(recipe.name)
                            .font(.yunTitle(20, weight: .semibold))
                            .foregroundStyle(YunColor.cream)
                        Spacer(minLength: YunMetrics.spacingS)
                        AromaBadge(aroma: recipe.aroma)
                    }
                    Text(recipe.tastingNote)
                        .font(.yunBody(.subheadline))
                        .foregroundStyle(YunColor.creamSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: YunMetrics.spacingS) {
                        Label("\(abvText(recipe.targetABV))%vol", systemImage: "drop.fill")
                        Text("·")
                        Text("\(recipe.components.count) 种成分")
                    }
                    .font(.yunBody(.caption))
                    .foregroundStyle(YunColor.gold)
                    .padding(.top, 2)
                }
            }
        }
        .contentShape(Rectangle())
    }

    private func abvText(_ v: Double) -> String {
        v.rounded() == v ? String(Int(v)) : String(format: "%.1f", v)
    }
}

// MARK: - 香型徽标

struct AromaBadge: View {
    let aroma: AromaType

    var body: some View {
        Text(aroma.displayName)
            .font(.yunBody(.caption2))
            .foregroundStyle(YunColor.goldBright)
            .padding(.vertical, 3)
            .padding(.horizontal, 8)
            .overlay(
                Capsule().stroke(YunColor.hairline, lineWidth: YunMetrics.hairlineWidth)
            )
    }
}

#Preview("RecipeRow") {
    ZStack {
        MistBackground()
        VStack(spacing: 12) {
            ForEach(Array(RecipeLibrary.all.prefix(3))) { RecipeRowView(recipe: $0) }
        }
        .padding()
    }
}
