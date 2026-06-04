# DeepLink 包（员工⑥）

> 二维码 + 深链点单。负责**扫码闭环**：生成烫金二维码、解析深链 / Universal Link 还原配方。
> 调性：墨黑底 + 烫金 + 衬线。依赖 `Engine` 的 `Recipe` 契约。

## 职责边界

- ✅ 生成烫金二维码（CoreImage `CIQRCodeGenerator`，H 级纠错）。
- ✅ 解析 `yun://recipe?c=...` 与 `https://yun53.com/r/<id>`，解码出 `Recipe`，**含容错**。
- ✅ 提供「扫码点单」桌牌展示页样式。
- ✅ 编解码格式权威，见 [`DEEPLINK_FORMAT.md`](./DEEPLINK_FORMAT.md)（与员工⑤ 共用）。
- ❌ **不**做 URL 还原后的页面路由 —— 那是员工① 的事；本包只通过回调把 `Recipe` 交出去。
- ❌ 不直接依赖任何 UI 包（DesignSystem 字体在集成时注入即可）。

## 公开接口

### 1. 编解码 — `RecipeCodec`
```swift
RecipeCodec.encode(_ recipe: Recipe) throws -> String          // base64url 载荷
RecipeCodec.decode(payload: String) throws -> Recipe           // 容错解码（解码权威）
RecipeCodec.customSchemeURL(for: Recipe) throws -> URL         // yun://recipe?c=...
RecipeCodec.universalLinkURL(for: Recipe) throws -> URL        // https://yun53.com/r/...
```

### 2. 解析 — `DeepLinkParser`
```swift
DeepLinkParser.resolve(_ url: URL) -> DeepLinkResolution       // 永不抛错
DeepLinkParser.canHandle(_ url: URL) -> Bool                   // onOpenURL 分流用

enum DeepLinkResolution {
    case recipe(Recipe)          // 自包含 → 立即还原 + 自动计算
    case needsLookup(id: String) // 仅短 id → 主工程/服务端查表
    case failed(DeepLinkError)   // 解析失败（含诊断）
}
```

### 3. 路由回调 — `DeepLinkRouter`（交给员工①）
```swift
@StateObject var router = DeepLinkRouter(
    onRecipe:      { recipe in appModel.restore(recipe) },      // 还原 + 自动计算
    onNeedsLookup: { id in appModel.fetchRecipe(id: id) },      // 查表还原
    onFailure:     { err in appModel.toast("无法识别：\(err)") }
)
// 在主工程根视图：
.onOpenURL { router.handle($0) }
```

### 4. SwiftUI 组件
```swift
GildedQRCodeView(recipe: Recipe)                               // 供员工⑤ 品鉴卡嵌入
GildedQRCodeView(content: String, side:, caption:)             // 任意文案二维码
ScanToOrderView(recipe: Recipe, storeName:)                    // 快闪店/酒吧桌牌展示页
GildedQRCode.cgImage(for: Recipe, size:) -> CGImage?           // 想自取图片时
```
两个 View 均带 `#Preview`。

## 主工程集成清单（员工①）

1. **注册 Custom Scheme**：`Info.plist` → `CFBundleURLTypes` 加 `yun`。
2. **配置 Universal Link**：Associated Domains 加 `applinks:yun53.com`，
   并在 `https://yun53.com/.well-known/apple-app-site-association` 配 `/r/*` 路径。
3. 在根视图 `.onOpenURL { router.handle($0) }`，把回调接到还原 + 自动计算流程。

## 合规

- 桌牌页 `ScanToOrderView` 内置「请理性饮酒 · 未成年人请勿饮酒 · 适龄 17+」固定提示。
- 本包不涉及任何售卖 / 支付逻辑。

## 验收自测

XCTest 套件位于 `Tests/DeepLinkTests/`（round-trip、两种 URL、容错、错误分支、QR 生成）。

> ⚠️ 本机仅装了 Command Line Tools（无完整 Xcode），缺 `XCTest` 与 `#Preview` 宏插件，
> 故 `swift test` 与含 Preview 的 `swift build` 需在 **Xcode / 带 Xcode 的 toolchain** 下执行。
> 开发期已用独立运行时 harness 验证全部逻辑（含「生成的二维码经 `CIDetector` 反扫
> → 还原出原配方」端到端闭环），16/16 通过。

## 依赖说明

`Engine`（员工②）通过 SPM 路径依赖引入。Engine 落地前，本仓 `Packages/Engine`
仅含**最小共享契约骨架**（见该文件顶部归属说明），由员工② 正式实现时按契约扩展。
