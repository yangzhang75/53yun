import Foundation
import Engine

// MARK: - AromaType 的菜单层展示扩展
//
// 仅承载 Recipes 包 UI 所需的展示文案（副标题、SF Symbol、强调用法），
// 不改动 Engine 中的契约本体。香型本体（rawValue / displayName）仍以 Engine 为准。

public extension AromaType {
    /// 香型一句话定位，用于列表/筛选副标题。
    var tagline: String {
        switch self {
        case .qingxiang: return "清雅净爽 · 一口干净"
        case .jiangxiang: return "幽雅醇厚 · 空杯留香"
        case .nongxiang: return "窖香浓郁 · 绵甜协调"
        }
    }

    /// 香型对应的 SF Symbol（暗金线性图标）。
    var symbolName: String {
        switch self {
        case .qingxiang: return "leaf"
        case .jiangxiang: return "drop.halffull"
        case .nongxiang: return "flame"
        }
    }
}

// MARK: - 香型筛选项

/// 列表页筛选用的香型选择：全部 + 三大香型。
public enum AromaFilter: Hashable, Identifiable, CaseIterable, Sendable {
    case all
    case aroma(AromaType)

    public static var allCases: [AromaFilter] {
        [.all] + AromaType.allCases.map(AromaFilter.aroma)
    }

    public var id: String {
        switch self {
        case .all: return "all"
        case .aroma(let a): return a.rawValue
        }
    }

    /// 筛选筹码上的中文标题。
    public var title: String {
        switch self {
        case .all: return "全部"
        case .aroma(let a): return a.displayName
        }
    }

    /// 是否匹配给定配方。
    public func matches(_ recipe: Recipe) -> Bool {
        switch self {
        case .all: return true
        case .aroma(let a): return recipe.aroma == a
        }
    }
}
