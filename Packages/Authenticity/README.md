# Authenticity — 防伪溯源 / 扫码验真（员工⑨）

高端白酒最大痛点是「真假」。本包提供 **扫码 / 手输防伪码 → 调用验真接口 → 展示真伪结果与溯源时间线** 的完整、独立流程。

- 语言 Swift 5.9+ / SwiftUI / iOS 17+，架构 MVVM。
- 网络层 `URLSession` + `async/await`，**接口与数据模型解耦**，后端就绪即可平滑接入。
- 独立流程，**不依赖计算模块**（Engine / Mixing 等）。
- 调性：墨黑底 + 烫金描边 + 衬线标题 + 克制微动效。

---

## 一、快速接入（员工① 集成用）

```swift
import Authenticity

// 开发 / 预览：使用 Mock 服务
AuthenticityView(viewModel: .init(service: MockAuthenticityService()))

// 上线：接入真实后端，UI 零改动
let endpoint = AuthenticityEndpoint(
    baseURL: URL(string: "https://api.yun53.com")!,
    authorization: "Bearer <token>",   // 可选
    appKey: "<app-key>"                // 可选
)
AuthenticityView(viewModel: .init(service: RemoteAuthenticityService(endpoint: endpoint)))
```

`AuthenticityView` 是唯一对外顶层 View，内部自带「输入 → 验真中 → 成功/失败」全部状态路由。

### 相机权限文案（隐私合规，务必在主工程 Info.plist 配置）

```xml
<key>NSCameraUsageDescription</key>
<string>「微醺之度」需要使用相机扫描瓶身防伪码，以验证您所购雲酒的真伪与溯源信息。我们不会拍照存储或上传任何图像，扫码全程在本机完成。</string>
```

> 本包对「未授权 / 已拒绝 / 设备不可用」均有清晰兜底界面，未授权时不会强行调起相机，并引导用户改用手动输入或前往「设置」。

---

## 二、对外 public 接口

### 顶层 View
| 类型 | 说明 |
| --- | --- |
| `AuthenticityView` | 验真主入口（扫码 + 手输 + 结果路由） |
| `VerificationResultView` | 验真成功展示（批次/年份/香型/酒厂故事 + 溯源时间线） |
| `VerificationFailureView` | 验真失败 / 防伪提示（仿冒 / 未收录 / 系统错误） |
| `TraceTimelineView` | 溯源时间线（酿造 → 封坛 → 出厂） |
| `CodeScannerView` | 相机扫码（iOS，AVFoundation） |

### 网络与抽象
| 类型 | 说明 |
| --- | --- |
| `AuthenticityProviding` | 验真服务协议（UI 只依赖它） |
| `MockAuthenticityService` | Mock 实现，内置示例数据 |
| `RemoteAuthenticityService` | `URLSession` async/await 真实实现 |
| `AuthenticityEndpoint` | 后端地址 / 鉴权 / appKey 配置 |
| `AuthenticityError` | 已本地化的错误枚举 |
| `AuthCodeValidator` | 防伪码本地预校验（规范化 + 格式） |

### 数据模型（Codable，对应后端协议）
`VerificationResult` · `AuthProduct` · `TraceStep` · `VerificationStatus` · `AuthAroma` · `VerificationChannel` · `VerificationRequest`

### ViewModel
`AuthenticityViewModel`（`@MainActor @Observable`）—— 管理输入态 / 加载态 / 结果态 / 错误态。

---

## 三、接口文档（后端协议）

### 验真

```
POST {baseURL}/v1/authenticity/verify
Content-Type: application/json
Authorization: <可选，如 Bearer token>
X-Yun-App-Key: <可选>
```

**请求体**

```json
{ "code": "YUN2018JX0427A", "channel": "scan" }
```

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `code` | string | 规范化后的防伪码（已去空格/连字符、转大写） |
| `channel` | string | `scan`（扫码）/ `manual`（手输），供后端风控 |

**响应 200**

