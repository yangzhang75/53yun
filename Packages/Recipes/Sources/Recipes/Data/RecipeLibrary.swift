import Foundation
import Engine

// MARK: - 官方配方库（Recipe Library）
//
// 从随包分发的结构化资源 `recipes.json` 解码官方配方。
// 配方模型 `Recipe` / `FlavorProfile` / `Component` / `AromaType` 全部来自 Engine，本包不重造。

public enum RecipeLibraryError: Error, CustomStringConvertible {
    case resourceMissing(String)
    case decodeFailed(underlying: Error)

    public var description: String {
        switch self {
        case .resourceMissing(let name):
            return "找不到配方资源文件：\(name)"
        case .decodeFailed(let underlying):
            return "配方资源解码失败：\(underlying)"
        }
    }
}

public enum RecipeLibrary {

    /// 资源文件名（不含扩展名）。
    static let resourceName = "recipes"

    /// 全部官方配方（已按香型→名称稳定排序）。失败时返回空数组，绝不崩溃。
    public static let all: [Recipe] = {
        (try? load()).map(sorted) ?? []
    }()

    /// 从 `recipes.json` 解码并校验配方。供测试直接调用以获得抛错信息。
    public static func load() throws -> [Recipe] {
        guard let url = Bundle.module.url(forResource: resourceName, withExtension: "json") else {
            throw RecipeLibraryError.resourceMissing("\(resourceName).json")
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([Recipe].self, from: data)
        } catch {
            throw RecipeLibraryError.decodeFailed(underlying: error)
        }
    }

    /// 按香型分组（保持各组内的稳定排序）。
    public static func grouped(_ recipes: [Recipe] = all) -> [(aroma: AromaType, recipes: [Recipe])] {
        AromaType.allCases.compactMap { aroma in
            let items = recipes.filter { $0.aroma == aroma }
            return items.isEmpty ? nil : (aroma, items)
        }
    }

    /// 香型优先、再按名称的稳定排序，保证菜单展示顺序可预测。
    static func sorted(_ recipes: [Recipe]) -> [Recipe] {
        recipes.sorted { lhs, rhs in
            if lhs.aroma != rhs.aroma {
                return aromaOrder(lhs.aroma) < aromaOrder(rhs.aroma)
            }
            return lhs.name.localizedCompare(rhs.name) == .orderedAscending
        }
    }

    private static func aromaOrder(_ aroma: AromaType) -> Int {
        AromaType.allCases.firstIndex(of: aroma) ?? .max
    }
}
