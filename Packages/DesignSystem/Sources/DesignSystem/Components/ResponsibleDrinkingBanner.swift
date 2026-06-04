import SwiftUI

// MARK: - 理性饮酒提示（合规红线）
// 全程展示，禁止任何鼓励过量饮酒的措辞。各模块底部统一引用本组件。

public struct ResponsibleDrinkingBanner: View {
    public init() {}

    public var body: some View {
        HStack(spacing: YunMetrics.spacingS) {
            Image(systemName: "exclamationmark.shield")
            Text("请理性饮酒 · 未成年人请勿饮酒")
        }
        .font(.yunBody(.footnote))
        .foregroundStyle(YunColor.creamSecondary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, YunMetrics.spacingS)
        .accessibilityElement(children: .combine)
    }
}

#Preview("ResponsibleDrinking") {
    ZStack {
        MistBackground()
        ResponsibleDrinkingBanner()
    }
}
