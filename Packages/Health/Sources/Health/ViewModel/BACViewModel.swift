import Foundation
import Observation

/// 微醺曲线模块的视图模型（MVVM）。
///
/// 持有输入（体重/性别/饮用时长 + 来自 Engine 的纯酒精克数），驱动 Widmark 估算，
/// 输出曲线、清醒时间、温柔提示与代驾入口。全程仅本地计算，不上传。
@Observable
@MainActor
public final class BACViewModel {

    // MARK: - 输入

    /// 纯酒精克数（来自 Engine MixResult）。
    public var pureAlcoholGrams: Double {
        didSet { recompute() }
    }

    /// 饮用时长（小时）。
    public var drinkingDurationHours: Double {
        didSet { recompute() }
    }

    /// 体重（公斤）。
    public var weightKilograms: Double {
        didSet { recompute() }
    }

    /// 生理性别。
    public var sex: BiologicalSex {
        didSet { recompute() }
    }

    /// 体重是否来自 HealthKit（用于 UI 标注）。
    public private(set) var weightFromHealthKit = false

    // MARK: - 输出（派生状态）

    public private(set) var estimate: BACEstimate = .empty
    public private(set) var tips: [PaceTip] = []
    public private(set) var headline: String = ""

    // MARK: - 依赖

    private let calculator: WidmarkCalculator
    private let advisor: DrinkingPaceAdvisor
    private let weightProvider: BodyWeightProviding

    /// 代驾服务入口。
    public let driverService: DesignatedDriverService

    public init(pureAlcoholGrams: Double = 0,
                drinkingDurationHours: Double = 1.0,
                profile: BiometricProfile = .default,
                calculator: WidmarkCalculator = WidmarkCalculator(),
                advisor: DrinkingPaceAdvisor = DrinkingPaceAdvisor(),
                weightProvider: BodyWeightProviding = ManualWeightProvider(),
                driverService: DesignatedDriverService = DesignatedDriverService()) {
        self.pureAlcoholGrams = pureAlcoholGrams
        self.drinkingDurationHours = drinkingDurationHours
        self.weightKilograms = profile.weightKilograms
        self.sex = profile.sex
        self.calculator = calculator
        self.advisor = advisor
        self.weightProvider = weightProvider
        self.driverService = driverService
        recompute()
    }

    // MARK: - 计算

    private var intake: AlcoholIntake {
        AlcoholIntake(pureAlcoholGrams: pureAlcoholGrams,
                      drinkingDurationHours: drinkingDurationHours)
    }

    private var profile: BiometricProfile {
        BiometricProfile(weightKilograms: weightKilograms, sex: sex)
    }

    private func recompute() {
        let result = calculator.estimate(intake: intake, profile: profile)
        estimate = result
        tips = advisor.tips(for: result)
        headline = advisor.headline(for: result)
    }

    // MARK: - HealthKit 体重导入（可选）

    /// 尝试从健康数据读取体重；成功则填入并标注来源。
    public func importWeightFromHealth() async {
        guard let kg = await weightProvider.latestWeightKilograms() else { return }
        weightFromHealthKit = true
        weightKilograms = kg // didSet 触发 recompute
    }

    // MARK: - 展示用格式化

    /// 当前 BAC（mg/100mL），保留 1 位。
    public var currentBACText: String {
        String(format: "%.1f", estimate.currentBACMgPer100mL)
    }

    /// 折算标准杯（保留 1 位）。
    public var standardUnitsText: String {
        String(format: "%.1f", intake.standardUnits)
    }

    /// 「预计清醒时间」人性化文案（从现在起）。
    public var soberCountdownText: String {
        BACViewModel.durationText(hours: estimate.hoursUntilSober, zeroText: "已清醒")
    }

    /// 「可合法驾车」倒计时文案（仅参考，非法律依据）。
    public var legalDrivingCountdownText: String {
        BACViewModel.durationText(hours: estimate.hoursUntilLegalDriving, zeroText: "已低于阈值")
    }

    /// 预计清醒的钟点时间（基于传入的「现在」时间）。
    public func soberClockText(now: Date, calendar: Calendar = .current) -> String {
        guard estimate.hoursUntilSober > 0 else { return "—" }
        let target = now.addingTimeInterval(estimate.hoursUntilSober * 3600)
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "zh_Hans")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: target)
    }

    /// 把小时数转成「X 小时 Y 分」式文案。
    static func durationText(hours: Double, zeroText: String) -> String {
        guard hours > 0 else { return zeroText }
        let totalMinutes = Int((hours * 60).rounded())
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        switch (h, m) {
        case (0, let m): return "约 \(m) 分钟"
        case (let h, 0): return "约 \(h) 小时"
        default: return "约 \(h) 小时 \(m) 分"
        }
    }
}
