import SwiftUI

// MARK: - 颜色令牌（Color Tokens）
// 墨黑底 + 烫金描边 的奢华克制调性。全 App 只用这里的语义色，禁止散落硬编码 hex。

public extension Color {
    /// 用 16 进制创建颜色，支持 "#RRGGBB" / "RRGGBB" / "#RRGGBBAA"
    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        var value: UInt64 = 0
        Scanner(string: s).scanHexInt64(&value)

        let r, g, b, a: Double
        switch s.count {
        case 8: // RRGGBBAA
            r = Double((value & 0xFF00_0000) >> 24) / 255
            g = Double((value & 0x00FF_0000) >> 16) / 255
            b = Double((value & 0x0000_FF00) >> 8) / 255
            a = Double(value & 0x0000_00FF) / 255
        default: // RRGGBB
            r = Double((value & 0xFF0000) >> 16) / 255
            g = Double((value & 0x00FF00) >> 8) / 255
            b = Double(value & 0x0000FF) / 255
            a = 1
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

/// 雲 设计系统语义色板
public enum YunColor {
    /// 墨黑底 #0A0A0C
    public static let ink = Color(hex: "#0A0A0C")
    /// 卡片底 #16161A
    public static let card = Color(hex: "#16161A")
    /// 烫金描边 #C4A463
    public static let gold = Color(hex: "#C4A463")
    /// 亮金（高光/强调）#E8D9A8
    public static let goldBright = Color(hex: "#E8D9A8")
    /// 米白正文 #EFEAE0
    public static let cream = Color(hex: "#EFEAE0")

    /// 次级文字（米白降透明度）
    public static let creamSecondary = Color(hex: "#EFEAE0").opacity(0.62)
    /// 极弱分隔线 / 描边底色
    public static let hairline = Color(hex: "#C4A463").opacity(0.22)

    /// 烫金渐变（用于描边与高光）
    public static let goldGradient = LinearGradient(
        colors: [goldBright, gold, gold.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
