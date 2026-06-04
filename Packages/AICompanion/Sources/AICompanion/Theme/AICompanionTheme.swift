//
//  AICompanionTheme.swift
//  AICompanion
//
//  本地品牌主题令牌 —— 墨黑底 + 烫金描边 + 衬线中文标题。
//
//  ⚠️ 集成约定：这些令牌镜像 DesignSystem 的设计变量。接入 DesignSystem 后，
//  员工① 可将此处替换为 `import DesignSystem` 并使用其官方 Color / Font，
//  本文件仅用于让 AICompanion 独立预览 / 编译。
//

import SwiftUI

public enum YunInk {
    /// 墨黑底
    public static let background = Color(red: 0.04, green: 0.04, blue: 0.05)
    public static let surface = Color(red: 0.09, green: 0.09, blue: 0.11)
    public static let surfaceRaised = Color(red: 0.13, green: 0.13, blue: 0.15)
    /// 烫金
    public static let gold = Color(red: 0.78, green: 0.65, blue: 0.38)
    public static let goldBright = Color(red: 0.90, green: 0.78, blue: 0.50)
    /// 文本
    public static let textPrimary = Color(red: 0.93, green: 0.92, blue: 0.89)
    public static let textSecondary = Color(red: 0.62, green: 0.61, blue: 0.58)
    public static let userBubble = Color(red: 0.16, green: 0.14, blue: 0.10)
}

public extension Font {
    /// 衬线中文标题（集成时替换为思源宋体）。
    static func yunSerifTitle(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .serif)
    }
}

extension View {
    /// 烫金描边卡片背景。
    func yunGoldCard(cornerRadius: CGFloat = 16) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(YunInk.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(YunInk.gold.opacity(0.45), lineWidth: 0.8)
            )
    }
}
