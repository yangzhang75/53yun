# Engine — 计算引擎 + 共享数据模型

> 「微醺之度」App 的数学心脏。**纯 Swift、零 UI、无状态、线程安全。**
> 全员引用本包的数据模型；调制相关计算统一走本包的 `public` API。

- 语言：Swift 5.9+ / 最低 iOS 17（额外声明 macOS 仅用于命令行测试）
- 约束：**禁止 `import SwiftUI` / `UIKit`**。本包只负责计算与数据契约。

## 安装

在依赖方 `Package.swift` 中：

```swift
.package(path: "../Engine")
// target 依赖
.product(name: "Engine", target: "...")
```

`import Engine` 即可。

---

## 一、共享数据模型（全员引用）

| 类型 | 说明 | 协议 |
| --- | --- | --- |
| `AromaType` | 香型：`.qingxiang` / `.jiangxiang` / `.nongxiang`（清/酱/浓）。`rawValue` 稳定，用于持久化与深链。`displayName` 给中文展示。 | `Codable, CaseIterable, Sendable, Hashable` |
| `Component` | 单个组分：`id / name / volumeML / abv`（`abv` 为该组分自身酒精度 0~100，果汁=0）。 | `Identifiable, Codable, Hashable, Sendable` |
| `MixResult` | 调制结果：`addedML / totalML / actualABV / alcoholGrams / standardUnits`。 | `Codable, Hashable, Sendable` |
| `FlavorProfile` | 风味画像：`mellow / strength / crisp / sweet / complexity`，各 0~1。 | `Codable, Hashable, Sendable` |
| `Recipe` | 配方：`id / name / aroma / components / targetABV / tastingNote / flavor`。 | `Identifiable, Codable, Hashable, Sendable` |

> 所有数值字段不做四舍五入，**展示精度由 UI 层决定**。

---

## 二、三向自由解算 `MixEngine.solve(_:)`

物理模型：果汁视为 0% 无醇基底，向其中加入度数为 `Pa` 的原酒。
记 `Vj`=果汁体积，`Va`=加酒量，`Pa`=原酒度数，`Pt`=目标度数。

```
最终度数 = (Va × Pa) / (Va + Vj)
```

用 `SolveMode` 切换三种解算方向（关联值携带各自输入）：

| 模式 | 已知 → 求 | 公式 |
| --- | --- | --- |
| `.addedVolume(juiceML:baseABV:targetABV:)` | Vj, Pa, Pt → **加酒量 Va** | `Va = (Pt × Vj) / (Pa − Pt)` |
| `.finalABV(juiceML:addedML:baseABV:)` | Vj, Va, Pa → **最终度数** | `Pt = (Va × Pa) / (Va + Vj)` |
| `.requiredBaseABV(juiceML:addedML:targetABV:)` | Vj, Va, Pt → **所需原酒度数 Pa** | `Pa = Pt × (Va + Vj) / Va` |

```swift
let result = MixEngine.solve(
    .addedVolume(juiceML: 100, baseABV: 53, targetABV: 10)
)
// .success(MixResult(addedML: 23.255…, totalML: 123.255…, actualABV: 10, …))
```

返回 `Result<MixResult, MixError>`。

---

## 三、多组分混调 `MixEngine.mix(_:)`

输入多种 `Component`，输出混合总体积与**加权总度数**：

```
加权度数 = Σ(volumeML × abv) / Σ(volumeML)
```

```swift
let r = MixEngine.mix([
    Component(name: "鲜榨橙汁", volumeML: 100, abv: 0),
    Component(name: "53° 原酒", volumeML: 50,  abv: 53),
])
// actualABV ≈ 17.67，totalML = 150，addedML = 50（仅含酒组分之和）
```

> `MixResult.addedML` 在多组分场景为「所有 abv>0 组分体积之和」，与三向解算中的「加酒量」语义一致。

---

## 四、酒精量换算（写入每个 `MixResult`）

```
纯酒精体积(mL) = 总体积 × 实际度数 / 100
纯酒精克数(g)  = 纯酒精体积 × 0.789          // 乙醇密度 EngineConstants.ethanolDensityGramsPerML
标准酒精单位   = 纯酒精克数 / 10             // EngineConstants.gramsPerStandardUnit（WHO/中国口径：1 单位 = 10 g）
```

口径常量集中在 `EngineConstants`，便于统一调整。

---

## 五、边界与错误 `MixError`

均带可读中文 `errorDescription`，可直接呈现给用户：

| 错误 | 触发条件 |
| --- | --- |
| `.invalidInput(String)` | 体积为负、数值为 NaN/无穷 |
| `.abvOutOfRange(value:)` | 酒精度超出 0~100 |
| `.targetUnreachable(target:baseABV:)` | `Pa ≤ Pt`（加酒无法升到目标）、无酒可加却要求 >0 目标、或反解所需度数 >100% |
| `.zeroTotalVolume` | 总体积为 0 |
| `.emptyComponents` | 多组分混调传入空数组 |

`targetABV == 0` 视为合法（无需加酒，结果为 0 度）。

---

## 六、测试

`Tests/EngineTests` 用 XCTest 覆盖全部解算模式、换算与边界用例。

```bash
swift test            # 需完整 Xcode 工具链（XCTest）
```

> 若仅安装 Command Line Tools（无 XCTest），可改用 `swiftc Sources/Engine/*.swift <runner>.swift` 编译自检；CI / Xcode 环境下 `swift test` 全绿。

---

## 对外只暴露这些

`MixEngine.solve(_:)`、`MixEngine.mix(_:)`、`SolveMode`、`MixError`、`EngineConstants`，
以及全部数据模型（`AromaType / Component / MixResult / FlavorProfile / Recipe`）。
