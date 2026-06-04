//  PreviewSupport.swift
//  预览 / 测试用的内存容器与样例数据。

import Foundation
import SwiftData
import CellarCore

public enum CellarSample {
    public static let recipes: [Recipe] = [
        Recipe(
            name: "清露·八度",
            aroma: .qingxiang,
            components: [Component(volumeML: 500, abv: 0), Component(volumeML: 125, abv: 53)],
            targetABV: 8,
            tastingNote: "清冽回甘，柑橘尾韵，佐餐怡人。",
            flavor: FlavorProfile(mellow: 0.8, strength: 0.3, sweet: 0.6, aroma: 0.7, finish: 0.5)
        ),
        Recipe(
            name: "酱韵·十二",
            aroma: .jiangxiang,
            components: [Component(volumeML: 300, abv: 0), Component(volumeML: 120, abv: 53)],
            targetABV: 12,
            tastingNote: "酱香醇厚，层次绵长。",
            flavor: FlavorProfile(mellow: 0.6, strength: 0.6, sweet: 0.4, aroma: 0.9, finish: 0.8)
        ),
        Recipe(
            name: "浓宴·十五",
            aroma: .nongxiang,
            components: [Component(volumeML: 250, abv: 0), Component(volumeML: 140, abv: 52)],
            targetABV: 15,
            tastingNote: "窖香浓郁，入口饱满。",
            flavor: FlavorProfile(mellow: 0.5, strength: 0.7, sweet: 0.5, aroma: 0.8, finish: 0.7)
        ),
    ]

    /// 构造一个已填充样例数据的内存 Store（供 Preview）
    @MainActor
    public static func makeStore(empty: Bool = false) -> CellarStore {
        // 内存容器：预览不落盘
        let container = try! CellarSchema.makeContainer(inMemory: true)
        let store = CellarStore(context: container.mainContext)
        guard !empty else { return store }

        store.saveRecipe(recipes[0])
        store.saveRecipe(recipes[1], customName: "我的酱香主场")
        store.addSpirit(name: "雲·53° 飞天", abv: 53, stockML: 500, aroma: .jiangxiang)
        store.addSpirit(name: "雲·清香原浆", abv: 52, stockML: 250, aroma: .qingxiang)
        // 多记几笔积分，预览到「白银」等级
        for _ in 0..<5 { store.award(.mix) }
        return store
    }
}
