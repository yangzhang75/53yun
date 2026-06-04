//  ScanToOrderView.swift
//  DeepLink —— 「扫码点单」展示页（快闪店 / 酒吧桌牌样式）
//
//  场景：把这页投在 iPad / 立牌 / 桌牌上，顾客用手机相机扫码即还原配方。
//  调性：墨黑底 + 烫金 + 衬线标题 + 克制留白。底部固定合规提示（17+ / 理性饮酒）。
//
//  注意：本页只「展示二维码」。扫码后落到顾客自己手机的 App，由那台设备的
//  DeepLinkRouter（员工①）还原配方 —— 桌牌本身不做路由。

import SwiftUI
import Engine

/// 扫码点单桌牌页。
public struct ScanToOrderView: View {

    private let recipe: Recipe
    private let storeName: String

    public init(recipe: Recipe, storeName: String = "53° 雲 · 微醺之度") {
        self.recipe = recipe
        self.storeName = storeName
    }

    public var body: some View {
        GeometryReader { geo in
            let qrSide = min(geo.size.width, geo.size.height) * 0.42

            ZStack {
                background

                VStack(spacing: 0) {
                    // 顶部品牌
                    VStack(spacing: 6) {
                        Text(storeName)
                            .font(.system(.subheadline, design: .serif))
                            .tracking(6)
                            .foregroundStyle(gold)
                        Rectangle()
                            .fill(gold.opacity(0.5))
                            .frame(width: 40, height: 1)
                    }
                    .padding(.top, 40)

                    Spacer(minLength: 16)

                    // 主标题 + 配方名
                    VStack(spacing: 10) {
                        Text("扫码即调")
                            .font(.system(size: 40, weight: .bold, design: .serif))
                            .foregroundStyle(.white)
                        Text(recipe.name)
                            .font(.system(.title3, design: .serif))
                            .foregroundStyle(gold)
                        Text("\(recipe.aroma.displayName) · 目标 \(recipe.targetABV, specifier: "%.1f")%vol")
                            .font(.system(.footnote, design: .serif))
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    Spacer(minLength: 24)

                    // 烫金二维码
                    GildedQRCodeView(recipe: recipe, side: qrSide, caption: nil)

                    Text("用相机对准二维码 · 还原这杯配方")
                        .font(.system(.subheadline, design: .serif))
                        .foregroundStyle(.white.opacity(0.75))
                        .padding(.top, 18)

                    Spacer(minLength: 16)

                    complianceFooter
                        .padding(.bottom, 28)
                }
                .padding(.horizontal, 28)
                .multilineTextAlignment(.center)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: 部件

    private var background: some View {
        ZStack {
            Color.black
            // 极克制的金色径向辉光，奢华但不喧宾夺主。
            RadialGradient(
                colors: [gold.opacity(0.10), .clear],
                center: .center, startRadius: 1, endRadius: 420
            )
        }
    }

    private var complianceFooter: some View {
        VStack(spacing: 4) {
            Text("请理性饮酒 · 未成年人请勿饮酒")
                .font(.system(.caption, design: .serif))
                .foregroundStyle(gold.opacity(0.9))
            Text("本页仅供配方展示，App 内不进行酒类售卖 · 适龄 17+")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.4))
        }
    }

    private let gold = Color(red: 0.831, green: 0.686, blue: 0.216)
}

#Preview("扫码点单 · 桌牌") {
    ScanToOrderView(recipe: .sample)
}
