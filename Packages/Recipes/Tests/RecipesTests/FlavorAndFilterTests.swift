import XCTest
import Engine
@testable import Recipes

final class FlavorAndFilterTests: XCTestCase {

    // MARK: - FlavorAxis

    func testAxisOrderAndExtraction() {
        let profile = FlavorProfile(mellow: 0.1, strength: 0.2, crisp: 0.3, sweet: 0.4, complexity: 0.5)
        XCTAssertEqual(FlavorAxis.allCases.map(\.displayName), ["醇厚", "酒劲", "净爽", "回甘", "层次"])
        XCTAssertEqual(profile.axisValues, [0.1, 0.2, 0.3, 0.4, 0.5])
    }

    func testAxisValueClampsOutOfRange() {
        let profile = FlavorProfile(mellow: 1.5, strength: -0.3, crisp: 0.5, sweet: 2, complexity: 0.5)
        XCTAssertEqual(FlavorAxis.mellow.value(in: profile), 1.0)
        XCTAssertEqual(FlavorAxis.strength.value(in: profile), 0.0)
        XCTAssertEqual(FlavorAxis.sweet.value(in: profile), 1.0)
    }

    // MARK: - AromaFilter

    func testAromaFilterAllMatchesEverything() {
        for r in RecipeLibrary.all {
            XCTAssertTrue(AromaFilter.all.matches(r))
        }
    }

    func testAromaFilterMatchesOnlyItsAroma() {
        let filter = AromaFilter.aroma(.jiangxiang)
        for r in RecipeLibrary.all {
            XCTAssertEqual(filter.matches(r), r.aroma == .jiangxiang)
        }
    }

    // MARK: - ViewModel

    @MainActor
    func testViewModelFiltersByAroma() {
        let model = RecipeMenuViewModel()
        let total = model.filteredRecipes.count
        XCTAssertEqual(total, RecipeLibrary.all.count, "默认 .all 显示全部")

        model.select(.aroma(.qingxiang))
        XCTAssertTrue(model.filteredRecipes.allSatisfy { $0.aroma == .qingxiang })
        XCTAssertFalse(model.filteredRecipes.isEmpty)
    }

    @MainActor
    func testViewModelAvailableFiltersReflectData() {
        let single = [Recipe(name: "仅清香", aroma: .qingxiang,
                             components: [Component(volumeML: 50, abv: 50)],
                             targetABV: 25, tastingNote: "测试",
                             flavor: FlavorProfile(mellow: 0.5, strength: 0.5, crisp: 0.5, sweet: 0.5, complexity: 0.5))]
        let model = RecipeMenuViewModel(recipes: single)
        XCTAssertEqual(model.availableFilters, [.all, .aroma(.qingxiang)],
                       "筛选项应只包含数据中出现的香型")
    }
}
