# AICompanion —「AI 调酒师」（员工⑩）

53° 雲（YÚN）·「微醺之度」差异化卖点：用户用自然语言描述需求，AI 给出**推荐香型 + 配比 + 兑法**，并能**一键载入计算器**（产出 Engine 的标准 `Recipe`）。

> 边界：本包只做推荐与对话 UI。**不实现度数公式** —— 精确兑制/标准杯由 Engine 计算。

---

## 能力

| 验收项 | 实现 |
| --- | --- |
| 常见诉求给出合理配方 | `LocalRuleRecommender` 中文诉求解析 + 规则装配 |
| 一键载入计算器 | `Recommendation.recipe`（标准 `Recipe`）→ `onLoadRecipe` 回调 |
| 两套实现：大模型 + 本地兜底 | `LLMRecommender` ＋ `LocalRuleRecommender`，由 `BartenderService` 编排 |
| 断网可用 | 云端失败/未配置/隐私优先 → 自动本地兜底 |
| 接口可配置 | `AICompanionConfig`（模式 / endpoint / 超时 / 隐私开关） |
| 密钥不硬编码 | 服务端代理（默认）或运行时注入 Bearer（`bearerTokenProvider`） |
| 隐私 | `PrivacyDisclosure` + 上传前用户同意闸门 |
| Preview | `BartenderChatView` / `RecommendationCardView` 的 `PreviewProvider` |
| 加分项 | 拍照识果 → `BartenderQuery.fruitHints`；语音输入 → 文本入 `viewModel.input` |

---

## 模块结构

```
AICompanionCore        ← 纯逻辑，无 SwiftUI，全部可单测
  EngineContract/      ← 共享契约兜底（见下「集成」）
  Models/              ← BartenderQuery / Recommendation / MixingMethod / 错误
  Config/              ← AICompanionConfig / LLMMode
  Privacy/             ← PrivacyDisclosure
  Recommender/         ← RecipeRecommending 协议 + 本地规则 + LLM + 解析 + BartenderService
AICompanion            ← SwiftUI 对话界面 + ViewModel（依赖 Core）
  Theme/ ViewModel/ Views/ Preview/
```

---

## 快速使用

```swift
import AICompanion
import AICompanionCore   // 集成 Engine 后，Recipe 等类型来自 Engine

// 1) 配置（默认纯本地、不联网、不上传）
let service = BartenderService(
    config: .localOnly,
    // 注入 Engine 的兑制计算，用于把精确配比回填进推荐卡（可选）
    mixPreview: { recipe in EngineMixCalculator.preview(recipe) } // 由员工②/③ 提供
)

// 2) 对话界面 + 一键载入计算器
BartenderChatView(service: service) { recipe in
    // recipe 是标准 Engine.Recipe，直接喂给计算器界面
    calculatorRouter.load(recipe)
}
```

### 启用云端 AI（走服务端代理，推荐）

```swift
let config = AICompanionConfig(
    llmMode: .serverProxy,                                   // 密钥在服务端，App 不持有
    endpoint: URL(string: "https://api.yun53.com/bartender"),
    modelName: "yun-bartender",
    allowCloudUpload: false,   // 初始关闭；用户在隐私提示中同意后由 ViewModel 置 true
    preferLocal: false
)
let service = BartenderService(config: config)
```

首次需要联网时，`BartenderViewModel` 会先弹出隐私同意框（`PrivacyDisclosure.bartender`）。
用户点「仅用本地推荐」则全程不联网；点「同意并继续」才上传本次诉求文本。

### 直连大模型（不走代理时）

密钥**绝不写进代码**，运行时从 Keychain 注入：

```swift
var config = AICompanionConfig(llmMode: .directWithInjectedToken, endpoint: modelEndpoint)
config.bearerTokenProvider = { Keychain.read("llm_api_key") }
```

---

## 与 Engine / DesignSystem 集成（员工① 接入时）

本包是**可独立编译/测试的叶子包**。集成只需两步：

1. **接 Engine**：在 `Package.swift` 取消注释 `.package(path: "../Engine")` 与对应 `.product`。
   `EngineContract.swift` 用 `#if canImport(Engine)` 守卫——一旦 Engine 在场即 `@_exported import Engine`，
   兜底契约自动失效，本包直接产出 **Engine 的** `Recipe`，**零改动**。
   > 前提：Engine 的 `Recipe / Component / AromaType / FlavorProfile / MixResult` 字段与
   > `EngineContract.swift` 中的兜底定义保持一致（已按《共享数据契约》对齐）。

2. **接 DesignSystem**（可选）：`Theme/AICompanionTheme.swift` 的 `YunInk` 令牌镜像了
   墨黑+烫金+衬线设计变量，可替换为 `import DesignSystem` 的官方 Color / Font。

---

## 测试

核心逻辑测试在 `Tests/AICompanionCoreTests`（XCTest）：
- `NaturalLanguageParserTests` — 中文解析（香型/度数/口味/兑法/全角数字）
- `LocalRuleRecommenderTests` — 规则装配、度数夹取、兜底
- `BartenderServiceTests` — 云端失败兜底、隐私闸门、Engine 预览注入、LLM JSON 解析（含 OpenAI 风格包裹）

```bash
swift test   # 需在装有完整 Xcode 的环境运行（XCTest 随 Xcode 提供）
```

> 注：纯命令行工具链（无 Xcode）不含 XCTest；CI 请用 `xcodebuild test` 或装有 Xcode 的 runner。

---

## 合规要点（上架红线）

- 推荐卡与对话固定展示「请理性饮酒 · 未成年人请勿饮酒」。
- 推荐来源诚实标注（`云端 AI` / `本地推荐` 角标）。
- 任何云端上传前必须经用户同意；默认优先本地，不联网。
- App 侧需在 `PrivacyInfo.xcprivacy` 声明上传的用户内容（不用于追踪），见 `PrivacyManifest.sample.json`。
