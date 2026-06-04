import SwiftUI

// MARK: - 暗金高端主题（内置兜底）
//
// 调性：墨黑底 + 烫金描边 + 衬线中文标题 + 克制微动效。
//
// ⚠️ 集成说明（员工① / DesignSystem）：
//   本文件是「兜底主题」，使 Authenticity 包可独立编译与预览。
//   接入 DesignSystem 后，建议将这里的 token 收敛为对 DesignSystem 的转发，
//   全部访问入口集中在 `AuthTheme`，因此切换时不影响各 View。

public enum AuthTheme {

    // MARK: 颜色

    /// 墨黑背景。
    public static let ink = Color(red: 0.043, green: 0.043, blue: 0.055)
    /// 略浅的卡片背景。
    public static let surface = Color(red: 0.094, green: 0.090, blue: 0.106)
    /// 烫金主色。
    public static let gold = Color(red: 0.831, green: 0.686, blue: 0.388)
    /// 高光金（描边/强调）。
    public static let goldBright = Color(red: 0.953, green: 0.831, blue: 0.561)
    /// 暗金（分隔线/次要描边）。
    public static let goldDim = Color(red: 0.451, green: 0.376, blue: 0.224)
    /// 主文字（米白）。
    public static let textPrimary = Color(red: 0.953, green: 0.941, blue: 0.910)
    /// 次要文字。
    public static let textSecondary = Color(red: 0.671, green: 0.651, blue: 0.604)
    /// 成功（验真通过）——克制的青金。
    public static let verified = Color(red: 0.741, green: 0.643, blue: 0.420)
    /// 警示红（仿冒）。
    public static let danger = Color(red: 0.792, green: 0.290, blue: 0.247)
    /// 预警橙（已扫描）。
    public static let warning = Color(red: 0.831, green: 0.580, blue: 0.298)

    // MARK: 金色渐变（描边/分隔）

    public static var goldGradient: LinearGradient {
        LinearGradient(
            colors: [goldBright, gold, goldDim],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: 字体
    //
    // 标题使用衬线（思源宋体 / Source Han Serif）。
    // 包内无法捆绑商用字体，故以系统 `.serif` 衬线兜底；
    // 集成时由 DesignSystem 注册「思源宋体」后替换 fontName 即可。

    /// 中文衬线标题字体名（集成后替换为「思源宋体」实际 PostScript 名）。
    public static let serifFontName: String? = nil

    public static func serifTitle(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        if let name = serifFontName {
            return .custom(name, size: size)
        }
        return .system(size: size, weight: weight, design: .serif)
    }

    // MARK: 间距 / 圆角

    public static let corner: CGFloat = 16
    public static let spacing: CGFloat = 16
}

// MARK: - 复用样式

/// 烫金描边卡片背景。
public struct GoldCardBackground: View {
    public var cornerRadius: CGFloat = AuthTheme.corner
    public init(cornerRadius: CGFloat = AuthTheme.corner) {
        self.cornerRadius = cornerRadius
    }
    public var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(AuthTheme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(AuthTheme.goldGradient, lineWidth: 0.8)
                    .opacity(0.6)
            )
    }
}

extension View {
    /// 套上暗金卡片背景。
    func goldCard(cornerRadius: CGFloat = AuthTheme.corner, padding: CGFloat = AuthTheme.spacing) -> some View {
        self
            .padding(padding)
            .background(GoldCardBackground(cornerRadius: cornerRadius))
    }
}
