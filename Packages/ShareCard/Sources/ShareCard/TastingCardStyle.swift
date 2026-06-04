import SwiftUI
import DesignSystem

/// 卡片比例。
public enum CardRatio: String, CaseIterable, Sendable, Identifiable {
    /// 朋友圈竖图 9:16
    case portrait
    /// 方图 1:1
    case square

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .portrait: return "朋友圈竖图"
        case .square:   return "方图"
        }
    }

    /// 设计基准尺寸（pt）。导出时按 scale 放大为高清 PNG。
    public var baseSize: CGSize {
        switch self {
        case .portrait: return CGSize(width: 360, height: 640) // 9:16
        case .square:   return CGSize(width: 480, height: 480) // 1:1
        }
    }

    public var aspectRatio: CGFloat { baseSize.width / baseSize.height }
}

/// 卡片底纹（背景纹理）。多套可选。
public enum CardTexture: String, CaseIterable, Sendable, Identifiable {
    /// 纯墨黑渐变
    case inkGradient
    /// 烫金细密斜纹
    case goldPinstripe
    /// 中央径向柔光
    case spotlight
    /// 鎏金水波纹
    case goldRipple

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .inkGradient:   return "墨黑渐变"
        case .goldPinstripe: return "烫金斜纹"
        case .spotlight:     return "中央柔光"
        case .goldRipple:    return "鎏金水波"
        }
    }

    /// 底纹视图（铺满卡片）。
    @ViewBuilder
    public func background(in size: CGSize) -> some View {
        switch self {
        case .inkGradient:
            LinearGradient(
                colors: [YunColor.ink, YunColor.ink],
                startPoint: .top, endPoint: .bottom
            )

        case .goldPinstripe:
            ZStack {
                YunColor.ink
                Canvas { ctx, canvasSize in
                    let gap: CGFloat = 14
                    var x: CGFloat = -canvasSize.height
                    while x < canvasSize.width {
                        var path = Path()
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x + canvasSize.height, y: canvasSize.height))
                        ctx.stroke(path, with: .color(YunColor.gold.opacity(0.06)), lineWidth: 1)
                        x += gap
                    }
                }
            }

        case .spotlight:
            ZStack {
                YunColor.ink
                RadialGradient(
                    colors: [YunColor.gold.opacity(0.18), .clear],
                    center: .init(x: 0.5, y: 0.38),
                    startRadius: 0,
                    endRadius: max(size.width, size.height) * 0.7
                )
            }

        case .goldRipple:
            ZStack {
                LinearGradient(colors: [YunColor.ink, YunColor.ink],
                               startPoint: .top, endPoint: .bottom)
                Canvas { ctx, canvasSize in
                    let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height * 0.42)
                    var r: CGFloat = 20
                    while r < max(canvasSize.width, canvasSize.height) {
                        let rect = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
                        ctx.stroke(Path(ellipseIn: rect),
                                   with: .color(YunColor.gold.opacity(0.05)),
                                   lineWidth: 1)
                        r += 26
                    }
                }
            }
        }
    }
}

/// 卡片样式组合：比例 + 底纹。
public struct TastingCardStyle: Sendable, Equatable {
    public var ratio: CardRatio
    public var texture: CardTexture

    public init(ratio: CardRatio = .portrait, texture: CardTexture = .spotlight) {
        self.ratio = ratio
        self.texture = texture
    }

    /// 朋友圈竖图默认款
    public static let momentsPortrait = TastingCardStyle(ratio: .portrait, texture: .spotlight)
    /// 方图默认款
    public static let square = TastingCardStyle(ratio: .square, texture: .goldRipple)
}
