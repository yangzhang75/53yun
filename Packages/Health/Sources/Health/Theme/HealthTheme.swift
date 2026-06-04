import SwiftUI

/// 品牌视觉 token 的**占位实现**（墨黑底 + 烫金描边 + 衬线中文标题）。
///
/// 集成边界：正式版应由 DesignSystem 包提供这些 token，本文件届时整体替换为对 DesignSystem 的引用。
/// 此处自包含，仅为本包可独立预览。
public enum HealthTheme {

    // MARK: - 颜色

    /// 墨黑背景。
    public static let ink = Color(red: 0.043, green: 0.043, blue: 0.051)
    /// 略浅的卡片底色。
    public static let surface = Color(red: 0.094, green: 0.094, blue: 0.110)
    /// 烫金（主强调色）。
    public static let gold = Color(red: 0.784, green: 0.659, blue: 0.420)
    /// 主文字（暖白）。
    public static let textPrimary = Color(red: 0.949, green: 0.937, blue: 0.910)
    /// 次要文字。
    public static let textSecondary = Color(red: 0.659, green: 0.647, blue: 0.620)

    /// 风险等级配色（克制，不刺眼）。
    public static func tint(for level: BACLevel) -> Color {
        switch level {
        case .sober: return gold
        case .driving: return Color(red: 0.847, green: 0.561, blue: 0.286)   // 暖橙
        case .intoxicated: return Color(red: 0.792, green: 0.353, blue: 0.318) // 暗红
        }
    }

    // MARK: - 字体（衬线中文标题，集成时替换为思源宋体）

    public static func serifTitle(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .serif)
    }

    public static func serifLarge() -> Font {
        .system(size: 30, weight: .bold, design: .serif)
    }
}
