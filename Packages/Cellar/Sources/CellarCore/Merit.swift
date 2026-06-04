//  Merit.swift
//  「微醺积分」纯逻辑：积分事件、等级、可配置阈值、进度计算。
//
//  设计为纯值类型，无任何持久化 / UI 依赖，便于单测。

import Foundation

/// 计积分的事件类型
public enum MeritKind: String, Codable, CaseIterable, Sendable {
    case mix       // 完成一次调制
    case favorite  // 收藏一次配方

    public var displayName: String {
        switch self {
        case .mix: return "调制"
        case .favorite: return "收藏"
        }
    }
}

/// 会员等级：青铜 / 白银 / 黄金 / 典藏
public enum MeritLevel: Int, CaseIterable, Codable, Comparable, Sendable {
    case bronze = 0    // 青铜
    case silver = 1    // 白银
    case gold = 2      // 黄金
    case collector = 3 // 典藏

    public static func < (lhs: MeritLevel, rhs: MeritLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public var title: String {
        switch self {
        case .bronze: return "青铜"
        case .silver: return "白银"
        case .gold: return "黄金"
        case .collector: return "典藏"
        }
    }

    /// 暗金徽章主色（十六进制，0xRRGGBB），供 DesignSystem 取色
    public var badgeHex: UInt32 {
        switch self {
        case .bronze: return 0x8C6A3F      // 古铜
        case .silver: return 0xB8BCC4      // 月银
        case .gold: return 0xC9A24B        // 烫金
        case .collector: return 0xE7C873   // 典藏亮金
        }
    }

    /// 下一等级（典藏已封顶则返回 nil）
    public var next: MeritLevel? {
        MeritLevel(rawValue: rawValue + 1)
    }
}

/// 各事件计多少分（可配置）
public struct MeritPoints: Codable, Hashable, Sendable {
    public var mix: Int
    public var favorite: Int

    public init(mix: Int = 20, favorite: Int = 10) {
        self.mix = mix
        self.favorite = favorite
    }

    public func points(for kind: MeritKind) -> Int {
        switch kind {
        case .mix: return mix
        case .favorite: return favorite
        }
    }

    public static let `default` = MeritPoints()
}

/// 升入各等级所需累计积分（青铜从 0 起）。阈值可配置。
public struct MeritThresholds: Codable, Hashable, Sendable {
    public var silver: Int
    public var gold: Int
    public var collector: Int

    public init(silver: Int = 100, gold: Int = 300, collector: Int = 800) {
        self.silver = silver
        self.gold = gold
        self.collector = collector
    }

    public static let `default` = MeritThresholds()

    /// 进入指定等级所需的累计积分门槛
    public func threshold(for level: MeritLevel) -> Int {
        switch level {
        case .bronze: return 0
        case .silver: return silver
        case .gold: return gold
        case .collector: return collector
        }
    }

    /// 阈值是否单调递增且非负（用于校验配置合法性）
    public var isValid: Bool {
        0 < silver && silver < gold && gold < collector
    }
}

/// 等级进度：当前等级 / 下一等级 / 距离下一级还差多少 / 进度比例
public struct MeritProgress: Equatable, Sendable {
    public let points: Int
    public let level: MeritLevel
    public let next: MeritLevel?
    public let pointsIntoLevel: Int      // 当前等级内已累计
    public let pointsForNext: Int?       // 升下一级还需多少（已封顶为 nil）
    public let fraction: Double          // 0...1，本级进度（封顶为 1）

    public init(points: Int, level: MeritLevel, next: MeritLevel?,
                pointsIntoLevel: Int, pointsForNext: Int?, fraction: Double) {
        self.points = points
        self.level = level
        self.next = next
        self.pointsIntoLevel = pointsIntoLevel
        self.pointsForNext = pointsForNext
        self.fraction = fraction
    }
}

/// 微醺积分引擎：把「累计积分」映射成等级与进度。
public struct MeritEngine: Sendable {
    public var points: MeritPoints
    public var thresholds: MeritThresholds

    public init(points: MeritPoints = .default, thresholds: MeritThresholds = .default) {
        self.points = points
        self.thresholds = thresholds
    }

    /// 单次事件计分
    public func points(for kind: MeritKind) -> Int {
        points.points(for: kind)
    }

    /// 由累计积分判定当前等级
    public func level(for total: Int) -> MeritLevel {
        // 从高到低匹配第一个达标的等级
        for level in MeritLevel.allCases.reversed() where total >= thresholds.threshold(for: level) {
            return level
        }
        return .bronze
    }

    /// 计算完整进度信息
    public func progress(for total: Int) -> MeritProgress {
        let clamped = max(0, total)
        let level = level(for: clamped)
        let base = thresholds.threshold(for: level)
        let into = clamped - base

        guard let next = level.next else {
            // 典藏封顶
            return MeritProgress(points: clamped, level: level, next: nil,
                                 pointsIntoLevel: into, pointsForNext: nil, fraction: 1)
        }
        let span = thresholds.threshold(for: next) - base
        let remaining = max(0, thresholds.threshold(for: next) - clamped)
        let fraction = span > 0 ? min(1, max(0, Double(into) / Double(span))) : 1
        return MeritProgress(points: clamped, level: level, next: next,
                             pointsIntoLevel: into, pointsForNext: remaining, fraction: fraction)
    }
}
