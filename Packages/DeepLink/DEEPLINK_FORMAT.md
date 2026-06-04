# 深链编码 / 解码格式规范 v1

> 维护者：员工⑥（DeepLink，**解码权威**） · 共用方：员工⑤（ShareCard）
> 任何对本格式的破坏性改动，必须由员工⑥ 评审并同步升级 `formatVersion`。

二维码 / 分享链接里流通的「配方载荷」一旦印刷或转发就无法收回，因此**格式向后兼容是硬约束**：
新增字段一律可选解码，绝不重命名 / 删除既有字段。

---

## 1. 两种入口

| 形态 | 模板 | 用途 |
|------|------|------|
| Custom Scheme | `yun://recipe?c=<payload>` | App 已安装时的最快路径 |
| Universal Link | `https://yun53.com/r/<token>` | 未装 App 可落网页引导；自包含可离线还原 |

两者都还原同一个 `Recipe`，打开后由主工程（员工①）「还原 + 自动计算」。

## 2. 载荷（payload / token）编码

```
payload = base64url( UTF8( JSON(Recipe) ) )
```

- **JSON**：由 Engine 的 `Codable` 契约产生。
  - key = 属性名（不自定义 CodingKeys 重命名）。
  - `AromaType` 以 String rawValue 序列化：`"qingxiang" | "jiangxiang" | "nongxiang"`。
  - 编码时使用 `.sortedKeys` → **同一配方恒定生成同一载荷**（利于二维码缓存 / 比对 / 去重）。
- **base64url**：RFC 4648 §5。`+`→`-`、`/`→`_`、去掉结尾 `=` 填充。
  - 选 base64url 而非标准 base64：避免 `+ / =` 在 URL（query / path）里被百分号转义、被 IM / 排版软件二次破坏。

### Universal Link 的 `<token>` 语义

`<token>` 优先按「自包含载荷」解码；解不出且形如短 id（纯字母数字 `- _`，长度 1–32）时，
判为 `needsLookup(id:)`，交主工程 / 服务端查表还原（容错保底，不直接报错）。
若同时给了 query `c=`，**以 `c=` 为准**（显式覆盖 path）。

## 3. 解码容错（员工⑥ 的承诺）

`RecipeCodec.decode(payload:)` 接受以下「脏」输入并仍能还原：

| 情况 | 处理 |
|------|------|
| 标准 base64（含 `+ / =`） | 自动转 base64url 后解码 |
| 缺失 `=` 填充 | 自动补齐到 4 的倍数 |
| 整段被再次百分号编码 | 先 `removingPercentEncoding` |
| 含换行 / 空格（长串被折行） | 解码前剔除空白 |
| 首尾空白 | trim |

失败时抛 `DeepLinkError`（`emptyPayload` / `malformedBase64` / `invalidJSON`），便于 UI 友好提示。

## 4. 给员工⑤（ShareCard）的对接约定

- **只调用 `RecipeCodec` 的出口**生成链接，不要自己拼 URL / base64：
  - `RecipeCodec.customSchemeURL(for:)`
  - `RecipeCodec.universalLinkURL(for:)`
- 品鉴卡里嵌二维码请直接用 `GildedQRCodeView(recipe:)`（已内置 H 级纠错 + 静区 + 烫金）。
- 如需自定义文案二维码：`GildedQRCodeView(content:side:caption:)`。

## 5. 版本与演进

- 当前 `RecipeCodec.formatVersion = 1`。
- 不兼容升级时：在 query 增加 `v=2`，或更换 path 前缀（如 `/r2/`），解码端按版本分流；
  旧二维码（v1，无版本标记）必须继续可解。
