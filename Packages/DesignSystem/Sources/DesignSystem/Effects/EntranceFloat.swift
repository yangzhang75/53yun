import SwiftUI

// MARK: - 入场上浮动效（克制微动效）
// 元素出现时轻微上浮 + 渐显。尊重「降低动态效果」无障碍设置：开启时直接显示、无位移。

private struct EntranceFloatModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let delay: Double
    let distance: CGFloat
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : (reduceMotion ? 0 : distance))
            .onAppear {
                guard !shown else { return }
                if reduceMotion {
                    shown = true
                } else {
                    withAnimation(.easeOut(duration: 0.5).delay(delay)) {
                        shown = true
                    }
                }
            }
    }
}

public extension View {
    /// 入场上浮渐显。`index` 用于做依次错峰（每个 0.06s）。
    func yunEntrance(index: Int = 0, distance: CGFloat = 14) -> some View {
        modifier(EntranceFloatModifier(delay: Double(index) * 0.06, distance: distance))
    }
}
