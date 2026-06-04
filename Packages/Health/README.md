# Health 包 · BAC 微醺曲线（员工⑦）

负责任饮酒模块。基于 **Widmark 公式**估算血液酒精浓度（BAC），用 **Swift Charts** 绘制
「BAC 随时间衰减」曲线，并给出预计清醒时间、温柔适饮提示与一键叫代驾占位入口。

> 全程显著免责声明：本模块结果仅为**健康估算**，存在显著个体差异，
> **不构成法律或医学依据**，更不能作为是否可驾车的判断标准。请理性饮酒，未成年人请勿饮酒。

---

## 边界（重要）

- 本包**不**重算「纯酒精摄入量」这一公式心脏。纯酒精克数由 **Engine 的 `MixResult`** 计算，
  经 App 层映射为本包的 `AlcoholIntake` 注入。本包只负责 **BAC（Widmark）估算与展示**。
- 本包当前**自包含、可独立构建与测试**：
  - `Engine` / `DesignSystem` 尚未接入本分支，故：
    - 输入通过中性的 `AlcoholIntake`（纯酒精克数 / 标准杯）接入，集成时由 App 层从 `MixResult` 映射；
    - 视觉 token 暂由 `HealthTheme`（墨黑 + 烫金 + 衬线标题）占位，集成时整体替换为 `DesignSystem`。

## 隐私

- 体重 / 性别 / 时长等数据**默认仅在本机参与计算，不上传**。
- 可选 HealthKit 体重读取：仅「读取」`bodyMass` 一项，不写入、不上传。
  需在宿主 App `Info.plist` 配置 `NSHealthShareUsageDescription`，例如：
  「用于读取你的体重，以便更准确地估算血液酒精浓度，数据仅保存在本机。」

---

## 对外公开接口

### 主 View

```swift
import Health

// 便捷用法：直接传入纯酒精克数（来自 Engine MixResult）
BACDashboardView(pureAlcoholGrams: mixResult.standardUnits * 10,
                 drinkingDurationHours: 1.5,
                 profile: .default)

// 或注入预置 ViewModel（推荐，便于与 App 状态/HealthKit 协同）
let vm = BACViewModel(pureAlcoholGrams: 40, drinkingDurationHours: 2)
BACDashboardView(viewModel: vm)
```

### 核心类型

| 类型 | 作用 |
| --- | --- |
| `AlcoholIntake` | 饮酒输入：`pureAlcoholGrams` + `drinkingDurationHours`。提供 `init(standardUnits:…)` 适配 `MixResult` |
| `BiometricProfile` | 体重 + 生理性别（`BiologicalSex`） |
| `BACParameters` | Widmark 系数 r、消除速率 β、国标阈值（20 / 80 mg/100mL） |
| `WidmarkCalculator` | 纯函数引擎：`estimate(intake:profile:) -> BACEstimate` |
| `BACEstimate` | 结果：曲线 `[BACSample]`、当前/峰值 BAC、清醒/可驾车倒计时、风险等级 |
| `DrinkingPaceAdvisor` | 「适饮节奏温柔提示」生成器 |
| `DesignatedDriverService` | 一键叫代驾入口（占位 / 可跳第三方，不在 App 内交易） |
| `BodyWeightProviding` | 体重来源协议；`ManualWeightProvider`（默认）/ `HealthKitWeightProvider`（iOS） |
| `BACViewModel` | `@Observable @MainActor` 视图模型（MVVM） |
| `HealthDisclaimer` | 全部免责声明 / 理性饮酒文案 |

### Engine 集成示例（App 层）

```swift
import Engine
import Health

let mix: MixResult = engine.mix(recipe)            // Engine 负责纯酒精量
let intake = AlcoholIntake(standardUnits: mix.standardUnits,
                           drinkingDurationHours: 1.5)
let vm = BACViewModel(pureAlcoholGrams: intake.pureAlcoholGrams,
                      drinkingDurationHours: intake.drinkingDurationHours,
                      weightProvider: HealthKitWeightProvider())   // iOS 可选
```

---

## 模型说明（Widmark）

内部统一单位 **mg/100mL**，与中国《GB19522》口径一致（饮酒 ≥20、醉酒 ≥80）。

- 峰值（全吸收、未消除）：`peak = A × 100 / (W × r)`，A=纯酒精克数，W=体重(kg)，r=分布系数（男 0.68 / 女 0.55）。
- 吸收：饮用时长 T 内线性吸收 `absorbed(t) = peak × min(1, t/T)`。
- 消除：恒定速率 β=15 mg/100mL/小时（保守偏低，使清醒时间估计偏安全）。
- 任意时刻：`BAC(t) = max(0, absorbed(t) − eliminated(t))`。
- 清醒（BAC→0）时刻 = `peak / β`。

合理性（已被单元测试覆盖）：体重↑→峰值↓；女性>男性；时长↑→峰值↓；摄入↑→BAC↑。

---

## 构建与测试

```bash
cd Packages/Health
swift build
```

测试使用 Apple **swift-testing**（`import Testing`，Xcode 16+ / iOS 17 工具链原生支持）。
在完整 Xcode 中可直接 `⌘U` 运行。

> 本机仅安装 CommandLineTools（无完整 Xcode），其未捆绑 XCTest，且 swift-testing 运行时
> 需手动指向 `Testing.framework`。本仓库提供脚本封装：

```bash
./run-tests.sh
```

结果：**23 个测试 / 4 个 Suite 全部通过**。

---

## 预览（Preview）

以下 View 均带 SwiftUI Preview（`PreviewProvider`，兼容命令行构建）：
`BACDashboardView`（两组场景）、`BACCurveChart`、`DisclaimerBanner`。

## 验收对照

- [x] 输入体重/性别/时长，Widmark 估算 BAC，Swift Charts 画衰减曲线
- [x] 输出预计清醒时间 + 温柔适饮提示 + 一键叫代驾（占位）
- [x] 全程显著免责声明 + 理性饮酒提示
- [x] 默认仅本地计算、不上传；可选 HealthKit 读体重（含权限说明）
- [x] 曲线随输入合理变化（单调性测试覆盖）
- [x] 含 Preview 与单元测试（23 项全绿）
