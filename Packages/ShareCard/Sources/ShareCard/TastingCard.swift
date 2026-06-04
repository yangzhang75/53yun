import SwiftUI
import Engine
import DesignSystem

/// 品鉴卡：把配方/结果渲染成一张精致竖版/方版卡片。
///
/// 含：品牌 logo、香型、配比、度数、品鉴语、风味、二维码槽位、烫金边框。
/// 泛型 `QR` 为二维码视图槽位 —— 由员工⑥ 注入；缺省使用 `QRCodeSlot` 占位。
public struct TastingCard<QR: View>: View {
    private let recipe: Recipe
    private let style: TastingCardStyle
    /// 深链 URL 字符串（编码了配方），传给二维码槽位。
    private let deepLink: String
    private let qrSlot: (String) -> QR

    public init(
        recipe: Recipe,
        style: TastingCardStyle = .momentsPortrait,
        deepLink: String,
        @ViewBuilder qrSlot: @escaping (String) -> QR
    ) {
        self.recipe = recipe
        self.style = style
        self.deepLink = deepLink
        self.qrSlot = qrSlot
    }

    public var body: some View {
        let size = style.ratio.baseSize
        let pad = size.width * 0.07

        ZStack {
            style.texture.background(in: size)

            VStack(alignment: .leading, spacing: 0) {
                header
                Spacer(minLength: size.height * 0.02)
                titleBlock
                Spacer(minLength: size.height * 0.025)
                paramsBlock
                Spacer(minLength: size.height * 0.02)
                if style.ratio == .portrait {
                    flavorBlock
                    Spacer(minLength: size.height * 0.02)
                    tastingNote
                }
                Spacer(minLength: 0)
                footer
            }
            .padding(pad)
        }
        .frame(width: size.width, height: size.height)
        .background(YunColor.inkDeep)
        .overlay(goldBorder)
        .clipShape(RoundedRectangle(cornerRadius: size.width * 0.045))
    }

