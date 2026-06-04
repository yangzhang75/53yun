//  ProfileView.swift
//  「我的」个人页：积分、等级、收藏数 + 暗金徽章 + 升级进度。

import SwiftUI
import SwiftData
import CellarCore

public struct ProfileView: View {
    @Environment(CellarStore.self) private var store

    public init() {}

    public var body: some View {
        let progress = store.currentProgress()
        let favorites = store.favoritesCount()

        ScrollView {
            VStack(spacing: 24) {
                // 徽章
                MeritBadgeView(level: progress.level, size: 120)
                    .padding(.top, 12)

                // 升级进度
                progressCard(progress)

                // 三项统计
                HStack(spacing: 12) {
                    statTile(value: "\(progress.points)", label: "微醺积分")
                    statTile(value: progress.level.title, label: "当前等级")
                    statTile(value: "\(favorites)", label: "收藏配方")
                }

                meritHistory()

                Text("请理性饮酒 · 未成年人请勿饮酒")
                    .font(.footnote)
                    .foregroundStyle(YunTheme.textSecondary)
                    .padding(.top, 8)
            }
            .padding(20)
        }
        .background(YunTheme.ink.ignoresSafeArea())
        .navigationTitle("我的")
    }

    @ViewBuilder
    private func progressCard(_ p: MeritProgress) -> some View {
        GoldEdgeCard {
            VStack(alignment: .leading, spacing: 10) {
                if let next = p.next, let need = p.pointsForNext {
                    Text("距「\(next.title)」还差 \(need) 分")
                        .font(YunTheme.serifBody(15))
                        .foregroundStyle(YunTheme.textPrimary)
                } else {
                    Text("已达最高等级 · 典藏")
                        .font(YunTheme.serifBody(15))
                        .foregroundStyle(YunTheme.goldBright)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(YunTheme.hairline)
                        Capsule()
                            .fill(LinearGradient(colors: [YunTheme.gold, YunTheme.goldBright],
                                                 startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(6, geo.size.width * p.fraction))
                    }
                }
                .frame(height: 8)
            }
        }
    }

    private func statTile(value: String, label: String) -> some View {
        GoldEdgeCard {
            VStack(spacing: 6) {
                Text(value)
                    .font(YunTheme.serifTitle(22))
                    .foregroundStyle(YunTheme.goldBright)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(YunTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private func meritHistory() -> some View {
        let records = store.meritRecords().prefix(8)
        if !records.isEmpty {
            GoldEdgeCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("近期积分")
                        .font(YunTheme.serifTitle(17))
                        .foregroundStyle(YunTheme.textPrimary)
                    ForEach(Array(records)) { record in
                        HStack {
                            Text(record.kind.displayName)
                                .foregroundStyle(YunTheme.textPrimary)
                            if !record.note.isEmpty {
                                Text(record.note)
                                    .foregroundStyle(YunTheme.textSecondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Text("+\(record.points)")
                                .foregroundStyle(YunTheme.goldBright)
                        }
                        .font(.subheadline)
                    }
                }
            }
        }
    }
}

#Preview("我的 · 白银") {
    NavigationStack {
        ProfileView()
            .environment(CellarSample.makeStore())
    }
    .preferredColorScheme(.dark)
}

#Preview("我的 · 空") {
    NavigationStack {
        ProfileView()
            .environment(CellarSample.makeStore(empty: true))
    }
    .preferredColorScheme(.dark)
}
