import SwiftUI
import DesignSystem

/// 二维码视图槽位。
///
/// 边界：**本包不生成二维码**。二维码图像由员工⑥(DeepLink) 提供。
/// 用法：员工⑥ 实现一个「接收 URL 字符串、输出二维码视图」的组件，
/// 通过 `TastingCard(..., qrSlot:)` 注入即可填充本槽位；
/// 未注入时显示占位（含将要编码的 URL 字符串，便于联调）。
public struct QRCodeSlot: View {
    /// 将要编码进二维码的 URL 字符串（员工⑥ 用它生成二维码）。
    public let urlString: String
    /// 槽位边长。
    public let side: CGFloat

    public init(urlString: String, side: CGFloat = 72) {
        self.urlString = urlString
        self.side = side
    }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(YunColor.paper.opacity(0.06))
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                .foregroundColor(YunColor.gold.opacity(0.5))
            VStack(spacing: 4) {
                Image(systemName: "qrcode")
                    .font(.system(size: side * 0.34, weight: .light))
                    .foregroundColor(YunColor.gold.opacity(0.7))
                Text("扫码品鉴")
                    .font(.system(size: 9))
                    .foregroundColor(YunColor.paperMuted)
            }
        }
        .frame(width: side, height: side)
        // 供员工⑥ / 自动化测试读取目标 URL
        .accessibilityLabel(Text("二维码占位"))
        .accessibilityValue(Text(urlString))
    }
}

struct QRCodeSlot_Previews: PreviewProvider {
    static var previews: some View {
        QRCodeSlot(urlString: "yun://recipe?c=eyJ4Ijox", side: 96)
            .padding(40)
            .background(YunColor.ink)
            .previewLayout(.sizeThatFits)
            .previewDisplayName("二维码占位槽")
    }
}
