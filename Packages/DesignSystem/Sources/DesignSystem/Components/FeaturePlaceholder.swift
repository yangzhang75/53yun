import SwiftUI

// MARK: - 功能占位页（Feature Placeholder）
// 各功能包尚未交付前，统一使用本占位页，保证主工程入口可进入、风格一致。
// 各位同事接手后，把自己的真实根视图替换进 `rootView()` 即可。

public struct FeaturePlaceholder: View {
    private let title: String
    private let systemImage: String
    private let owner: String
    private let summary: String

    public init(title: String, systemImage: String, owner: String, summary: String) {
        self.title = title
        self.systemImage = systemImage
        self.owner = owner
        self.summary = summary
    }

    public var body: some View {
        ZStack {
            MistBackground()
            VStack(spacing: YunMetrics.spacingL) {
                Spacer()
                Image(systemName: systemImage)
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(YunColor.goldGradient)
                    .yunEntrance(index: 0)
                VStack(spacing: YunMetrics.spacingS) {
                    Text(title)
                        .font(.yunTitle(28, weight: .semibold))
                        .foregroundStyle(YunColor.cream)
                    Text(summary)
                        .font(.yunBody(.callout))
                        .foregroundStyle(YunColor.creamSecondary)
                        .multilineTextAlignment(.center)
                }
                .yunEntrance(index: 1)

                YunChip("即将上线 · \(owner)")
                    .yunEntrance(index: 2)
                Spacer()
                ResponsibleDrinkingBanner()
            }
            .padding(YunMetrics.spacingL)
        }
    }
}

#Preview("FeaturePlaceholder") {
    FeaturePlaceholder(title: "度数调制",
                       systemImage: "drop.fill",
                       owner: "员工③",
                       summary: "单位换算 · 冰融 · 酒精单位，敬请期待。")
}
