import Testing
@testable import Health

@Suite struct DrinkingPaceAdvisorTests {

    let advisor = DrinkingPaceAdvisor()
    let calc = WidmarkCalculator()

    private func estimate(grams: Double, hours: Double = 1) -> BACEstimate {
        calc.estimate(intake: AlcoholIntake(pureAlcoholGrams: grams, drinkingDurationHours: hours),
                      profile: BiometricProfile(weightKilograms: 70, sex: .male))
    }

    /// 任何状态都至少给出一条提示，且始终包含通用关怀「节奏小贴士」。
    @Test func alwaysIncludesGeneralTip() {
        for grams in [0.0, 15, 40, 120] {
            let tips = advisor.tips(for: estimate(grams: grams))
            #expect(!tips.isEmpty)
            #expect(tips.contains { $0.id == "hydrate" })
        }
    }

    /// 进入驾车区间时，提示「请勿驾车」。
    @Test func drivingLevelWarnsNoDrive() {
        let est = estimate(grams: 30, hours: 1)
        #expect(est.level == .driving)
        let tips = advisor.tips(for: est)
        #expect(tips.contains { $0.id == "no-drive" })
        #expect(tips.contains { $0.tone == .caution })
    }

    /// 醉酒区间使用强提醒语气，并建议停杯。
    @Test func intoxicatedLevelStrongTone() {
        let est = estimate(grams: 100, hours: 1)
        #expect(est.level == .intoxicated)
        let tips = advisor.tips(for: est)
        #expect(tips.contains { $0.tone == .strong })
        #expect(tips.contains { $0.id == "stop" })
    }

    /// headline 永远非空。
    @Test func headlineNotEmpty() {
        #expect(!advisor.headline(for: estimate(grams: 0)).isEmpty)
        #expect(!advisor.headline(for: estimate(grams: 50)).isEmpty)
    }
}
