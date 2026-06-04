import SwiftUI
import Engine
import DesignSystem
import CoreGraphics
import ImageIO

/// 系统分享入口：预览品鉴卡 + 用 `ShareLink` 分享「图片 + 深链」。
///
/// - 渲染高清 PNG 落到临时文件，`ShareLink` 分享该图片文件；
/// - 深链字符串作为 `message` 一并带出（与员工⑥ 对齐的 `yun://` 深链）。
/// - 二维码视图由调用方注入（员工⑥）；未注入时使用内置占位槽。
public struct ShareCardView<QR: View>: View {
    private let recipe: Recipe
    private let style: TastingCardStyle
    private let qrSlot: (String) -> QR

    @State private var exportURL: URL?
    @State private var previewImage: Image?
    @State private var renderError: String?

    public init(
        recipe: Recipe,
        style: TastingCardStyle = .momentsPortrait,
        @ViewBuilder qrSlot: @escaping (String) -> QR
    ) {
        self.recipe = recipe
        self.style = style
        self.qrSlot = qrSlot
    }

    private var deepLink: String {
        (try? DeepLinkBuilder.customSchemeURL(for: recipe).absoluteString) ?? "yun://recipe"
    }

    private var card: TastingCard<QR> {
        TastingCard(recipe: recipe, style: style, deepLink: deepLink, qrSlot: qrSlot)
    }

    public var body: some View {
        VStack(spacing: 20) {
            ScrollView {
                card
                    .padding()
            }

            if let exportURL {
                ShareLink(
                    item: exportURL,
                    subject: Text(recipe.name),
                    message: Text("「\(recipe.name)」品鉴卡 · \(deepLink)"),
                    preview: SharePreview(recipe.name, image: previewImage ?? Image(systemName: "wineglass"))
                ) {
                    Label("分享品鉴卡", systemImage: "square.and.arrow.up")
                        .font(YunFont.serifBody(17))
                        .foregroundColor(YunColor.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(YunColor.goldGradient))
                }
                .padding(.horizontal, 24)
            } else if let renderError {
                Text("生成失败：\(renderError)")
                    .font(.footnote)
                    .foregroundColor(.red)
            } else {
                ProgressView("正在生成品鉴卡…")
                    .tint(YunColor.gold)
            }
        }
        .background(YunColor.inkDeep.ignoresSafeArea())
        .task(id: style) { await render() }
    }

    @MainActor
    private func render() async {
        do {
            let data = try TastingCardRenderer.png(of: card)
            let url = try writeTempPNG(data, name: recipe.name)
            exportURL = url
            if let provider = makePreviewImage(from: data) {
                previewImage = provider
            }
            renderError = nil
        } catch {
            renderError = String(describing: error)
        }
    }

    private func writeTempPNG(_ data: Data, name: String) throws -> URL {
        let safe = name.replacingOccurrences(of: "/", with: "-")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("YunTastingCard-\(safe)")
            .appendingPathExtension("png")
        try data.write(to: url, options: .atomic)
        return url
    }

    private func makePreviewImage(from data: Data) -> Image? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cg = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return nil }
        return Image(decorative: cg, scale: TastingCardRenderer.defaultScale)
    }
}

// MARK: - 便捷初始化：内置占位二维码槽

public extension ShareCardView where QR == QRCodeSlot {
    init(recipe: Recipe, style: TastingCardStyle = .momentsPortrait) {
        self.init(recipe: recipe, style: style) { url in
            QRCodeSlot(urlString: url)
        }
    }
}

struct ShareCardView_Previews: PreviewProvider {
    static var previews: some View {
        ShareCardView(recipe: .preview, style: .momentsPortrait)
            .previewDisplayName("分享面板")
    }
}
