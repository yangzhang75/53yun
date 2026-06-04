import Testing
@testable import Health

@MainActor
@Suite struct BACViewModelTests {

    /// 修改输入后派生状态自动重算。
    @Test func recomputeOnInputChange() {
        let vm = BACViewModel(pureAlcoholGrams: 0, drinkingDurationHours: 1)
        #expect(vm.estimate.currentBACMgPer100mL == 0)

        vm.pureAlcoholGrams = 40
        #expect(vm.estimate.currentBACMgPer100mL > 0)
        #expect(!vm.tips.isEmpty)
        #expect(!vm.headline.isEmpty)
    }

    /// 体重变化影响估算。
    @Test func weightAffectsEstimate() {
        let vm = BACViewModel(pureAlcoholGrams: 40, drinkingDurationHours: 2)
        vm.weightKilograms = 50
        let light = vm.estimate.currentBACMgPer100mL
        vm.weightKilograms = 95
        let heavy = vm.estimate.currentBACMgPer100mL
        #expect(light > heavy)
    }

    /// 时长文案格式化。
    @Test func durationTextFormatting() {
        #expect(BACViewModel.durationText(hours: 0, zeroText: "已清醒") == "已清醒")
        #expect(BACViewModel.durationText(hours: 0.5, zeroText: "x") == "约 30 分钟")
        #expect(BACViewModel.durationText(hours: 2, zeroText: "x") == "约 2 小时")
        #expect(BACViewModel.durationText(hours: 2.5, zeroText: "x") == "约 2 小时 30 分")
    }

    /// 标准杯展示。
    @Test func standardUnitsText() {
        let vm = BACViewModel(pureAlcoholGrams: 30, drinkingDurationHours: 1)
        #expect(vm.standardUnitsText == "3.0")
    }

    /// HealthKit 导入：注入假体重源，验证体重被写入并标注来源。
    @Test func importWeightFromHealth() async {
        let vm = BACViewModel(pureAlcoholGrams: 20, drinkingDurationHours: 1,
                              weightProvider: StubWeightProvider(kg: 82))
        await vm.importWeightFromHealth()
        #expect(vm.weightKilograms == 82)
        #expect(vm.weightFromHealthKit)
    }

    /// 假体重源返回 nil 时不改动体重。
    @Test func importWeightNoData() async {
        let vm = BACViewModel(pureAlcoholGrams: 20, drinkingDurationHours: 1,
                              weightProvider: StubWeightProvider(kg: nil))
        let before = vm.weightKilograms
        await vm.importWeightFromHealth()
        #expect(vm.weightKilograms == before)
        #expect(vm.weightFromHealthKit == false)
    }
}

/// 测试替身：可注入的体重源。
private struct StubWeightProvider: BodyWeightProviding {
    let kg: Double?
    func latestWeightKilograms() async -> Double? { kg }
}
