//  GildedQRCodeView.swift
//  DeepLink —— 烫金二维码 SwiftUI 组件（供员工⑤ 品鉴卡嵌入）
//
//  纯展示组件，不依赖 DesignSystem（保持包独立）。字体先用系统衬线（.serif），
//  集成时由员工① 注入「思源宋体」即可（不影响布局）。

import SwiftUI
import CoreGraphics
import Engine

/// 烫金二维码视图：墨黑底 + 烫金细描边 + 衬线说明。可直接嵌入品鉴卡。
public struct GildedQRCodeView: View {

    private let cgImage: CGImage?
    private let caption: String?
    private let side: CGFloat

    /// 用任意字符串（深链）构造。
    public init(content: String, side: CGFloat = 220, caption: String? = nil) {
        self.cgImage = GildedQRCode.cgImage(from: content, size: side * 3)
        self.caption = caption
        self.side = side
    }

    /// 用配方构造（自动生成 Universal Link，离线自包含）。
    public init(recipe: Recipe, side: CGFloat = 220, caption: String? = "扫码还原配方") {
        self.cgImage = GildedQRCode.cgImage(for: recipe, size: side * 3)
        self.caption = caption
        self.side = side
    }

    public var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.black)
                qrLayer
                    .padding(side * 0.10) // 静区（quiet zone），保证可扫
            }
            .frame(width: side, height: side)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Self.goldGradient, lineWidth: 1.5)
            )
            .shadow(color: Self.gold.opacity(0.25), radius: 10, y: 4)

            if let caption {
                Text(caption)
                    .font(.system(.footnote, design: .serif))
                    .tracking(2)
                    .foregroundStyle(Self.gold)
            }
        }
    }

    @ViewBuilder
    private var qrLayer: some View {
        if let cgImage {
            Image(decorative: cgImage, scale: 1.0)
                .resizable()
                .interpolation(.none) // 保持模块锐利，利于扫描
                .scaledToFit()
        } else {
            // 兜底：编码失败时给出可见占位，而不是空白。
            Image(systemName: "qrcode")
                .resizable()
                .scaledToFit()
                .foregroundStyle(Self.gold.opacity(0.4))
                .padding()
        }
    }

    // MARK: 烫金调色
    static let gold = Color(red: 0.831, green: 0.686, blue: 0.216)
    static let goldGradient = LinearGradient(
        colors: [
            Color(red: 0.95, green: 0.86, blue: 0.55),
            gold,
            Color(red: 0.66, green: 0.52, blue: 0.16)
        ],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

#Preview("烫金二维码 · 配方") {
    GildedQRCodeView(recipe: .sample)
        .padding(40)
        .background(Color.black)
}

#Preview("烫金二维码 · 自定义文案") {
    GildedQRCodeView(content: "yun://recipe?c=demo", side: 180, caption: "53° 雲 · 微醺之度")
        .padding(40)
        .background(Color.black)
}
