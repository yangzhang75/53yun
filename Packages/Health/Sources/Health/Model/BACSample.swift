import Foundation

/// BAC 曲线上的一个采样点。
public struct BACSample: Equatable, Codable, Sendable, Identifiable {

    /// 自第一口酒起经过的小时数。
    public var hoursSinceStart: Double

    /// 该时刻血液酒精浓度（mg/100mL）。
    public var bacMgPer100mL: Double

    public var id: Double { hoursSinceStart }

    public init(hoursSinceStart: Double, bacMgPer100mL: Double) {
        self.hoursSinceStart = hoursSinceStart
        self.bacMgPer100mL = bacMgPer100mL
    }
}
