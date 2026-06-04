import SwiftUI

// MARK: - 雾气背景层（Mist Background）
// 墨黑底上漂浮的几缕烫金薄雾，使用 Canvas 绘制径向光晕。作为全屏底层。

public struct MistBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let glows: [Glow]

    private struct Glow {
        let unit: CGPoint   // 0~1 相对坐标
        let radius: CGFloat // 相对短边比例
        let opacity: Double
    }

    public init() {
        self.glows = [
            Glow(unit: CGPoint(x: 0.18, y: 0.12), radius: 0.55, opacity: 0.16),
            Glow(unit: CGPoint(x: 0.86, y: 0.30), radius: 0.40, opacity: 0.10),
            Glow(unit: CGPoint(x: 0.50, y: 0.92), radius: 0.62, opacity: 0.12)
        ]
    }

    public var body: some View {
        ZStack {
            YunColor.ink
            Canvas { context, size in
                let minSide = min(size.width, size.height)
                for glow in glows {
                    let center = CGPoint(x: glow.unit.x * size.width,
                                         y: glow.unit.y * size.height)
                    let r = glow.radius * minSide
                    let rect = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
                    let shading = GraphicsContext.Shading.radialGradient(
                        Gradient(colors: [YunColor.gold.opacity(glow.opacity), .clear]),
                        center: center, startRadius: 0, endRadius: r)
                    context.fill(Path(ellipseIn: rect), with: shading)
                }
            }
            .blur(radius: reduceMotion ? 0 : 0.5)
        }
        .ignoresSafeArea()
    }
}

#Preview("Mist") {
    MistBackground()
}
