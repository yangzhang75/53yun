//
//  PreviewFixtures.swift
//  AICompanion
//
//  SwiftUI 预览 / 演示用假数据。仅供 #Preview，不参与业务逻辑。
//

import Foundation
import AICompanionCore

enum PreviewFixtures {

    static let sample = Recommendation(
        headline: "酱香低度·加冰",
        aroma: .jiangxiang,
        method: .ice,
        ratioSummary: "约 基酒 1 : 冰/水 5.6（估算，精确值以计算器为准）",
        steps: [
            "取 酱香基酒（约 53°）。",
            "杯中加 2~3 颗大冰球，倒入基酒，静置 30 秒待其降温化开。",
            "目标约 8°，化冰会进一步柔化口感。",
            "点「载入计算器」可由引擎算出精确兑制比例与标准杯数。"
        ],
        rationale: "你点名了酱香，「清爽不上头」→ 降到约 8°，配以加冰，可一键载入计算器精确调制。",
        recipe: Recipe(
            name: "酱香低度·加冰",
            aroma: .jiangxiang,
            components: [Component(volumeML: 100, abv: 53), Component(volumeML: 0, abv: 0)],
            targetABV: 8,
            tastingNote: "酱香幽雅、空杯留香，经兑制后清爽易饮、负担更轻。",
            flavor: FlavorProfile(mellow: 0.82, strength: 0.13)
        ),
        source: .localRules,
        confidence: 0.8
    )

    /// 预填几轮对话的 ViewModel（演示推荐卡）。
    @MainActor
    static func populatedViewModel() -> BartenderViewModel {
        let vm = BartenderViewModel(service: BartenderService())
        vm.useExample("清爽不上头、8 度左右、酱香打底")
        return vm
    }
}
