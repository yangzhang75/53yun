import Testing
@testable import Health

/// Widmark 引擎核心计算测试。
@Suite struct WidmarkCalculatorTests {

    let calc = WidmarkCalculator()

    /// 经典算例校验：70kg 男性，14g 纯酒精 → 峰值约 29.4 mg/100mL。
    @Test func peakIntrinsicKnownValue() {
        let intake = AlcoholIntake(pureAlcoholGrams: 14, drinkingDurationHours: 1)
        let profile = BiometricProfile(weightKilograms: 70, sex: .male)
        let peak = calc.peakIntrinsicMgPer100mL(intake: intake, profile: profile)
        #expect(abs(peak - 29.41) < 0.1)
    }

    /// 无摄入 → 空结果，全 0。
    @Test func noIntakeYieldsEmpty() {
        let intake = AlcoholIntake(pureAlcoholGrams: 0, drinkingDurationHours: 2)
        let est = calc.estimate(intake: intake, profile: .default)
        #expect(est.currentBACMgPer100mL == 0)
        #expect(est.hoursUntilSober == 0)
        #expect(est.level == .sober)
    }

    /// 女性分布系数更小 → 同等摄入下峰值更高。
    @Test func femaleHigherThanMale() {
        let intake = AlcoholIntake(pureAlcoholGrams: 30, drinkingDurationHours: 2)
        let male = calc.peakIntrinsicMgPer100mL(
            intake: intake, profile: BiometricProfile(weightKilograms: 65, sex: .male))
        let female = calc.peakIntrinsicMgPer100mL(
            intake: intake, profile: BiometricProfile(weightKilograms: 65, sex: .female))
        #expect(female > male)
    }

    /// 体重越大 → 峰值越低（合理单调性）。
    @Test func heavierWeightLowerBAC() {
        let intake = AlcoholIntake(pureAlcoholGrams: 40, drinkingDurationHours: 2)
        let light = calc.estimate(intake: intake, profile: BiometricProfile(weightKilograms: 50, sex: .male))
        let heavy = calc.estimate(intake: intake, profile: BiometricProfile(weightKilograms: 90, sex: .male))
        #expect(light.currentBACMgPer100mL > heavy.currentBACMgPer100mL)
    }

    /// 饮用时长越长 → 峰值越低（吸收被拉平）。
    @Test func longerDurationLowerPeak() {
        let profile = BiometricProfile(weightKilograms: 70, sex: .male)
        let fast = calc.estimate(intake: AlcoholIntake(pureAlcoholGrams: 40, drinkingDurationHours: 1),
                                 profile: profile)
        let slow = calc.estimate(intake: AlcoholIntake(pureAlcoholGrams: 40, drinkingDurationHours: 4),
                                 profile: profile)
        #expect(fast.currentBACMgPer100mL > slow.currentBACMgPer100mL)
    }

    /// 摄入越多 → BAC 越高（合理单调性）。
    @Test func moreAlcoholHigherBAC() {
        let profile = BiometricProfile(weightKilograms: 70, sex: .male)
        let few = calc.estimate(intake: AlcoholIntake(pureAlcoholGrams: 20, drinkingDurationHours: 2), profile: profile)
        let many = calc.estimate(intake: AlcoholIntake(pureAlcoholGrams: 80, drinkingDurationHours: 2), profile: profile)
        #expect(many.currentBACMgPer100mL > few.currentBACMgPer100mL)
    }

    /// 清醒时间 = 峰值/消除速率（自第一口起）减去饮用时长。
    @Test func soberTimeMatchesFormula() {
        let intake = AlcoholIntake(pureAlcoholGrams: 30, drinkingDurationHours: 1)
        let profile = BiometricProfile(weightKilograms: 70, sex: .male)
        let est = calc.estimate(intake: intake, profile: profile)
        let peak = calc.peakIntrinsicMgPer100mL(intake: intake, profile: profile)
        let expectedSoberFromNow = peak / 15.0 - 1.0 // 减去饮用时长 1h
        #expect(abs(est.hoursUntilSober - expectedSoberFromNow) < 0.05)
    }

    /// 曲线应单调下降至 0 收尾，且峰值后非增。
    @Test func curveEndsAtZeroAndIsMonotonicAfterPeak() {
        let intake = AlcoholIntake(pureAlcoholGrams: 50, drinkingDurationHours: 2)
        let est = calc.estimate(intake: intake, profile: .default)
        #expect(est.curve.count > 10)
        #expect(abs((est.curve.last?.bacMgPer100mL ?? -1) - 0) < 0.5)

        let maxBAC = est.curve.map(\.bacMgPer100mL).max() ?? 0
        guard let peakIdx = est.curve.firstIndex(where: { $0.bacMgPer100mL == maxBAC }) else {
            Issue.record("无峰值点")
            return
        }
        var monotonic = true
        for i in (peakIdx + 1)..<est.curve.count where est.curve[i].bacMgPer100mL > est.curve[i - 1].bacMgPer100mL + 0.001 {
            monotonic = false
        }
        #expect(monotonic)
    }

    /// BAC 值映射风险等级阈值正确。
    @Test func levelThresholds() {
        #expect(WidmarkCalculator.level(forBAC: 10) == .sober)
        #expect(WidmarkCalculator.level(forBAC: 20) == .driving)
        #expect(WidmarkCalculator.level(forBAC: 79) == .driving)
        #expect(WidmarkCalculator.level(forBAC: 80) == .intoxicated)
    }
}
