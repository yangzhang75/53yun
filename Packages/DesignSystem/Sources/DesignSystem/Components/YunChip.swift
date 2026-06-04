import SwiftUI

// MARK: - YunChip
// 胶囊标签 / 可选筹码。selected 时金色填充。

public struct YunChip: View {
    private let title: String
    private let isSelected: Bool
    private let action: (() -> Void)?

    public init(_ title: String, isSelected: Bool = false, action: (() -> Void)? = nil) {
        self.title = title
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        let label = Text(title)
            .font(.yunBody(.subheadline))
            .foregroundStyle(isSelected ? YunColor.ink : YunColor.cream)
            .padding(.vertical, 6)
            .padding(.horizontal, 14)
            .background(
                Capsule().fill(isSelected ? YunColor.gold : YunColor.card)
            )
            .overlay(
                Capsule().stroke(YunColor.hairline, lineWidth: isSelected ? 0 : YunMetrics.hairlineWidth)
            )

        if let action {
            Button(action: action) { label }
                .buttonStyle(.plain)
        } else {
            label
        }
    }
}

#Preview("YunChip") {
    ZStack {
        MistBackground()
        HStack {
            YunChip("清香", isSelected: true) {}
            YunChip("酱香") {}
            YunChip("浓香") {}
        }
        .padding()
    }
}
