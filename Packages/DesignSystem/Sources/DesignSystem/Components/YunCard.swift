import SwiftUI

// MARK: - YunCard
// 卡片容器：深色卡底 + 烫金细描边，承载内容区块。

public struct YunCard<Content: View>: View {
    private let padding: CGFloat
    private let content: Content

    public init(padding: CGFloat = YunMetrics.spacingM, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    public var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: YunMetrics.cardRadius, style: .continuous)
                    .fill(YunColor.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: YunMetrics.cardRadius, style: .continuous)
                    .stroke(YunColor.hairline, lineWidth: YunMetrics.hairlineWidth)
            )
    }
}

#Preview("YunCard") {
    ZStack {
        MistBackground()
        YunCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("雲·清香")
                    .font(.yunTitle(22, weight: .semibold))
                    .foregroundStyle(YunColor.cream)
                Text("清雅净爽，回甘悠长。")
                    .font(.yunBody())
                    .foregroundStyle(YunColor.creamSecondary)
            }
        }
        .padding()
    }
}
