import Foundation
import Engine

// MARK: - 配方菜单 ViewModel（MVVM）
//
// 负责持有全部配方、当前香型筛选，并对外输出筛选后的列表。纯逻辑、可单测。

@MainActor
public final class RecipeMenuViewModel: ObservableObject {

    /// 数据源（默认官方配方库；测试可注入自定义数据）。
    private let allRecipes: [Recipe]

    /// 当前选中的香型筛选。
    @Published public var filter: AromaFilter = .all

    public init(recipes: [Recipe] = RecipeLibrary.all) {
        self.allRecipes = recipes
    }

    /// 可供筛选的筹码（全部 + 仅在数据中出现的香型）。
    public var availableFilters: [AromaFilter] {
        let present = Set(allRecipes.map(\.aroma))
        return AromaFilter.allCases.filter {
            switch $0 {
            case .all: return true
            case .aroma(let a): return present.contains(a)
            }
        }
    }

    /// 当前筛选后的配方列表（保持库的稳定排序）。
    public var filteredRecipes: [Recipe] {
        allRecipes.filter { filter.matches($0) }
    }

    /// 选中某筛选项。
    public func select(_ filter: AromaFilter) {
        self.filter = filter
    }
}
