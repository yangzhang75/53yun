import SwiftUI

// MARK: - 溯源时间线（酿造 → 封坛 → 出厂）
//
// 暗金高端排版：左侧金色节点 + 连接线，右侧阶段卡片。

public struct TraceTimelineView: View {
    public let steps: [TraceStep]

    public init(steps: [TraceStep]) {
        self.steps = steps
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                row(step: step, isLast: index == steps.count - 1)
            }
        }
    }

    private func row(step: TraceStep, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            // 节点 + 竖线
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(AuthTheme.ink)
                        .frame(width: 16, height: 16)
                    Circle()
                        .strokeBorder(AuthTheme.goldGradient, lineWidth: 1.5)
                        .frame(width: 16, height: 16)
                    Circle()
                        .fill(AuthTheme.gold)
                        .frame(width: 6, height: 6)
                }
                if !isLast {
                    Rectangle()
                        .fill(AuthTheme.goldDim.opacity(0.5))
                        .frame(width: 1)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 16)

            // 阶段内容
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(step.stage)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AuthTheme.gold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .overlay(
                            Capsule().strokeBorder(AuthTheme.goldDim, lineWidth: 0.8)
                        )
                    Text(step.date)
                        .font(.system(size: 12))
                        .foregroundStyle(AuthTheme.textSecondary)
                }
                Text(step.title)
                    .font(AuthTheme.serifTitle(17))
                    .foregroundStyle(AuthTheme.textPrimary)
                Label(step.location, systemImage: "mappin.and.ellipse")
                    .font(.system(size: 12))
                    .foregroundStyle(AuthTheme.textSecondary)
                Text(step.detail)
                    .font(.system(size: 13))
                    .foregroundStyle(AuthTheme.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, isLast ? 0 : 22)
        }
    }
}

#if os(iOS)
#Preview("溯源时间线") {
    ScrollView {
        TraceTimelineView(steps: MockAuthenticityService.jiangxiangSample(code: "YUN2018JX0427A").trace)
            .padding()
    }
    .background(AuthTheme.ink)
}
#endif
