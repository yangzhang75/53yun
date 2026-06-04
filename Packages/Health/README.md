# Health

> 归属：员工⑦ ｜ Tab/入口：微醺曲线（SF Symbol `waveform.path.ecg`）

BAC 微醺曲线，敬请期待。

## 对外接口（地基占位）
- `HealthModule`：遵循 `DesignSystem.YunModule`，由主工程拼装入口。
  - `static var tab: YunTab`
  - `static func rootView() -> AnyView`

## 依赖
- `DesignSystem`（组件 / 主题 / 入口协议）
- `Engine`（共享数据契约：Component / MixResult / Recipe / FlavorProfile / AromaType）

## 接手须知
1. 在 `Sources/Health` 内按 MVVM 开发，UI 用 DesignSystem 组件，数据用 Engine 类型。
2. 把 `HealthHomeView` 替换为真实根视图；保持 `HealthModule` 公开接口不变，便于主工程零改动集成。
3. 核心逻辑写 XCTest（见 `Tests/HealthTests`）。
4. 合规红线：全程「请理性饮酒 / 未成年人请勿饮酒」，禁止鼓励过量措辞，不在 App 内完成酒类交易。
