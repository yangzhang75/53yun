//
//  RecommendationCardView.swift
//  AICompanion
//
//  推荐卡：香型 + 配比 + 兑法 + 一键载入计算器。
//

import SwiftUI
import AICompanionCore

public struct RecommendationCardView: View {
    public let recommendation: Recommendation
    public let onLoad: () -> Void

    public init(recommendation: Recommendation, onLoad: @escaping () -> Void) {
        self.recommendation = recommendation
        self.onLoad = onLoad
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Divider().overlay(YunInk.gold.opacity(0.25))

            infoRow(label: "香型", value: recommendation.aroma.displayName)
            infoRow(label: "目标", value: "约 \(formatted(recommendation.recipe.targetABV))°")
            infoRow(label: "兑法", value: recommendation.method.displayName)
            infoRow(label: "配比", value: recommendation.ratioSummary)

            if !recommendation.steps.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("调制步骤")
                        .font(.caption).foregroundStyle(YunInk.gold)
                    ForEach(Array(recommendation.steps.enumerated()), id: \.offset) { idx, step in
                        Text("\(idx + 1). \(step)")
                            .font(.footnote)
                            .foregroundStyle(YunInk.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.top, 2)
            }

            loadButton

            Text("请理性饮酒 · 未成年人请勿饮酒")
                .font(.caption2)
                .foregroundStyle(YunInk.textSecondary.opacity(0.7))
        }
        .padding(16)
        .yunGoldCard()
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(recommendation.headline)
                .font(.yunSerifTitle(19))
                .foregroundStyle(YunInk.textPrimary)
            Spacer()
            sourceBadge
        }
    }

    private var sourceBadge: some View {
        Text(recommendation.source.displayName)
            .font(.caption2)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(
                Capsule().fill(
                    recommendation.source == .llm
                        ? YunInk.gold.opacity(0.22)
                        : YunInk.surfaceRaised
                )
            )
            .foregroundStyle(recommendation.source == .llm ? YunInk.goldBright : YunInk.textSecondary)
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(label)
                .font(.footnote)
                .foregroundStyle(YunInk.gold)
                .frame(width: 36, alignment: .leading)
            Text(value)
                .font(.footnote)
                .foregroundStyle(YunInk.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    private var loadButton: some View {
        Button(action: onLoad) {
            HStack(spacing: 6) {
                Image(systemName: "slider.horizontal.below.rectangle")
                Text("一键载入计算器")
                    .font(.subheadline.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(YunInk.gold.opacity(0.18))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(YunInk.gold, lineWidth: 1)
            )
            .foregroundStyle(YunInk.goldBright)
        }
        .buttonStyle(.plain)
        .padding(.top, 2)
    }

    private func formatted(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v)
    }
}

// 使用 PreviewProvider（而非 #Preview 宏），以便在 Xcode 与命令行工具链下均可编译。
struct RecommendationCardView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            YunInk.background.ignoresSafeArea()
            RecommendationCardView(
                recommendation: PreviewFixtures.sample,
                onLoad: {}
            )
            .padding()
        }
        .previewDisplayName("推荐卡")
    }
}
