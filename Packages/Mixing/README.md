# Mixing 包（员工③）

让计算贴近真实饮用场景：**单位换算 / 冰融稀释 / 酒精摄入展示**。
依赖 `Engine`（计算公式）与 `DesignSystem`（样式）。本包**只做前后换算与展示**，
不修改 Engine 的公式本身。

```
带单位输入 ──单位换算──▶ [Engine 计算] ──冰融稀释修正──▶ 展示文案
```

## 安装

本地 SPM 包，放在 `Packages/Mixing`，与 `Packages/Engine`、`Packages/DesignSystem` 同级。

```swift
.package(path: "../Mixing")
// target 依赖加入 "Mixing"
```

> ⚠️ 仓库内的 `Packages/Engine` 与 `Packages/DesignSystem` 目前是**契约桩**
> （仅含本包编译/测试所需的最小公开接口），由员工② 与 DesignSystem 负责方替换为正式实现。
> 只要公开接口（`Component` / `MixResult` / `MixEngine` / `YunColor` / `YunFont` / `yunCard()`）
> 保持一致，本包无需改动。

## 公开接口

### 1. 单位换算层 — `VolumeUnit` / `VolumeMeasurement` / `UnitConverter`

支持 **毫升 / 标准杯(30ml) / 分酒器(可配置) / 盖数(可配置)**，互相换算。
分酒器、盖、标准杯的实际容量来自 `MixingConfig`。

```swift
let cups = VolumeMeasurement(value: 2, unit: .standardCup)
cups.toMilliliters()                 // 60
cups.converted(to: .jigger).value    // 4（默认分酒器 15ml）

let cfg = MixingConfig(jiggerML: 20)
VolumeMeasurement(value: 3, unit: .jigger).toMilliliters(cfg)   // 60
```

### 2. 冰融稀释模型 — `IceLevel` / `IceDilution`

三档：**不加冰 / 冰块 / 大冰球**。按经验稀释系数修正最终度数与体积。
> 稀释系数为**经验估算**（冰块约 +15%、大冰球约 +8%），在 `MixingConfig` 集中配置。
> 模型：加水比例 f → 度数 = abv / (1+f)，总量 = totalML × (1+f)，纯酒精克数不变。

```swift
let r = IceDilution.apply(abv: 40, totalML: 100, ice: .cube)
r.dilutedABV       // 40 / 1.15 ≈ 34.8
r.dilutedTotalML   // 115
r.isEstimate       // true（用于 UI 的「≈」提示）
```

### 3. 酒精摄入展示封装 — `AlcoholDisplay`

把 Engine 的 `alcoholGrams` / `standardUnits` 转成可读中文文案。

```swift
let d = AlcoholDisplay(mixResult)
d.standardCupText   // "本杯≈3.2标准杯酒精"
d.pureAlcoholText   // "相当于 31.6 克纯酒精"
d.summaryText       // 合并一行
```

### 4. 门面服务 — `MixingService` / `MixingOutcome`

一步串起：单位换算 → Engine 计算 → 冰融修正 → 展示。

```swift
let service = MixingService()                 // 或 MixingService(config:)
let outcome = service.mix(components: [
    (VolumeMeasurement(value: 2, unit: .standardCup), 53),  // 2 标准杯 53° 白酒
    (VolumeMeasurement(value: 100, unit: .milliliter), 0)   // 100ml 果汁
], ice: .cube)

outcome.finalABV                 // 含冰融修正的最终度数
outcome.finalTotalML             // 含冰融体积
outcome.display.summaryText      // 酒精摄入文案
outcome.engineResult             // Engine 原始结果（克数/标准单位以此为准）

// 调兑计算器：加多少酒能到目标度数
service.solveAddition(base: [...], spiritABV: 53, targetABV: 20, ice: .none)
```

### 5. SwiftUI 组件 — `UnitIcePickerView`

「单位 / 冰量选择器」，墨黑 + 烫金 DesignSystem 样式，绑定输出当前选择。
含 `PreviewProvider` 预览（在 Xcode 画布实时预览）。

```swift
@State private var unit: VolumeUnit = .standardCup
@State private var ice: IceLevel = .cube

UnitIcePickerView(unit: $unit, ice: $ice)               // 默认配置
UnitIcePickerView(unit: $unit, ice: $ice, config: cfg)  // 自定义容量/系数
```

## 测试

`Tests/MixingTests`（XCTest）覆盖单位换算、冰融稀释、展示文案、门面服务四块。

```bash
# 需要完整 Xcode（XCTest）。命令行工具链下可用 `xcrun swift build` 验证编译。
xcrun swift test
```

## 合规

涉及酒精摄入展示，请配合全局「请理性饮酒 / 未成年人请勿饮酒」与年龄门。
冰融数值均为估算，UI 应以「≈」呈现，不作精确承诺。
