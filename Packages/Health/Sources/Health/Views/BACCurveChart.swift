import SwiftUI
import Charts

/// 「BAC 随时间衰减」曲线（Swift Charts）。
///
/// 标注：饮酒驾车阈值(20)、醉酒阈值(80) 参考线，以及「现在」竖线。
public struct BACCurveChart: View {

    private let estimate: BACEstimate
    private let nowHour: Double

    /// - Parameters:
    ///   - estimate: Widmark 估算结果。
    ///   - nowHour: 「现在」在曲线上的横坐标（= 饮用时长），用于标注当前位置。
    public init(estimate: BACEstimate, nowHour: Double) {
        self.estimate = estimate
        self.nowHour = nowHour
    }

    private var maxBAC: Double {
        max(estimate.peakBACMgPer100mL, BACParameters.intoxicatedLimit) * 1.15
    }

    public var body: some View {
        Chart {
            // BAC 衰减曲线（烫金渐变填充）。
            ForEach(estimate.curve) { sample in
                AreaMark(
                    x: .value("小时", sample.hoursSinceStart),
                    y: .value("BAC", sample.bacMgPer100mL)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [HealthTheme.gold.opacity(0.35), HealthTheme.gold.opacity(0.02)],
                        startPoint: .top, endPoint: .bottom)
                )
            }
            ForEach(estimate.curve) { sample in
                LineMark(
                    x: .value("小时", sample.hoursSinceStart),
                    y: .value("BAC", sample.bacMgPer100mL)
                )
                .foregroundStyle(HealthTheme.gold)
                .interpolationMethod(.monotone)
            }

            // 阈值参考线。
            RuleMark(y: .value("饮酒驾车阈值", BACParameters.drivingLimit))
                .foregroundStyle(HealthTheme.tint(for: .driving).opacity(0.6))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .annotation(position: .top, alignment: .leading) {
                    Text("饮酒驾车 20")
                        .font(.caption2)
                        .foregroundStyle(HealthTheme.tint(for: .driving))
                }
            RuleMark(y: .value("醉酒阈值", BACParameters.intoxicatedLimit))
                .foregroundStyle(HealthTheme.tint(for: .intoxicated).opacity(0.6))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .annotation(position: .top, alignment: .leading) {
                    Text("醉酒 80")
                        .font(.caption2)
                        .foregroundStyle(HealthTheme.tint(for: .intoxicated))
                }

            // 「现在」竖线。
            RuleMark(x: .value("现在", nowHour))
                .foregroundStyle(HealthTheme.textSecondary.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 3]))
                .annotation(position: .bottom, alignment: .center) {
                    Text("现在")
                        .font(.caption2)
                        .foregroundStyle(HealthTheme.textSecondary)
                }
        }
        .chartYScale(domain: 0...maxBAC)
        .chartYAxisLabel("BAC (mg/100mL)")
        .chartXAxisLabel("小时")
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 6)) { _ in
                AxisGridLine().foregroundStyle(HealthTheme.textSecondary.opacity(0.12))
                AxisTick().foregroundStyle(HealthTheme.textSecondary.opacity(0.3))
                AxisValueLabel().foregroundStyle(HealthTheme.textSecondary)
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine().foregroundStyle(HealthTheme.textSecondary.opacity(0.12))
                AxisValueLabel().foregroundStyle(HealthTheme.textSecondary)
            }
        }
        .frame(height: 240)
    }
}

#if DEBUG
struct BACCurveChart_Previews: PreviewProvider {
    static var previews: some View {
        let intake = AlcoholIntake(standardUnits: 4, drinkingDurationHours: 2)
        let estimate = WidmarkCalculator().estimate(intake: intake, profile: .default)
        return BACCurveChart(estimate: estimate, nowHour: 2)
            .padding()
            .background(HealthTheme.ink)
    }
}
#endif
