import Foundation
import Engine

/// 预览 / 联调用示例数据。
public enum SampleData {
    /// 固定 id，便于预览与测试稳定。
    public static let previewRecipeID = UUID(uuidString: "5E3F0C0D-0000-4000-8000-000000000053")!

    public static let recipe = Recipe(
        id: previewRecipeID,
        name: "青城雪顶",
        aroma: .qingxiang,
        components: [
            Component(volumeML: 30, abv: 53),
            Component(volumeML: 90, abv: 0)   // 冰 / 调和液
        ],
        targetABV: 13.3,
        tastingNote: "初入清冽如雪，尾韵回甘绵长；以清香基酒佐冰饮，烈而不燥，适宜微醺一刻。",
        flavor: FlavorProfile(mellow: 0.62, strength: 0.45, sweet: 0.55, smooth: 0.78, aroma: 0.7)
    )

    /// 预览用深链字符串（由示例配方编码）。
    public static let previewDeepLink: String = {
        (try? DeepLinkBuilder.customSchemeURL(for: recipe).absoluteString) ?? "yun://recipe"
    }()
}

public extension Recipe {
    /// 预览用配方
    static var preview: Recipe { SampleData.recipe }
}
