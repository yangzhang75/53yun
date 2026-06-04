import SwiftUI
import DesignSystem
import Health
import AICompanion
import ShareCard
import DeepLink

// MARK: - 「我的」页
// 主工程页面，聚合未直接占据 Tab 的模块入口（微醺曲线 / AI 调酒师 / 品鉴卡 / 扫码点单）+ 设置区。

struct MeView: View {
    var body: some View {
        // 在 @MainActor 的 body 内构造，调用各模块的 YunModule.rootView()。
        let modules: [(tab: YunTab, view: AnyView)] = [
            (HealthModule.tab, HealthModule.rootView()),
            (AICompanionModule.tab, AICompanionModule.rootView()),
            (ShareCardModule.tab, ShareCardModule.rootView()),
            (DeepLinkModule.tab, DeepLinkModule.rootView())
        ]
        return ZStack {
            MistBackground()
            ScrollView {
                VStack(spacing: YunMetrics.spacingM) {
                    YunCard {
                        VStack(alignment: .leading, spacing: YunMetrics.spacingS) {
                            Text("微醺之度")
                                .font(.yunTitle(24, weight: .semibold))
                                .foregroundStyle(YunColor.cream)
                            Text("53° 雲 · 高度白酒品鉴 / 调制 / 溯源")
                                .font(.yunBody(.footnote))
                                .foregroundStyle(YunColor.creamSecondary)
                        }
                    }
                    .yunEntrance(index: 0)

                    ForEach(Array(modules.enumerated()), id: \.offset) { index, item in
                        NavigationLink {
                            item.view.navigationTitle(item.tab.title)
                        } label: {
                            YunCard {
                                HStack(spacing: YunMetrics.spacingM) {
                                    Image(systemName: item.tab.systemImage)
                                        .font(.title3)
                                        .foregroundStyle(YunColor.goldGradient)
                                        .frame(width: 28)
                                    Text(item.tab.title)
                                        .font(.yunBody(.headline))
                                        .foregroundStyle(YunColor.cream)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(YunColor.creamSecondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .yunEntrance(index: index + 1)
                    }

                    NavigationLink {
                        AboutView()
                    } label: {
                        YunCard {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundStyle(YunColor.goldGradient).frame(width: 28)
                                Text("关于与合规").font(.yunBody(.headline)).foregroundStyle(YunColor.cream)
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(YunColor.creamSecondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .yunEntrance(index: modules.count + 1)

                    ResponsibleDrinkingBanner()
                }
                .padding(YunMetrics.spacingM)
            }
        }
        .navigationTitle("我的")
    }
}

private struct AboutView: View {
    var body: some View {
        ZStack {
            MistBackground()
            VStack(spacing: YunMetrics.spacingM) {
                YunCard {
                    VStack(alignment: .leading, spacing: YunMetrics.spacingS) {
                        Text("合规说明").font(.yunBody(.headline)).foregroundStyle(YunColor.goldBright)
                        Text("· 适用年龄 17+，启动需年龄确认。\n· 全程倡导理性饮酒，未成年人请勿饮酒。\n· 本应用不在站内完成酒类售卖交易。\n· 健康/AI 相关数据默认本地处理，上传将在隐私清单声明。")
                            .font(.yunBody(.callout)).foregroundStyle(YunColor.cream)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer()
                ResponsibleDrinkingBanner()
            }
            .padding(YunMetrics.spacingM)
        }
        .navigationTitle("关于与合规")
    }
}

#Preview("Me") {
    NavigationStack { MeView() }
}
