import SwiftUI
import Engine
import ImageIO
import CoreGraphics
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

/// 把品鉴卡渲染并导出为高清 PNG。
///
/// 使用 SwiftUI `ImageRenderer` 离屏渲染，取 `cgImage` 后经 ImageIO 编码为 PNG，
/// 全程不依赖 UIKit，便于跨平台与单元测试。
@MainActor
public enum TastingCardRenderer {

    /// 渲染倍率（默认 3x，导出 App Store 级清晰度）。
    public nonisolated static let defaultScale: CGFloat = 3

    public enum RenderError: Error {
        case cgImageUnavailable
        case pngEncodingFailed
    }

    /// 渲染任意 SwiftUI 视图为 PNG `Data`。
    public static func png<V: View>(of view: V, scale: CGFloat = defaultScale) throws -> Data {
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale
        renderer.isOpaque = true
        guard let cgImage = renderer.cgImage else {
            throw RenderError.cgImageUnavailable
        }
        return try pngData(from: cgImage)
    }

    /// 便捷：直接渲染某配方的品鉴卡（使用内置占位二维码槽）。
    /// 注入员工⑥ 的二维码视图时，请改用 `png(of:)` 传入自定义 `TastingCard`。
    public static func png(
        recipe: Recipe,
        style: TastingCardStyle = .momentsPortrait,
        deepLink: String,
        scale: CGFloat = defaultScale
    ) throws -> Data {
        let card = TastingCard(recipe: recipe, style: style, deepLink: deepLink)
        return try png(of: card, scale: scale)
    }

    // MARK: - PNG 编码（ImageIO，跨平台）

    static func pngData(from cgImage: CGImage) throws -> Data {
        let data = NSMutableData()
        let type: CFString
        #if canImport(UniformTypeIdentifiers)
        type = UTType.png.identifier as CFString
        #else
        type = "public.png" as CFString
        #endif
        guard let dest = CGImageDestinationCreateWithData(data as CFMutableData, type, 1, nil) else {
            throw RenderError.pngEncodingFailed
        }
        CGImageDestinationAddImage(dest, cgImage, nil)
        guard CGImageDestinationFinalize(dest) else {
            throw RenderError.pngEncodingFailed
        }
        return data as Data
    }
}
