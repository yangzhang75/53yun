# Recipes — 配方菜单 + 风味雷达图（员工④）

「微醺之度」的内容核心：内置官方配方「微醺菜单」、暗金高端排版的列表/详情，以及随配方变化的五维风味雷达图。

## 依赖

本包**不重造**共享数据模型，全部引用 `Engine`：

```
.package(path: "../Engine")        // Recipe / FlavorProfile / Component / AromaType
.package(path: "../DesignSystem")  // 颜色 / 字体 / 组件 / 动效
```

集成时由主工程（员工①）提供这两个兄弟包。本包目录内不包含它们的副本。

## 对外公开接口（public API）

| 类型 | 说明 |
| --- | --- |
| `RecipesModule` | 模块入口，遵循 `DesignSystem.YunModule`。`tab` 提供 Tab 元信息；`rootView(onLoadIntoMixer:)` 返回带「一键载入」路由的根视图。 |
| `RecipeMenuView(recipes:onLoadIntoMixer:)` | 配方菜单（列表页）。按香型筛选、点击进入详情。 |
| `RecipeDetailView(recipe:onLoadIntoMixer:)` | 配方详情页。雷达图 + 成分配比 + 品鉴 + 「一键载入到调制器」。 |
| `FlavorRadarChart(profile:rings:)` | 五维风味雷达图（醇厚/酒劲/净爽/回甘/层次），暗金描边，带入场动效。 |
| `RecipeLibrary` | 官方配方库：`all` / `load()` / `grouped()`。 |
| `RecipeMenuViewModel` | 列表页 MVVM，承载香型筛选逻辑。 |
| `FlavorAxis` / `AromaFilter` | 雷达五维轴、香型筛选项（含中文展示名与匹配逻辑）。 |

## 一键载入到调制器（回调路由）

详情页底部「一键载入到调制器」按钮通过回调把 `Recipe` 传出去，**本包不做导航**，由主工程路由到 Mixing 模块：

```swift
RecipesModule.rootView(onLoadIntoMixer: { recipe in
    // 员工① 在此把 recipe 路由到调制器
    router.openMixer(with: recipe)
})

// 或直接使用视图：
RecipeMenuView(onLoadIntoMixer: { recipe in ... })
```

## 配方数据

官方配方写成结构化资源 `Sources/Recipes/Resources/recipes.json`，随包分发，经 `Bundle.module` + `JSONDecoder` 解码为 `[Recipe]`。

内置 9 款，覆盖清/酱/浓三香型，每款含：名称、香型、成分配比、目标度数、一句品鉴文案、`FlavorProfile`：

- **清香**：晨露·清饮、竹露、青梅引
- **酱香**：焦糖琥珀、空杯香、酱韵·纯饮
- **浓香**：桂影、窖藏·绵柔、荔香醉

新增配方只需向 JSON 追加一条；`targetABV` 应与成分配比大致吻合（测试容差 3%）。

## 风味雷达图

- 五维（顺时针自正上方）：**醇厚 / 酒劲 / 净爽 / 回甘 / 层次**，取自 `FlavorProfile`，clamp 到 0~1。
- 网格（同心五边形 + 辐条）用 `Canvas` 绘制；数据多边形用可动画 `Shape`（`animatableData`）从圆心展开。
- 暗金描边（`YunColor.goldGradient`），尊重「降低动态效果」无障碍设置。

## 测试

`Tests/RecipesTests/` 覆盖：配方资源解码、≥8 款且覆盖三香型、字段完整、风味值域、id 唯一、度数与配比自洽、雷达轴顺序/clamp、香型筛选与分组、ViewModel 筛选。

> 验证说明：本包在仅装 Command Line Tools（无 Xcode）的环境下，已通过 `swift build` 完整编译（数据层 + 全部 SwiftUI 视图针对真实 Engine/DesignSystem），并以等价可执行用例跑通全部断言。XCTest 与 `#Preview` 需在 Xcode 环境运行。

## 合规

详情/列表底部统一展示 `ResponsibleDrinkingBanner`（请理性饮酒 · 未成年人请勿饮酒）。本包不涉及任何售卖交易。
