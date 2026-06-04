import Foundation

/// 体重数据来源抽象。默认不读取任何系统数据（隐私友好）。
public protocol BodyWeightProviding: Sendable {
    /// 请求并读取最新体重（公斤）。返回 nil 表示无授权/无数据/不支持。
    func latestWeightKilograms() async -> Double?
}

/// 默认实现：不接入任何系统健康数据，始终返回 nil（由用户手动输入）。
public struct ManualWeightProvider: BodyWeightProviding {
    public init() {}
    public func latestWeightKilograms() async -> Double? { nil }
}

#if canImport(HealthKit) && os(iOS)
import HealthKit

/// 可选：从 HealthKit 读取体重。
///
/// 隐私：仅「读取」体重一项；不写入、不上传，读到的值仅在本地参与 BAC 估算。
/// 使用前 App 需在 Info.plist 提供 `NSHealthShareUsageDescription` 权限说明，例如：
/// 「用于读取你的体重，以便更准确地为你估算血液酒精浓度。数据仅保存在本机。」
public final class HealthKitWeightProvider: BodyWeightProviding {

    private let store = HKHealthStore()

    public init() {}

    public func latestWeightKilograms() async -> Double? {
        guard HKHealthStore.isHealthDataAvailable() else { return nil }
        guard let bodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass) else { return nil }

        // 请求读取授权。
        do {
            try await store.requestAuthorization(toShare: [], read: [bodyMass])
        } catch {
            return nil
        }

        // 取最近一条体重样本。
        return await withCheckedContinuation { (continuation: CheckedContinuation<Double?, Never>) in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(sampleType: bodyMass,
                                      predicate: nil,
                                      limit: 1,
                                      sortDescriptors: [sort]) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                let kg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                continuation.resume(returning: kg)
            }
            store.execute(query)
        }
    }
}
#endif
