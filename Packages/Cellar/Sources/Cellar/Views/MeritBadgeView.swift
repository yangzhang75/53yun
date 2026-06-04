//  MeritBadgeView.swift
//  暗金会员徽章：墨黑底 + 等级金属色描边 + 衬线等级名。

import SwiftUI
import CellarCore

public struct MeritBadgeView: View {
    public let level: MeritLevel
    public var size: CGFloat = 96

    public init(level: MeritLevel, size: CGFloat = 96) {
        self.level = level
        self.size = size
    }

    private var metal: Color { YunTheme.color(hex: level.badgeHex) }

    public var body: some View {
        ZStack {
            // 暗金放射底
            Circle()
                .fill(
                    RadialGradient(
                        colors: [metal.opacity(0.35), YunTheme.ink],
                        center: .center, startRadius: 2, endRadius: size * 0.6
                    )
                )
            // 双层金属描边
            Circle().strokeBorder(metal.opacity(0.9), lineWidth: 2)
            Circle()
                .inset(by: 6)
                .strokeBorder(metal.opacity(0.4), lineWidth: 1)

            VStack(spacing: 2) {
                Image(systemName: emblem)
                    .font(.system(size: size * 0.26, weight: .light))
                    .foregroundStyle(
                        LinearGradient(colors: [YunTheme.goldBright, metal],
                                       startPoint: .top, endPoint: .bottom)
                    )
                Text(level.title)
                    .font(YunTheme.serifTitle(size * 0.17))
                    .foregroundStyle(YunTheme.textPrimary)
            }
        }
        .frame(width: size, height: size)
        .shadow(color: metal.opacity(0.4), radius: 8, y: 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("会员等级 \(level.title)")
    }

    /// 不同等级用不同纹章
    private var emblem: String {
        switch level {
        case .bronze: return "drop"
        case .silver: return "drop.halffull"
        case .gold: return "crown"
        case .collector: return "seal"
        }
    }
}

#Preview("徽章四级", traits: .sizeThatFitsLayout) {
    HStack(spacing: 16) {
        ForEach(MeritLevel.allCases, id: \.self) { MeritBadgeView(level: $0, size: 88) }
    }
    .padding(24)
    .background(YunTheme.ink)
}
