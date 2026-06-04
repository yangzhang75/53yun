//  CellarTheme_Standin.swift
//
//  ⚠️ 临时占位 —— 集成时删除本文件 ⚠️
//
//  设计系统（颜色 / 字体 / 组件）归属 DesignSystem 包（员工①）。
//  本包独立开发时 DesignSystem 尚未落地，这里内联一份「墨黑底 + 烫金描边 + 衬线宋体标题」
//  的最小令牌，仅为让本包能独立编译 / 预览。
//
//  集成步骤（员工①）：删除本文件 → 为 Cellar target 添加 DesignSystem 依赖 →
//  将下列 `YunTheme.*` 替换为 DesignSystem 暴露的同名令牌。

import SwiftUI

/// 雲 · 视觉令牌（占位）
public enum YunTheme {
    // 颜色
    public static let ink = Color(red: 0.04, green: 0.04, blue: 0.05)        // 墨黑底
    public static let inkRaised = Color(red: 0.09, green: 0.09, blue: 0.11)  // 卡片底
    public static let gold = Color(red: 0.79, green: 0.63, blue: 0.29)       // 烫金 #C9A24B
    public static let goldBright = Color(red: 0.91, green: 0.78, blue: 0.45) // 亮金
    public static let textPrimary = Color(red: 0.94, green: 0.92, blue: 0.88)
    public static let textSecondary = Color(red: 0.62, green: 0.60, blue: 0.56)
    public static let hairline = Color.white.opacity(0.10)

    /// 衬线中文标题（思源宋体；占位用系统 serif 兜底）
    public static func serifTitle(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .serif)
    }

    public static func serifBody(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .serif)
    }

    /// 由十六进制构造颜色（积分等级徽章取色用）
    public static func color(hex: UInt32) -> Color {
        Color(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

/// 烫金描边卡片容器
public struct GoldEdgeCard<Content: View>: View {
    private let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }

    public var body: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(YunTheme.inkRaised)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [YunTheme.gold.opacity(0.7), YunTheme.gold.opacity(0.2)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}
