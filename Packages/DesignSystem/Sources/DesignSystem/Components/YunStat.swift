import SwiftUI

// MARK: - YunStat
// 数值展示卡：小标题 + 大数值 + 单位。用于结果区（如需添加量 / 总量 / 实际度数）。

public struct YunStat: View {
    private let title: String
    private let value: String
    private let unit: String?

    public init(title: String, value: String, unit: String? = nil) {
        self.title = title
        self.value = value
        self.unit = unit
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: YunMetrics.spacingXS) {
            Text(title)
                .font(.yunBody(.caption))
                .foregroundStyle(YunColor.creamSecondary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.yunTitle(28, weight: .semibold))
                    .foregroundStyle(YunColor.goldBright)
                    .contentTransition(.numericText())
                if let unit {
                    Text(unit)
                        .font(.yunBody(.footnote))
                        .foregroundStyle(YunColor.creamSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(YunMetrics.spacingM)
        .background(
            RoundedRectangle(cornerRadius: YunMetrics.buttonRadius, style: .continuous)
                .fill(YunColor.ink.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: YunMetrics.buttonRadius, style: .continuous)
                .stroke(YunColor.hairline, lineWidth: YunMetrics.hairlineWidth)
        )
    }
}

#Preview("YunStat") {
    ZStack {
        MistBackground()
        HStack(spacing: 12) {
            YunStat(title: "需添加该酒", value: "125.0", unit: "ml")
            YunStat(title: "实际度数", value: "8.00", unit: "%vol")
        }
        .padding()
    }
}
