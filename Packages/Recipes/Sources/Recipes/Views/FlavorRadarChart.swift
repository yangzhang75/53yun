import SwiftUI
import Engine
import DesignSystem

// MARK: - 风味雷达图（五维 · 暗金描边）
//
// 用 Canvas 绘制蛛网网格（同心五边形 + 辐条），数据多边形用 `Animatable` 的 Shape 叠加，
// 随配方变化并带入场动效（从圆心向外展开）。尊重「降低动态效果」无障碍设置。

public struct FlavorRadarChart: View {
    private let profile: FlavorProfile
    private let rings: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress: CGFloat = 0

    /// - Parameters:
    ///   - profile: 配方风味画像（各维 0~1）。
    ///   - rings: 同心网格圈数（默认 4）。
    public init(profile: FlavorProfile, rings: Int = 4) {
        self.profile = profile
        self.rings = max(1, rings)
    }

    private var values: [Double] { profile.axisValues }
    private var axes: [FlavorAxis] { FlavorAxis.allCases }

    public var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            // 给顶点文字留白，半径取可用空间的 ~0.34。
            let radius = side * 0.34
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)

            ZStack {
                // 1) 网格：同心五边形 + 辐条（静态底图）
                Canvas { ctx, _ in
                    drawGrid(in: &ctx, center: center, radius: radius)
                }

                // 2) 数据多边形（填充 + 描边），随 progress 从圆心展开
                RadarPolygon(values: values, center: center, radius: radius, progress: progress)
                    .fill(YunColor.gold.opacity(0.22))
                RadarPolygon(values: values, center: center, radius: radius, progress: progress)
                    .stroke(YunColor.goldGradient, lineWidth: YunMetrics.goldStrokeWidth + 0.4)

                // 3) 顶点圆点
                ForEach(axes) { axis in
                    let v = values[axis.rawValue] * Double(progress)
                    let p = vertex(axis.rawValue, radius: radius * CGFloat(v), center: center)
                    Circle()
                        .fill(YunColor.goldBright)
                        .frame(width: 5, height: 5)
                        .position(p)
                        .opacity(Double(progress))
                }

                // 4) 顶点标签（中文衬线，外圈定位）
                ForEach(axes) { axis in
                    let labelPoint = vertex(axis.rawValue, radius: radius + 22, center: center)
                    VStack(spacing: 1) {
                        Text(axis.displayName)
                            .font(.yunBody(.caption))
                            .foregroundStyle(YunColor.cream)
                        Text(percentText(values[axis.rawValue]))
                            .font(.yunBody(.caption2))
                            .foregroundStyle(YunColor.creamSecondary)
                    }
                    .position(labelPoint)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("风味雷达图")
        .accessibilityValue(accessibilitySummary)
        .onAppear { animateIn() }
        // 配方切换时重新播放入场动效
        .onChange(of: profile) { _, _ in
            progress = 0
            animateIn()
        }
    }

    // MARK: - 绘制

    /// 顶点坐标：第 0 维在正上方，顺时针分布。
    private func vertex(_ index: Int, radius r: CGFloat, center: CGPoint) -> CGPoint {
        let count = max(1, values.count)
        let angle = -CGFloat.pi / 2 + CGFloat(index) * (2 * .pi / CGFloat(count))
        return CGPoint(x: center.x + r * cos(angle), y: center.y + r * sin(angle))
    }

    private func drawGrid(in ctx: inout GraphicsContext, center: CGPoint, radius: CGFloat) {
        let count = values.count
        // 同心五边形
        for ring in 1...rings {
            let r = radius * CGFloat(ring) / CGFloat(rings)
            var path = Path()
            for i in 0..<count {
                let p = vertex(i, radius: r, center: center)
                if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
            }
            path.closeSubpath()
            ctx.stroke(path, with: .color(YunColor.hairline),
                       lineWidth: ring == rings ? YunMetrics.hairlineWidth + 0.2 : YunMetrics.hairlineWidth * 0.7)
        }
        // 辐条
        for i in 0..<count {
            var spoke = Path()
            spoke.move(to: center)
            spoke.addLine(to: vertex(i, radius: radius, center: center))
            ctx.stroke(spoke, with: .color(YunColor.hairline.opacity(0.7)), lineWidth: 0.6)
        }
    }

    // MARK: - 动效 & 辅助

    private func animateIn() {
        if reduceMotion {
            progress = 1
        } else {
            withAnimation(.easeOut(duration: 0.7)) { progress = 1 }
        }
    }

    private func percentText(_ v: Double) -> String {
        "\(Int((min(1, max(0, v)) * 100).rounded()))"
    }

    private var accessibilitySummary: String {
        axes.map { "\($0.displayName) \(percentText(values[$0.rawValue]))%" }
            .joined(separator: "，")
    }
}

// MARK: - 数据多边形（可动画 Shape）

/// 五维数据多边形。`progress` 作为 animatableData，使顶点从圆心平滑展开到目标位置。
private struct RadarPolygon: Shape {
    var values: [Double]
    var center: CGPoint
    var radius: CGFloat
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let count = max(1, values.count)
        for i in 0..<values.count {
            let v = min(1, max(0, values[i])) * Double(progress)
            let angle = -CGFloat.pi / 2 + CGFloat(i) * (2 * .pi / CGFloat(count))
            let r = radius * CGFloat(v)
            let point = CGPoint(x: center.x + r * cos(angle), y: center.y + r * sin(angle))
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

#Preview("风味雷达 · 酱韵纯饮") {
    ZStack {
        MistBackground()
        FlavorRadarChart(
            profile: FlavorProfile(mellow: 0.90, strength: 0.95, crisp: 0.35, sweet: 0.40, complexity: 0.92)
        )
        .padding(40)
    }
}
