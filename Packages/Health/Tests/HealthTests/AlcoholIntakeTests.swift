import Testing
@testable import Health

@Suite struct AlcoholIntakeTests {

    /// 标准杯换算：1 杯 = 10g。
    @Test func standardUnitsConversion() {
        let intake = AlcoholIntake(standardUnits: 3, drinkingDurationHours: 2)
        #expect(abs(intake.pureAlcoholGrams - 30) < 0.0001)
        #expect(abs(intake.standardUnits - 3) < 0.0001)
    }

    /// 自定义每杯克数。
    @Test func customGramsPerUnit() {
        let intake = AlcoholIntake(standardUnits: 2, drinkingDurationHours: 1, gramsPerStandardUnit: 12)
        #expect(abs(intake.pureAlcoholGrams - 24) < 0.0001)
    }

    /// 负值被夹断为 0（稳健性）。
    @Test func negativeClampedToZero() {
        let intake = AlcoholIntake(pureAlcoholGrams: -5, drinkingDurationHours: -2)
        #expect(intake.pureAlcoholGrams == 0)
        #expect(intake.drinkingDurationHours == 0)
        #expect(intake.hasIntake == false)
    }

    /// 体重越界夹断。
    @Test func weightClamping() {
        let tooHeavy = BiometricProfile(weightKilograms: 500, sex: .male)
        #expect(tooHeavy.clampedWeightKilograms == BiometricProfile.weightRange.upperBound)
        #expect(tooHeavy.isWeightValid == false)

        let ok = BiometricProfile(weightKilograms: 70, sex: .female)
        #expect(ok.isWeightValid)
    }
}
