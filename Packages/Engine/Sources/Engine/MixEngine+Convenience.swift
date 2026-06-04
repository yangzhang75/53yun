import Foundation

// MARK: - 便捷别名 / 包装（追加式，不改动既有 API）

public extension MixResult {
    /// 兼容别名：混合后实际度数（等同 `actualABV`）。
    var finalABV: Double { actualABV }
}

public extension MixEngine {

    /// 多组分混合的非抛出便捷版：失败时返回零值结果。
    static func combine(_ components: [Component]) -> MixResult {
        switch mix(components) {
        case .success(let result):
            return result
        case .failure:
            return MixResult(addedML: 0, totalML: 0, actualABV: 0, alcoholGrams: 0, standardUnits: 0)
        }
    }

    /// 调兑：在给定基底上加入某酒体（`spiritABV`），使成品达到 `targetABV`。
    /// 解出需加入的酒体体积后，复用 `combine` 统一计算总量 / 度数 / 酒精量。
    static func solveAddition(base: [Component],
                              spiritABV: Double,
                              targetABV: Double) -> MixResult {
        let baseML = base.reduce(0) { $0 + $1.volumeML }
        let baseAlcoholML = base.reduce(0) { $0 + $1.volumeML * $1.abv / 100 }
        let baseABV = baseML > 0 ? baseAlcoholML / baseML * 100 : 0
        let denominator = spiritABV - targetABV
        let addedML = denominator > 0
            ? max(0, baseML * (targetABV - baseABV) / denominator)
            : 0
        return combine(base + [Component(volumeML: addedML, abv: spiritABV)])
    }
}