    // MARK: - 品牌 logo / 页眉

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("53° 雲")
                    .font(YunFont.serifTitle(style.ratio.baseSize.width * 0.075))
                    .foregroundStyle(YunColor.goldGradient)
                Text("YÚN · 微醺之度")
                    .font(.system(size: style.ratio.baseSize.width * 0.026, weight: .light))
                    .tracking(2)
                    .foregroundColor(YunColor.paperMuted)
            }
            Spacer()
            aromaBadge
        }
    }

    private var aromaBadge: some View {
        Text(recipe.aroma.displayName)
            .font(YunFont.serifBody(style.ratio.baseSize.width * 0.038))
            .foregroundColor(YunColor.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(YunColor.goldGradient))
    }

    // MARK: - 标题

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(recipe.name)
                .font(YunFont.serifTitle(style.ratio.baseSize.width * 0.10))
                .foregroundColor(YunColor.paper)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
            Rectangle()
                .fill(YunColor.goldGradient)
                .frame(width: style.ratio.baseSize.width * 0.16, height: 2)
        }
    }

    // MARK: - 关键参数（度数 / 香型 / 配比）

    private var paramsBlock: some View {
        VStack(alignment: .leading, spacing: style.ratio.baseSize.height * 0.018) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(String(format: "%.1f", recipe.targetABV))
                    .font(YunFont.mono(style.ratio.baseSize.width * 0.13))
                    .foregroundStyle(YunColor.goldGradient)
                Text("%vol")
                    .font(.system(size: style.ratio.baseSize.width * 0.035, weight: .light))
                    .foregroundColor(YunColor.paperMuted)
                Spacer()
                Text("目标度数")
                    .font(YunFont.serifBody(style.ratio.baseSize.width * 0.032))
                    .foregroundColor(YunColor.paperMuted)
            }

            ratioRow
        }
    }

    /// 配比行：列出各成分体积 + 度数。
    private var ratioRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("配比")
                .font(YunFont.serifBody(style.ratio.baseSize.width * 0.030))
                .foregroundColor(YunColor.gold)
            ForEach(Array(recipe.components.enumerated()), id: \.offset) { _, c in
                HStack {
                    Text(String(format: "%.0f ml", c.volumeML))
                        .font(YunFont.mono(style.ratio.baseSize.width * 0.034))
                        .foregroundColor(YunColor.paper)
                    Spacer()
                    Text(String(format: "%.0f%%vol", c.abv))
                        .font(YunFont.mono(style.ratio.baseSize.width * 0.030))
                        .foregroundColor(YunColor.paperMuted)
                }
            }
        }
    }

    // MARK: - 风味迷你条

    private var flavorBlock: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(flavorDimensions, id: \.0) { name, value in
                HStack(spacing: 8) {
                    Text(name)
                        .font(YunFont.serifBody(style.ratio.baseSize.width * 0.030))
                        .foregroundColor(YunColor.paperMuted)
                        .frame(width: style.ratio.baseSize.width * 0.10, alignment: .leading)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(YunColor.paper.opacity(0.08))
                            Capsule()
                                .fill(YunColor.goldGradient)
                                .frame(width: geo.size.width * max(0, min(1, value)))
                        }
                    }
                    .frame(height: 5)
                }
            }
        }
    }

    private var flavorDimensions: [(String, Double)] {
        [("醇厚", recipe.flavor.mellow),
         ("烈度", recipe.flavor.strength),
         ("回甘", recipe.flavor.sweet),
         ("绵柔", recipe.flavor.smooth),
         ("香气", recipe.flavor.aroma)]
    }

    // MARK: - 品鉴语

    private var tastingNote: some View {
        Text(recipe.tastingNote)
            .font(YunFont.serifBody(style.ratio.baseSize.width * 0.034))
            .foregroundColor(YunColor.paper.opacity(0.85))
            .lineSpacing(4)
            .lineLimit(3)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - 页脚：二维码槽位 + 合规提示

    private var footer: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("请理性饮酒 · 未成年人请勿饮酒")
                    .font(.system(size: style.ratio.baseSize.width * 0.026, weight: .regular))
                    .foregroundColor(YunColor.paperMuted)
                Text("扫码还原本配方")
                    .font(YunFont.serifBody(style.ratio.baseSize.width * 0.028))
                    .foregroundColor(YunColor.gold)
            }
            Spacer()
            // 二维码槽位（员工⑥ 填充）
            qrSlot(deepLink)
                .frame(width: style.ratio.baseSize.width * 0.22,
                       height: style.ratio.baseSize.width * 0.22)
        }
    }

    // MARK: - 烫金边框

    private var goldBorder: some View {
        RoundedRectangle(cornerRadius: style.ratio.baseSize.width * 0.045)
            .strokeBorder(YunColor.goldGradient, lineWidth: 2)
            .padding(style.ratio.baseSize.width * 0.018)
            .overlay(
                RoundedRectangle(cornerRadius: style.ratio.baseSize.width * 0.045)
                    .strokeBorder(YunColor.gold.opacity(0.25), lineWidth: 1)
            )
    }
}

// MARK: - 便捷初始化：使用内置占位二维码槽

public extension TastingCard where QR == QRCodeSlot {
    /// 使用内置 `QRCodeSlot` 占位（联调期 / 员工⑥ 尚未接入时）。
    init(recipe: Recipe,
         style: TastingCardStyle = .momentsPortrait,
         deepLink: String) {
        self.init(recipe: recipe, style: style, deepLink: deepLink) { url in
            QRCodeSlot(urlString: url)
        }
    }
}

// MARK: - Preview
// 说明：使用 PreviewProvider（而非 #Preview 宏）以兼容命令行 Swift 工具链构建；
// Xcode 画布同样支持，可实时预览各比例 / 底纹。

struct TastingCard_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TastingCard(recipe: .preview,
                        style: .momentsPortrait,
                        deepLink: SampleData.previewDeepLink)
                .previewDisplayName("竖版 · 中央柔光")

            TastingCard(recipe: .preview,
                        style: .square,
                        deepLink: SampleData.previewDeepLink)
                .previewDisplayName("方图 · 鎏金水波")

            TastingCard(recipe: .preview,
                        style: TastingCardStyle(ratio: .portrait, texture: .goldPinstripe),
                        deepLink: SampleData.previewDeepLink)
                .previewDisplayName("竖版 · 烫金斜纹")
        }
        .previewLayout(.sizeThatFits)
        .padding()
        .background(YunColor.ink)
    }
}