```json
{
  "status": "authentic",
  "code": "YUN2018JX0427A",
  "product": {
    "name": "53° 雲 · 酱香典藏",
    "batch": "JX-20180917-0427",
    "vintage": 2018,
    "aroma": "jiangxiang",
    "abv": 53,
    "net_volume_ml": 500,
    "distillery": "赤水河畔 · 雲酒坊",
    "story": "……"
  },
  "trace": [
    { "stage": "酿造", "title": "端午制曲 · 重阳下沙", "date": "2018-09-17", "location": "赤水河谷", "detail": "……" },
    { "stage": "封坛", "title": "陶坛入库 · 洞藏陈放", "date": "2019-04-02", "location": "雲酒坊地下酒库", "detail": "……" },
    { "stage": "出厂", "title": "勾调灌装 · 验真出厂", "date": "2023-11-20", "location": "灌装中心", "detail": "……" }
  ],
  "scan_count": 1,
  "first_scanned_at": "2026-06-03 20:14",
  "verified_at": "2026-06-03 20:14"
}
```

#### `status` 取值

| 值 | 含义 | 客户端表现 |
| --- | --- | --- |
| `authentic` | 正品 | 成功页 + 完整溯源 |
| `counterfeit` | 仿冒 | 红色防伪警示 + 自查指引 |
| `unknown` | 系统未收录该码 | 橙色提示 + 自查指引 |
| `already_scanned` | 已被多次验证 | 成功页 + 二次流通预警 |

#### 字段约定
- `product` 仅在 `authentic` / `already_scanned` 时存在。
- `trace[*].stage` 约定为「酿造 / 封坛 / 出厂」，但 UI 不写死，按数组顺序渲染。
- `trace[*].id` 后端可不下发，客户端自动生成稳定 id。
- 日期 / 时间为**展示用字符串**（后端已格式化，客户端不做时区换算）。
- `aroma` 未知值（后端新增香型）客户端兜底为 `unknown`，不会导致整体解析失败。

#### 错误（非 2xx）映射 `AuthenticityError`
| 情况 | 错误 |
| --- | --- |
| 输入为空 | `.emptyCode` |
| 本地格式校验未过 | `.malformedCode` |
| 网络异常 | `.network(描述)` |
| 服务端非 2xx | `.server(status:)` |
| 响应解析失败 | `.decoding` |
| 请求取消 | `.cancelled` |

---

## 四、示例码（验收用，Mock 服务内置）

| 防伪码 | 结果 |
| --- | --- |
| `YUN2018JX0427A` | 正品 · 酱香典藏（含完整「酿造→封坛→出厂」时间线） |
| `YUN2021QX1187C` | 正品 · 清香原浆 |
| `FAKE000000000000` | 仿冒（明确防伪提示） |
| `YUN9999RESCAN001` | 已被多次验证（二次流通预警） |
| 其它合法格式码 | 系统未收录（`unknown`） |

> 防伪码本地规则：规范化（去空格/连字符、转大写）后为 12–24 位 `A–Z`/`0–9`。本地校验仅挡明显错误，**真伪以服务端为准**。

---

## 五、Preview

各 View 均带 SwiftUI `#Preview`（Xcode 中打开对应文件即可预览，已按 `#if os(iOS)` 隔离）：
- `AuthenticityView` — 验真入口
- `VerificationResultView` — 验真成功 · 酱香 / 已多次扫描
- `VerificationFailureView` — 仿冒 / 未收录 / 网络错误
- `TraceTimelineView` — 溯源时间线

---

## 六、测试

`Tests/AuthenticityTests` 覆盖：防伪码校验、Mock 各状态分支、错误抛出、后端 JSON 解析契约（含 snake_case 映射与未知枚举兜底）、请求编码、ViewModel 状态流转。

```bash
swift test          # 需 Xcode 工具链（XCTest）
```

> 说明：纯命令行 `CommandLineTools` 不含 `XCTest`，需在 Xcode / CI（含完整 Xcode）下运行。包本身 `swift build` 在命令行即可通过（相机相关代码以 `#if os(iOS)` 隔离）。

---

## 七、集成边界与 DesignSystem 衔接
- 本包内置最小暗金主题 `AuthTheme`（颜色 / 衬线字体 / 卡片样式），使包可**独立编译与预览**。
- 接入 `DesignSystem`（员工①）后，建议将 `AuthTheme` 收敛为对 DesignSystem token 的转发，所有 View 通过 `AuthTheme` 取值，故切换零侵入。
- 衬线标题当前以系统 `.serif` 兜底；DesignSystem 注册「思源宋体」后，将 `AuthTheme.serifFontName` 设为其 PostScript 名即可全局生效。

## 合规
全程展示「请理性饮酒 · 未成年人请勿饮酒」。本包不涉及任何酒类售卖交易。
