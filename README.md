# 微醺之度 · 53° 雲（YÚN）

高度白酒（清香 / 酱香 / 浓香）「度数调制 · 品鉴 · 溯源」一站式原生 iOS App。
调性：墨黑底 + 烫金描边 + 衬线中文标题，极简、奢华、克制。

> 本仓库由**员工①（地基 + 设计系统 + 上架，组长）**搭建。各功能包由对应同事在自己的 Package 内开发，最后由员工① 统一集成。

## 技术栈
Swift 5.9+ · SwiftUI · 最低 iOS 17 · MVVM · 本地 SPM 拆包 · Swift Charts · Canvas/ImageRenderer · SwiftData · URLSession+async/await · XCTest · SwiftLint。

## 快速开始
```bash
open YunApp/YunApp.xcodeproj      # 直接打开（已提交工程）；选 YunApp scheme → 任意 iOS 17 模拟器运行
# 或用 XcodeGen 重新生成工程：
#   brew install xcodegen && cd YunApp && xcodegen generate
make help                         # 查看常用命令
```
> · 已提交的 `YunApp.xcodeproj` 采用 Xcode 16 的「文件系统同步分组」格式，需 **Xcode 16+** 打开；
>   若使用 Xcode 15，请改用 `cd YunApp && xcodegen generate` 生成兼容工程。
> · 本机若仅装「Command Line Tools」而无完整 Xcode，可用 `swift build` 编译纯逻辑包，但无法编译 iOS App 与运行模拟器 / XCTest。

## 工程结构
```
YunApp/                      App 主工程（员工①）
  YunApp.xcodeproj           已提交，可直接打开
  project.yml                XcodeGen 规格（可选，避免 pbxproj 合并冲突）
  YunApp/                    App 源码（年龄门 / TabBar / 我的 / 资源）
Packages/
  DesignSystem/   员工①   设计系统：颜色/字体/组件 + 模块入口协议 YunModule
  Engine/         员工②   纯计算引擎 + 共享数据模型（全员引用）
  Mixing/         员工③   单位换算 / 冰融 / 酒精单位
  Recipes/        员工④   配方菜单 + 风味雷达
  ShareCard/      员工⑤   品鉴卡导出 + 分享
  DeepLink/       员工⑥   二维码 + 深链点单（含统一 DeepLinkRouter）
  Health/         员工⑦   BAC 微醺曲线
  Cellar/         员工⑧   会员 / 我的酒柜
  Authenticity/   员工⑨   防伪溯源验真
  AICompanion/    员工⑩   AI 调酒师
```

## TabBar 五入口
调制（Mixing）· 配方（Recipes）· 我的酒柜（Cellar）· 验真（Authenticity）· 我的（主工程页，聚合 Health / AICompanion / ShareCard / DeepLink 入口与合规说明）。

## 共享数据契约（`Engine` 包定义，全员引用）
`AromaType` · `Component` · `MixResult` · `Recipe` · `FlavorProfile`。详见 `Packages/Engine/README.md`。**禁止各自重造。**

## 模块入口约定（`DesignSystem.YunModule`）
每个功能包暴露一个遵循 `YunModule` 的类型，提供 `tab`（标题+SF Symbol）与 `rootView() -> AnyView`。
主工程仅依赖此协议拼装入口，**各模块完成后零改动即可集成**——把占位 `XXHomeView` 换成真实根视图即可。

## 深链统一规范（员工⑤⑥ 共用，已在 `DeepLink` 包实现接口）
- Custom scheme：`yun://recipe?c=<base64(配方JSON)>`（已实现编解码与还原）
- Universal Link：`https://yun53.com/r/<id>`（解析出 id，按 id 取配方留给员工⑥）
- App 已接 `onOpenURL` → `DeepLinkRouter().resolve(url)` → `AppState`。
- Universal Link 需在 `yun53.com` 部署 `apple-app-site-association`，并保留 `YunApp.entitlements` 的 `applinks:yun53.com`。

## 合规红线（上架关键，全员遵守）
- 年龄分级 **17+**（频繁/强烈酒精内容）。
- 启动**年龄确认门**：未确认年满 18 不可进入（`AppStorage("yun.ageVerified")`，已实现）。
- 全程「请理性饮酒 / 未成年人请勿饮酒」（`ResponsibleDrinkingBanner`），禁止任何鼓励过量饮酒措辞。
- **不在 App 内完成酒类售卖交易**。
- 隐私：默认本地处理优先；任何上传（健康/AI）必须在 `PrivacyInfo.xcprivacy` 声明。

## 交付要求
各包内 MVVM 开发，对外只暴露清晰 `public` 接口与 SwiftUI View；提交前自测通过 + 写好 README；核心逻辑必须有 XCTest。

## 上架收尾清单（员工① 最后阶段）
- [ ] 注册 Apple Developer，App Store Connect 建 App，填 Bundle ID `com.yun53.weixundu`
- [ ] 设置 DEVELOPMENT_TEAM、自动签名；开启 Associated Domains capability
- [ ] 替换占位 App 图标 / 启动 Logo 为正式视觉资产
- [ ] 安装并注册思源宋体 / Cormorant Garamond（见 DesignSystem/README）
- [ ] 年龄分级问卷选 17+（频繁/强烈酒精）
- [ ] 完成 `PrivacyInfo.xcprivacy` 数据收集声明 + App 隐私「营养标签」
- [ ] 截图（6.7" / 6.5" / iPad）+ 预览
- [ ] TestFlight 内测 → 提交审核
