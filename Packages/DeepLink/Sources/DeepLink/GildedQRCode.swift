//  GildedQRCode.swift
//  DeepLink —— 烫金风格二维码生成（CoreImage / CIQRCodeGenerator）
//
//  设计调性：墨黑底 + 烫金描边。为保证「能被系统相机扫描」：
//  - 纠错等级用 H（30% 容错），适配桌牌反光 / 局部遮挡 / 印刷误差。
//  - 二维码模块用「亮金」前景、背景透明（clear），由上层 View 叠在墨黑底上，
//    保证前景 / 背景对比度足够（金 vs 黑），扫描稳定。
//  - 不做花哨的中心 logo 挖空，避免破坏可扫性（奢华感交给外框与排版）。
//
//  跨平台：输出 CGImage（CoreImage 跨平台），SwiftUI 用 Image(decorative:scale:)
//  直接吃 CGImage，无需 UIImage —— 因此本文件在 macOS 上也能编译 / 测试。

import CoreImage
import CoreImage.CIFilterBuiltins
import CoreGraphics
import Foundation
import Engine

public enum GildedQRCode {

    /// 烫金配色（sRGB）。默认亮金 #D4AF37 一类的暖金。
    public struct Palette: Sendable {
        public var gold: CIColor       // 前景（模块）
        public var background: CIColor // 背景（默认透明，叠在墨黑底上）
        public init(gold: CIColor, background: CIColor) {
            self.gold = gold
            self.background = background
        }
        public static let gilded = Palette(
            gold: CIColor(red: 0.831, green: 0.686, blue: 0.216), // ~#D4AF37
            background: CIColor(red: 0, green: 0, blue: 0, alpha: 0) // clear
        )
    }

    /// 生成烫金二维码（CGImage）。
    /// - Parameters:
    ///   - string: 要编码的字符串（通常是 yun:// 或 https 深链）。
    ///   - size: 期望输出边长（点）。实际会按整数倍放大以保持锐利。
    ///   - palette: 配色。
    /// - Returns: CGImage；编码失败返回 nil。
    public static func cgImage(
        from string: String,
        size: CGFloat = 512,
        palette: Palette = .gilded
    ) -> CGImage? {
        guard !string.isEmpty,
              let payload = string.data(using: .utf8) else { return nil }

        let qr = CIFilter.qrCodeGenerator()
        qr.message = payload
        qr.correctionLevel = "H" // 最高纠错，最佳可扫性
        guard let base = qr.outputImage else { return nil }

        // 上色：CIFalseColor 把黑(0)映射成背景、白(1)映射成金……
        // CIQRCodeGenerator 输出是「黑模块 / 白底」，所以 color0=金(模块)、color1=背景。
        let colored = base.applyingFilter("CIFalseColor", parameters: [
            "inputColor0": palette.gold,        // 数据模块
            "inputColor1": palette.background   // 空白
        ])

        // 放大到目标尺寸（整数倍 + 最近邻，避免模块边缘模糊影响扫描）。
        let extent = colored.extent
        guard extent.width > 0 else { return nil }
        let scale = max(1, (size / extent.width).rounded())
        let scaled = colored.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        let context = CIContext(options: [.useSoftwareRenderer: false])
        return context.createCGImage(scaled, from: scaled.extent)
    }

    // MARK: 便捷重载

    /// 直接为配方生成 Universal Link 二维码（离线自包含，扫码即还原）。
    public static func cgImage(
        for recipe: Recipe,
        size: CGFloat = 512,
        palette: Palette = .gilded
    ) -> CGImage? {
        guard let url = try? RecipeCodec.universalLinkURL(for: recipe) else { return nil }
        return cgImage(from: url.absoluteString, size: size, palette: palette)
    }
}
