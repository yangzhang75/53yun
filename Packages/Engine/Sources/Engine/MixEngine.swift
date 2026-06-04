import Foundation

/// 调制计算引擎：App 的「数学心脏」。
///
/// 纯逻辑、无状态、线程安全。所有公开方法均返回 `Result<MixResult, MixError>`，
/// 调用方据此区分成功值与可读错误。引擎不做任何四舍五入，精度由 UI 层决定。
public enum MixEngine {

    // MARK: - 三向自由解算

    /// 按 `SolveMode` 解算一次「果汁 + 原酒」调制。
    public static func solve(_ mode: SolveMode) -> Result<MixResult, MixError> {
        switch mode {
        case let .addedVolume(juiceML, baseABV, targetABV):
            return solveAddedVolume(juiceML: juiceML, baseABV: baseABV, targetABV: targetABV)
        case let .finalABV(juiceML, addedML, baseABV):
            return solveFinalABV(juiceML: juiceML, addedML: addedML, baseABV: baseABV)
        case let .requiredBaseABV(juiceML, addedML, targetABV):
            return solveRequiredBaseABV(juiceML: juiceML, addedML: addedML, targetABV: targetABV)
        }
    }

    /// 已知 Vj + Pa + Pt → 解加酒量 Va = (Pt × Vj) / (Pa − Pt)。
    private static func solveAddedVolume(juiceML: Double,
                                         baseABV: Double,
                                         targetABV: Double) -> Result<MixResult, MixError> {
        if let e = validateVolume(juiceML, label: "果汁体积") { return .failure(e) }
        if let e = validateABV(baseABV) { return .failure(e) }
        if let e = validateABV(targetABV) { return .failure(e) }

        // 目标为 0：无需加酒，结果即纯果汁。
        if targetABV == 0 {
            return .success(makeResult(addedML: 0, juiceML: juiceML, actualABV: 0))
        }
        // 加酒只能把度数拉向 Pa；若 Pa ≤ Pt 则永远无法到达目标。
        guard baseABV > targetABV else {
            return .failure(.targetUnreachable(target: targetABV, baseABV: baseABV))
        }

        let addedML = (targetABV * juiceML) / (baseABV - targetABV)
        // 实际度数按定义重算，避免浮点累积误差并自洽。
        let actualABV = computeABV(addedML: addedML, baseABV: baseABV, totalML: addedML + juiceML)
        return .success(makeResult(addedML: addedML, juiceML: juiceML, actualABV: actualABV))
    }

    /// 已知 Vj + Va + Pa → 解最终度数 Pt = (Va × Pa) / (Va + Vj)。
    private static func solveFinalABV(juiceML: Double,
                                      addedML: Double,
                                      baseABV: Double) -> Result<MixResult, MixError> {
        if let e = validateVolume(juiceML, label: "果汁体积") { return .failure(e) }
        if let e = validateVolume(addedML, label: "加酒量") { return .failure(e) }
        if let e = validateABV(baseABV) { return .failure(e) }

        let totalML = addedML + juiceML
        guard totalML > 0 else { return .failure(.zeroTotalVolume) }

        let actualABV = computeABV(addedML: addedML, baseABV: baseABV, totalML: totalML)
        return .success(makeResult(addedML: addedML, juiceML: juiceML, actualABV: actualABV))
    }

