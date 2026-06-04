import SwiftUI
import DesignSystem

// MARK: - 年龄确认门（合规红线）
// 首次启动弹出，未确认年满 18 不可进入。确认后 AppStorage 记忆，不再弹出。

struct AgeGateView: View {
    @Binding var ageVerified: Bool
    @State private var declined = false

    var body: some View {
        ZStack {
            MistBackground()
            VStack(spacing: YunMetrics.spacingL) {
                Spacer()

                Text("微醺之度")
                    .font(.yunTitle(40, weight: .semibold))
                    .foregroundStyle(YunColor.goldGradient)
                    .yunEntrance(index: 0)

                Text("53° 雲 · YÚN")
                    .font(.yunSerifLatin(20))
                    .foregroundStyle(YunColor.creamSecondary)
                    .yunEntrance(index: 1)

                YunCard {
                    VStack(alignment: .leading, spacing: YunMetrics.spacingM) {
                        Label("年龄确认", systemImage: "checkmark.shield")
                            .font(.yunBody(.headline))
                            .foregroundStyle(YunColor.goldBright)
                        Text("本应用含频繁、强烈的酒精相关内容，适用年龄 17+。\n请确认您已年满 18 周岁，方可进入。")
                            .font(.yunBody(.callout))
                            .foregroundStyle(YunColor.cream)
                            .fixedSize(horizontal: false, vertical: true)

                        if declined {
                            Text("根据相关规定，未满 18 周岁无法使用本应用。")
                                .font(.yunBody(.footnote))
                                .foregroundStyle(.red.opacity(0.9))
                                .transition(.opacity)
                        }
                    }
                }
                .yunEntrance(index: 2)

                VStack(spacing: YunMetrics.spacingS) {
                    YunButton("我已年满 18 周岁，进入") {
                        ageVerified = true
                    }
                    YunButton("我未满 18 周岁", style: .secondary) {
                        withAnimation { declined = true }
                    }
                }
                .yunEntrance(index: 3)

                Spacer()
                ResponsibleDrinkingBanner()
            }
            .padding(YunMetrics.spacingL)
        }
        .interactiveDismissDisabled(true) // 不可下滑关闭，必须明确确认
    }
}

#Preview("AgeGate") {
    AgeGateView(ageVerified: .constant(false))
}
