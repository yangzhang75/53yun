# DesignSystem

> 归属：员工① ｜ 颜色 / 字体 / 组件 / 入场动效 / **模块入口协议**

墨黑底 + 烫金描边 + 衬线中文标题，极简、奢华、克制。全员 UI 一律使用本包，禁止散落硬编码。

## 颜色令牌（`YunColor`）
`ink #0A0A0C`（墨黑底）｜`card #16161A`（卡片）｜`gold #C4A463`（烫金）｜`goldBright #E8D9A8`（亮金）｜`cream #EFEAE0`（米白文字）。
另有 `creamSecondary` / `hairline` / `goldGradient`。`Color(hex:)` 支持 `#RRGGBB` / `#RRGGBBAA`。

## 字体（`Font` 扩展）
- `.yunTitle(_:weight:)` 中文衬线标题（Noto Serif SC / 思源宋体）
- `.yunSerifLatin(_:)` 拉丁点缀（Cormorant Garamond）
- `.yunBody(_:)` 正文系统字体（支持动态字号）

> 字体文件未随包分发时自动回退系统衬线，开箱即用。就位步骤见下「字体安装」。

## 组件库
| 组件 | 用途 |
| --- | --- |
| `YunCard` | 深色卡片容器 + 烫金细描边 |
| `YunButton` | `.primary`（烫金填充）/ `.secondary`（金色描边） |
| `YunStat` | 数值展示卡（标题 + 大数值 + 单位） |
| `YunChip` | 胶囊标签 / 可选筹码 |
| `MistBackground` | 雾气背景层（Canvas 径向光晕） |
| `ResponsibleDrinkingBanner` | 「请理性饮酒 / 未成年人请勿饮酒」合规提示 |
| `FeaturePlaceholder` | 各功能包未交付前的统一占位页 |

## 动效与无障碍
- `.yunEntrance(index:)`：入场上浮渐显，按 `index` 错峰。
- 全部尊重「降低动态效果」(`accessibilityReduceMotion`)：开启时无位移、瞬时显示。

## 模块入口协议（`YunModule` / `YunTab`）
每个功能包对外暴露一个遵循 `YunModule` 的类型，主工程据此拼装 TabBar：
```swift
public enum XXModule: YunModule {
    public static let tab = YunTab(title: "调制", systemImage: "drop.fill")
    public static func rootView() -> AnyView { AnyView(XXHomeView()) }
}
```

## 预览
每个组件文件均含 `#Preview`，可在 Xcode Canvas 直接查看。

## 字体安装（可选，提升品牌质感）
1. 把 `NotoSerifSC-Regular.otf` / `NotoSerifSC-Bold.otf` / `CormorantGaramond-Medium.ttf`
   放入 `Sources/DesignSystem/Resources/Fonts/`。
2. 解注释 `Package.swift` 里的 `resources: [.process("Resources/Fonts")]`。
3. 在 App 侧 `Info.plist` 用 `UIAppFonts` 注册，或用 `CTFontManagerRegisterFontsForURL` 运行时注册。
   未注册时 `YunFontName.isFontAvailable` 返回 false，自动回退系统衬线。
