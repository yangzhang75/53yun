# Cellar —— 会员 / 我的酒柜（员工⑧）

> 53° 雲（YÚN）·「微醺之度」会员留存模块。
> 负责：我的酒柜（收藏配方 + 常用原酒）、微醺积分 / 等级、「我的」个人页。

## 模块分层

| Target | 内容 | 能否在纯命令行编译 |
| --- | --- | --- |
| **CellarCore** | 纯业务逻辑：`MeritEngine`（积分/等级/阈值）、`RecipeMapper`（Recipe ↔ 持久化快照）、共享契约占位 | ✅ 是 |
| **Cellar** | SwiftData `@Model` + SwiftUI 视图（含 `#Preview`） | ❌ 需 Xcode（SwiftData/SwiftUI 宏） |

> 之所以拆分：核心逻辑不依赖任何宏，可被 `swift test` 直接覆盖；UI/持久化层依赖 SwiftData/SwiftUI 宏插件，必须在 Xcode（或完整 SDK）下构建。

## 对外 public 接口

### 视图（注入 `CellarStore` 到 environment）
```swift
import Cellar

// 个人页：积分、等级、收藏数、暗金徽章
ProfileView()

// 我的酒柜：收藏配方（命名/编辑/删除/一键载入）+ 常用原酒
CellarView(onLoad: { recipe in
    // 把还原的 Engine.Recipe 交给 Mixing/Engine 触发计算
})

// 单独的等级徽章
MeritBadgeView(level: .gold, size: 96)
```

### 业务门面 `CellarStore`（`@MainActor @Observable`）
```swift
let container = try CellarSchema.makeContainer()       // App 启动时
let store = CellarStore(context: container.mainContext)

store.saveRecipe(recipe)          // 收藏（首次 +收藏分；同 id 再存=编辑，不重复计分）
store.rename(saved, to: "新名字")
store.delete(saved)
let recipe = store.load(saved)    // 一键载入（计调制分），返回 Engine.Recipe
store.addSpirit(name:abv:stockML:aroma:)

store.totalMerit()                // 累计积分
store.currentLevel()              // 青铜/白银/黄金/典藏
store.currentProgress()           // 进度（距下一级还差多少）
store.favoritesCount()
```

### 积分引擎 `MeritEngine`（可配置）
```swift
// 阈值与每事件计分均可配置
let engine = MeritEngine(
    points: .init(mix: 20, favorite: 10),
    thresholds: .init(silver: 100, gold: 300, collector: 800)
)
engine.level(for: 250)            // .silver
engine.progress(for: 250)         // MeritProgress
```

默认规则：调制 +20、收藏 +10；青铜 0 / 白银 100 / 黄金 300 / 典藏 800。

## SwiftData Schema（本包拥有）

- `SavedRecipe` — 收藏的配方，`recipeID` 唯一；通过 `RecipeMapper` 与 `Engine.Recipe` 互转（成分/风味以 JSON `Data` 存储，向后兼容）。
- `SavedSpirit` — 常用原酒（名称/度数/库存/香型）。
- `MeritRecord` — 积分明细（每次调制/收藏一条，累加得总分）。

`CellarSchema.makeContainer(inMemory:)` 统一构造容器（`inMemory: true` 供预览/测试）。

## 与 Engine / DesignSystem 的边界

本包**不修改** Engine 模型，只通过 `RecipeMapper` 做映射。为支持独立分支开发，包内含两个**临时占位**，集成时由员工① 删除并替换：

- `Sources/CellarCore/EngineContract_Standin.swift` → 替换为 `import Engine`
- `Sources/Cellar/Theme/CellarTheme_Standin.swift` → 替换为 `import DesignSystem`

集成时还需为对应 target 在 `Package.swift` 添加 Engine / DesignSystem 依赖。

## 测试

```bash
# 纯逻辑（命令行可跑）——积分/等级/阈值/映射 round-trip
swift test --filter CellarCoreTests

# 持久化 + 积分集成（需 Xcode）——重启后数据仍在、载入触发计算、积分/等级正确
xcodebuild test -scheme Cellar -destination 'platform=iOS Simulator,name=iPhone 15'
```

> 本仓库当前环境仅有 CommandLineTools（无 SwiftData/SwiftUI 宏插件），故 CellarCore 逻辑已用等价断言可执行程序验证通过；UI/持久化层与测试需在 Xcode 下构建运行。

## 验收对照

- ✅ 重启后数据仍在 → `testDataPersistsAcrossContainerReopen`（重开同一 store 文件）
- ✅ 收藏可载入触发计算 → `load()` 返回可计算的 `Recipe`（`testLoadReturnsRecipeAndAwardsMixPoint`）
- ✅ 积分/等级正确 → `CellarCoreTests` + `testLevelReachesSilverAndGold`
- ✅ Preview → `ProfileView` / `CellarView` / `MeritBadgeView` 均含 `#Preview`

## 合规

个人页底部常驻「请理性饮酒 · 未成年人请勿饮酒」。本模块不涉及任何酒类交易。
