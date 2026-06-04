import SwiftUI
import Engine
import DesignSystem

// MARK: - 配方菜单（列表页）
//
// 「微醺菜单」：暗金高端排版，按香型筛选，点击进入详情。
// `onLoadIntoMixer` 一路透传到详情页的「一键载入」按钮，由主工程路由到调制器。

public struct RecipeMenuView: View {
    @StateObject private var model: RecipeMenuViewModel
    private let onLoadIntoMixer: ((Recipe) -> Void)?

    /// - Parameters:
    ///   - recipes: 数据源，默认官方配方库。
    ///   - onLoadIntoMixer: 「一键载入到调制器」回调，由主工程注入并路由。
    public init(recipes: [Recipe] = RecipeLibrary.all,
                onLoadIntoMixer: ((Recipe) -> Void)? = nil) {
        _model = StateObject(wrappedValue: RecipeMenuViewModel(recipes: recipes))
        self.onLoadIntoMixer = onLoadIntoMixer
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                MistBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: YunMetrics.spacingM) {
                        title
                        filterBar
                        list
                        ResponsibleDrinkingBanner()
                            .padding(.top, YunMetrics.spacingS)
                    }
                    .padding(YunMetrics.spacingM)
                }
            }
            .navigationTitle("微醺菜单")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe, onLoadIntoMixer: onLoadIntoMixer)
            }
        }
    }

    // MARK: - 区块

    private var title: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("53° 雲 · 官方配方")
                .font(.yunBody(.caption))
                .tracking(2)
                .foregroundStyle(YunColor.gold)
            Text("微醺之度")
                .font(.yunTitle(30, weight: .semibold))
                .foregroundStyle(YunColor.cream)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: YunMetrics.spacingS) {
                ForEach(model.availableFilters) { filter in
                    YunChip(filter.title, isSelected: model.filter == filter) {
                        withAnimation(.easeInOut(duration: 0.2)) { model.select(filter) }
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var list: some View {
        LazyVStack(spacing: YunMetrics.spacingM) {
            ForEach(Array(model.filteredRecipes.enumerated()), id: \.element.id) { index, recipe in
                NavigationLink(value: recipe) {
                    RecipeRowView(recipe: recipe)
                        .yunEntrance(index: index)
                }
                .buttonStyle(.plain)
            }

            if model.filteredRecipes.isEmpty {
                Text("该香型暂无配方")
                    .font(.yunBody(.subheadline))
                    .foregroundStyle(YunColor.creamSecondary)
                    .padding(.vertical, YunMetrics.spacingL)
            }
        }
    }
}

#Preview("配方菜单") {
    RecipeMenuView { recipe in
        print("载入到调制器：\(recipe.name)")
    }
    .preferredColorScheme(.dark)
}
