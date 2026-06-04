# ShareCard（品鉴卡导出 + 分享）· 员工⑤

把一杯酒优雅地传播出去：将当前配方/结果渲染成精致竖版/方版品鉴卡，导出高清 PNG，并通过系统 `ShareLink` 分享「图片 + 深链」。

> 调性：墨黑底 + 烫金描边 + 衬线中文标题 + 克制微动效。

## 边界

- ✅ 本包负责：**卡片渲染 / 高清 PNG 导出 / 系统分享 / 深链字符串生成**。
- ❌ 本包不负责：**二维码图像生成** —— 交给员工⑥(`DeepLink`)。本包只预留「二维码视图槽位」和要编码的 URL 字符串。

## 依赖

- `Engine`（员工②）：共享数据契约（`Recipe` / `Component` / `AromaType` / `FlavorProfile` …）。
- `DesignSystem`（员工①）：品牌色 `YunColor`、字体 `YunFont`。

> ⚠️ 仓库当前的 `Packages/Engine` 与 `Packages/DesignSystem` 是**最小占位骨架**（仅暴露本包编译/预览所需的公共面），便于并行开发。员工②/① 落地正式实现后直接替换即可，公共签名保持稳定。

## 公共接口

### 1. 品鉴卡视图 `TastingCard`

```swift
// 注入员工⑥ 的二维码视图：
TastingCard(recipe: recipe, style: .momentsPortrait, deepLink: link) { url in
    QRView(url)            // 员工⑥ 的二维码组件
}

// 或使用内置占位槽（联调期）：
TastingCard(recipe: recipe, style: .square, deepLink: link)
```

含：品牌 logo、香型徽章、目标度数、配比、风味迷你条、品鉴语、二维码槽位、烫金边框、理性饮酒提示。

### 2. 样式 `TastingCardStyle`

- 比例 `CardRatio`：`.portrait`（朋友圈竖图 9:16）、`.square`（方图 1:1）。
- 底纹 `CardTexture`：`.inkGradient`、`.goldPinstripe`、`.spotlight`、`.goldRipple`。
- 预设：`.momentsPortrait`、`.square`。

### 3. 高清导出 `TastingCardRenderer`

```swift
let png: Data = try TastingCardRenderer.png(
    recipe: recipe, style: .momentsPortrait, deepLink: link, scale: 3
)
// 或渲染任意已注入二维码的卡片：
let png = try TastingCardRenderer.png(of: myCard, scale: 3)
```

`ImageRenderer` 离屏渲染 → `cgImage` → ImageIO 编码 PNG（不依赖 UIKit，跨平台）。默认 3x。

### 4. 系统分享 `ShareCardView`

```swift
ShareCardView(recipe: recipe, style: .momentsPortrait)          // 内置占位二维码
ShareCardView(recipe: recipe) { url in QRView(url) }            // 注入员工⑥ 二维码
```

内部渲染 PNG → 临时文件 → `ShareLink` 分享图片，并将 `yun://` 深链作为 `message` 带出。

### 5. 二维码槽位 `QRCodeSlot`

占位视图，显示将要编码的 `urlString`（`accessibilityValue` 也带该字符串，便于联调/测试）。员工⑥ 用同样的「URL → 二维码视图」签名替换即可。

## 深链规范（与员工⑥ 对齐）`DeepLinkBuilder`

| 类型 | 格式 |
| --- | --- |
| Custom scheme | `yun://recipe?c=<base64url(配方JSON)>` |
| Universal Link | `https://yun53.com/r/<recipe.id>` |

```swift
let url   = try DeepLinkBuilder.customSchemeURL(for: recipe) // yun://recipe?c=...
let ul    = DeepLinkBuilder.universalLink(for: recipe)       // https://yun53.com/r/<id>
let code  = try DeepLinkBuilder.encode(recipe)               // c 参数值
let back  = try DeepLinkBuilder.recipe(from: url)            // 还原配方
```

**对齐要点（请员工⑥ 同步）：**

1. `c` 使用 **base64url（无填充）**：标准 base64 的 `+ / =` 在 URL query 中易出错，故用 `-_` 替换 `+/` 并去掉 `=`。两端编解码必须一致。
2. 配方 JSON 编码时使用 `sortedKeys`，保证同一配方编码结果稳定（利于二维码缓存与测试）。
3. 二维码内容 = 上述 `customSchemeURL` 的 `absoluteString`（即卡片传入的 `deepLink`）。

## 预览

各文件提供 `PreviewProvider`（兼容命令行工具链与 Xcode 画布）：
`TastingCard_Previews`（竖版/方图/烫金斜纹三款）、`ShareCardView_Previews`、`QRCodeSlot_Previews`。

## 测试

`Tests/ShareCardTests`：深链格式/base64url/round-trip/错误分支，PNG 导出（魔数校验、比例、scale）。

```bash
swift test        # 需 XCTest（Xcode 或带 XCTest 的工具链）
```

> 注：仅装 Command Line Tools 的环境缺 XCTest，请在 Xcode/CI 中跑测试。

## 合规

卡片页脚固定展示「请理性饮酒 · 未成年人请勿饮酒」。本包不含任何售卖/支付入口。
