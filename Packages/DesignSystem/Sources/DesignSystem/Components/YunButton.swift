import SwiftUI

// MARK: - YunButton
// 两种样式：primary（烫金填充）/ secondary（金色描边幽灵按钮）。

public struct YunButton: View {
    public enum Style { case primary, secondary }

    private let title: String
    private let icon: String?
    private let style: Style
    private let action: () -> Void

    public init(_ title: String, icon: String? = nil, style: Style = .primary, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: YunMetrics.spacingS) {
                if let icon { Image(systemName: icon) }
                Text(title).font(.yunBody(.headline))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, YunMetrics.spacingL)
        }
        .buttonStyle(YunButtonStyle(style: style))
    }
}

private struct YunButtonStyle: ButtonStyle {
    let style: YunButton.Style

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(foreground)
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: YunMetrics.buttonRadius, style: .continuous)
                    .stroke(YunColor.gold, lineWidth: style == .secondary ? YunMetrics.goldStrokeWidth : 0)
            )
            .clipShape(RoundedRectangle(cornerRadius: YunMetrics.buttonRadius, style: .continuous))
            .opacity(configuration.isPressed ? 0.82 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }

    private var foreground: Color {
        style == .primary ? YunColor.ink : YunColor.goldBright
    }

    @ViewBuilder private var background: some View {
        switch style {
        case .primary: YunColor.goldGradient
        case .secondary: Color.clear
        }
    }
}

#Preview("YunButton") {
    ZStack {
        MistBackground()
        VStack(spacing: 16) {
            YunButton("开始调制", icon: "drop.fill") {}
            YunButton("查看配方", icon: "list.bullet", style: .secondary) {}
        }
        .padding()
    }
}