    /// 已知 Vj + Va + Pt → 反解所需原酒度数 Pa = Pt × (Va + Vj) / Va。
    private static func solveRequiredBaseABV(juiceML: Double,
                                             addedML: Double,
                                             targetABV: Double) -> Result<MixResult, MixError> {
        if let e = validateVolume(juiceML, label: "果汁体积") { return .failure(e) }
        if let e = validateVolume(addedML, label: "加酒量") { return .failure(e) }
        if let e = validateABV(targetABV) { return .failure(e) }

        // 目标为 0：所需原酒度数为 0（任意度数加 0 体积也可，这里取 0 自洽）。
        if targetABV == 0 {
            return .success(makeResult(addedML: addedML, juiceML: juiceML, actualABV: 0))
        }
        // 无酒可加却要求 >0 的目标 → 不可达。
        guard addedML > 0 else {
            return .failure(.targetUnreachable(target: targetABV, baseABV: 0))
        }

        let requiredBaseABV = targetABV * (addedML + juiceML) / addedML
        // 原酒度数物理上不可能超过 100%。
        guard requiredBaseABV <= EngineConstants.abvRange.upperBound else {
            return .failure(.targetUnreachable(target: targetABV, baseABV: requiredBaseABV))
        }
        // 成品实际度数即目标度数。
        return .success(makeResult(addedML: addedML, juiceML: juiceML, actualABV: targetABV))
    }

    // MARK: - 多组分混调

    /// 多组分混调：输入多种组分，输出总体积、加权总度数及酒精量。
    /// 加权度数 = Σ(体积 × 度数) / Σ体积。
    public static func mix(_ components: [Component]) -> Result<MixResult, MixError> {
        guard !components.isEmpty else { return .failure(.emptyComponents) }

        var totalML = 0.0
        var alcoholVolumeML = 0.0   // 纯酒精体积合计 = Σ(vol × abv/100)
        var addedML = 0.0           // 含酒组分体积合计

        for c in components {
            if let e = validateVolume(c.volumeML, label: "组分「\(c.name.isEmpty ? "未命名" : c.name)」体积") {
                return .failure(e)
            }
            if let e = validateABV(c.abv) { return .failure(e) }

            totalML += c.volumeML
            alcoholVolumeML += c.volumeML * c.abv / 100.0
            if c.abv > 0 { addedML += c.volumeML }
        }

        guard totalML > 0 else { return .failure(.zeroTotalVolume) }

        let actualABV = alcoholVolumeML / totalML * 100.0
        let alcoholGrams = alcoholVolumeML * EngineConstants.ethanolDensityGramsPerML
        return .success(MixResult(addedML: addedML,
                                  totalML: totalML,
                                  actualABV: actualABV,
                                  alcoholGrams: alcoholGrams,
                                  standardUnits: alcoholGrams / EngineConstants.gramsPerStandardUnit))
    }

    // MARK: - 私有辅助

    /// 由（加酒量、原酒度数、总体积）计算成品度数。
    private static func computeABV(addedML: Double, baseABV: Double, totalML: Double) -> Double {
        guard totalML > 0 else { return 0 }
        return (addedML * baseABV) / totalML
    }

    /// 统一构造结果：基于成品度数与总体积，换算纯酒精克数与标准单位。
    private static func makeResult(addedML: Double, juiceML: Double, actualABV: Double) -> MixResult {
        let totalML = addedML + juiceML
        let alcoholVolumeML = totalML * actualABV / 100.0
        let alcoholGrams = alcoholVolumeML * EngineConstants.ethanolDensityGramsPerML
        return MixResult(addedML: addedML,
                         totalML: totalML,
                         actualABV: actualABV,
                         alcoholGrams: alcoholGrams,
                         standardUnits: alcoholGrams / EngineConstants.gramsPerStandardUnit)
    }

    /// 校验体积：必须为有限且非负的数值。
    private static func validateVolume(_ value: Double, label: String) -> MixError? {
        guard value.isFinite else { return .invalidInput("\(label) 不是有效数值。") }
        guard value >= 0 else { return .invalidInput("\(label) 不能为负数（\(String(format: "%g", value))）。") }
        return nil
    }

    /// 校验酒精度：必须为有限数值且落在 0~100。
    private static func validateABV(_ value: Double) -> MixError? {
        guard value.isFinite else { return .invalidInput("酒精度不是有效数值。") }
        guard EngineConstants.abvRange.contains(value) else { return .abvOutOfRange(value: value) }
        return nil
    }
}
