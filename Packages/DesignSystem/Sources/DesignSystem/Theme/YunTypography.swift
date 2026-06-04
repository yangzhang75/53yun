import SwiftUI

// MARK: - 字体（Typography）
//
// 中文标题：Noto Serif SC（思源宋体）
// 拉丁点缀：Cormorant Garamond
// 正文：系统字体（自动适配动态字号 / 多语言）
//
// 字体文件尚未随包分发时，下列 API 会自动回退到系统衬线体（.serif），保证开箱即用。
// 就位步骤见 DesignSystem/README.md。

public enum YunFontName {
    /// Noto Serif SC 的 PostScript 名（Regular / Bold）
    public static let serifCJK = "NotoSerifSC-Regular"
    public static let serifCJKBold = "NotoSerifSC-Bold"
    /// Cormorant Garamond
    public static let serifLatin = "CormorantGaramond-Medium"
}

public extension Font {

    /// 中文衬线标题（思源宋体），缺字体时回退系统衬线。
    static func yunTitle(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let isBold = [.semibold, .bold, .heavy, .black].contains(weight)
        let name = isBold ? YunFontName.serifCJKBold : YunFontName.serifCJK
        if isFontAvailable(name) {
            return .custom(name, size: size)
        }
        return .system(size: size, weight: weight, design: .serif)
    }

    /// 拉丁点缀（Cormorant Garamond），缺字体时回退系统衬线。
    static func yunSerifLatin(_ size: CGFloat) -> Font {
        if isFontAvailable(YunFontName.serifLatin) {
            return .custom(YunFontName.serifLatin, size: size)
        }
        return .system(size: size, design: .serif)
    }

    /// 正文：系统字体，支持动态字号。
    static func yunBody(_ style: Font.TextStyle = .body) -> Font {
        .system(style)
    }

    private static func isFontAvailable(_ name: String) -> Bool {
        #if canImport(UIKit)
        return UIFont(name: name, size: 12) != nil
        #else
        return false
        #endif
    }
}

#if canImport(UIKit)
import UIKit
#endif
