import Foundation

/// Widmark BAC 估算引擎（纯函数，无 UI / 无副作用，可独立单元测试）。
///
/// 模型：
/// - 峰值（全吸收、未消除）BAC：`peak = A × 100 / (W × r)`（mg/100mL）
///   其中 A=纯酒精克数，W=体重(kg)，r=体液分布系数。
/// - 吸收：在饮用时长 T 内线性吸收，`absorbed(t) = peak × min(1, t/T)`。
/// - 消除：自始以恒定速率 β 线性消除，`eliminated(t) = β × t`。
/// - 任意时刻：`BAC(t) = max(0, absorbed(t) − eliminated(t))`。
///
/// 边界：本引擎只做 BAC 估算；纯酒精摄入量（A）由 Engine 的 MixResult 提供，本包不重算。
public struct WidmarkCalculator: Sendable {

    public let parameters: BACParameters

    public init(parameters: BACParameters = .default) {
        self.parameters = parameters
    }

    /// 峰值 BAC（全部吸收、尚未消除时的理论上限，mg/100mL）。
    public func peakIntrinsicMgPer100mL(intake: AlcoholIntake,
                                        profile: BiometricProfile) -> Double {
        let weight = profile.clampedWeightKilograms
        let r = parameters.distributionRatio(for: profile.sex)
        guard weight > 0, r > 0 else { return 0 }
        return intake.pureAlcoholGrams * 100.0 / (weight * r)
    }

    /// 任意时刻 t（自第一口起的小时数）的 BAC（mg/100mL）。
    public func bac(atHour t: Double,
                    intake: AlcoholIntake,
                    profile: BiometricProfile) -> Double {
        guard t > 0 else { return 0 }
        let peak = peakIntrinsicMgPer100mL(intake: intake, profile: profile)
        guard peak > 0 else { return 0 }

        let duration = intake.drinkingDurationHours
        let absorbedFraction: Double = duration > 0 ? min(1.0, t / duration) : 1.0
        let absorbed = peak * absorbedFraction
        let eliminated = parameters.eliminationRatePerHour * t
        return max(0, absorbed - eliminated)
    }

    /// 生成完整估算结果（曲线 + 关键指标）。
    ///
    /// - Parameter sampleIntervalHours: 采样步长（默认 6 分钟 = 0.1 小时）。
    public func estimate(intake: AlcoholIntake,
                         profile: BiometricProfile,
                         sampleIntervalHours: Double = 0.1) -> BACEstimate {

        let peak = peakIntrinsicMgPer100mL(intake: intake, profile: profile)
        let beta = parameters.eliminationRatePerHour
        guard intake.hasIntake, peak > 0, beta > 0 else { return .empty }

        let duration = intake.drinkingDurationHours
        // 「现在」= 饮用结束时刻，故当前 BAC 即 t=max(duration, ε) 处的值。
        let nowHour = max(duration, 0)
        let currentBAC = bac(atHour: max(nowHour, sampleIntervalHours / 2),
                             intake: intake, profile: profile)

        // 完全清醒（BAC→0）的绝对时刻：消除掉全部已吸收酒精所需时间 = peak/β（自第一口起）。
        let soberAtHour = peak / beta
        let hoursUntilSober = max(0, soberAtHour - nowHour)

        // 回落到饮酒驾车阈值（20mg/100mL）的绝对时刻。
        let drivingAtHour: Double = peak > BACParameters.drivingLimit
            ? (peak - BACParameters.drivingLimit) / beta
            : nowHour
        let hoursUntilLegalDriving = max(0, drivingAtHour - nowHour)

        // 采样曲线：从 0 到「清醒时刻」并留少量余量。
        let end = max(soberAtHour, nowHour) + sampleIntervalHours
        let step = max(sampleIntervalHours, 0.01)
        var curve: [BACSample] = []
        curve.reserveCapacity(Int(end / step) + 2)
        var t = 0.0
        while t <= end + step / 2 {
            curve.append(BACSample(hoursSinceStart: t,
                                   bacMgPer100mL: bac(atHour: t, intake: intake, profile: profile)))
            t += step
        }

        return BACEstimate(
            curve: curve,
            currentBACMgPer100mL: currentBAC,
            peakBACMgPer100mL: max(currentBAC, peak - beta * duration),
            hoursUntilSober: hoursUntilSober,
            hoursUntilLegalDriving: hoursUntilLegalDriving,
            level: WidmarkCalculator.level(forBAC: currentBAC)
        )
    }

    /// 由 BAC 值映射风险等级。
    public static func level(forBAC bac: Double) -> BACLevel {
        if bac >= BACParameters.intoxicatedLimit { return .intoxicated }
        if bac >= BACParameters.drivingLimit { return .driving }
        return .sober
    }
}
