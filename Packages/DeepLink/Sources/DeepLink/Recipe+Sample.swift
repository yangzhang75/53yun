import Engine

extension Recipe {
    /// 预览用示例配方（仅 DeepLink 模块内部使用）。
    static var sample: Recipe {
        Recipe(
            name: "青城雪顶",
            aroma: .qingxiang,
            components: [
                Component(volumeML: 30, abv: 53),
                Component(volumeML: 90, abv: 0)
            ],
            targetABV: 13.3,
            tastingNote: "初入清冽如雪，尾韵回甘绵长；以清香基酒佐冰饮，烈而不燥。",
            flavor: FlavorProfile(mellow: 0.62, strength: 0.45, crisp: 0.55, sweet: 0.55, complexity: 0.7)
        )
    }
}
