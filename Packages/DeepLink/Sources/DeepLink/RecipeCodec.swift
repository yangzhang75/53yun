//  RecipeCodec.swift
//  DeepLink —— 配方 ⇄ 深链载荷 编解码（解码权威：员工⑥）
//
//  载荷格式（v1）：
//    payload = base64url( utf8( JSON(Recipe) ) )
//  - JSON 由 Engine 的 Codable 契约产生（属性名作 key、AromaType 为 String）。
//  - base64url：RFC 4648 §5，`+`→`-`、`/`→`_`、去掉结尾 `=` 填充。
//    选 base64url 是因为载荷要塞进 URL（query / path），标准 base64 的 `+ / =`
//    在 URL 里需百分号转义，易被第三方扫码器 / IM 二次破坏。
//  - 解码端做**容错**：base64url 与标准 base64 都吃；自动补 `=` 填充；
//    先尝试百分号解码；忽略首尾空白。详见 `decode(payload:)`。

import Foundation
import Engine

/// 编解码 / 解析过程中可能出现的错误（用于容错与诊断）。
public enum DeepLinkError: Error, Equatable, CustomStringConvertible, Sendable {
    case emptyPayload                 // 没有载荷
    case malformedBase64              // base64(url) 无法解码成字节
    case invalidJSON(String)          // 字节不是合法的 Recipe JSON
    case unsupportedScheme(String)    // 既不是 yun:// 也不是受支持的 https 主机
    case unsupportedHost(String)      // https 但主机不在白名单
    case missingRecipeToken           // URL 结构合法但找不到配方载荷 / id

    public var description: String {
        switch self {
        case .emptyPayload: return "深链载荷为空"
        case .malformedBase64: return "载荷不是合法的 base64/base64url"
        case .invalidJSON(let detail): return "配方 JSON 解析失败：\(detail)"
        case .unsupportedScheme(let s): return "不支持的 scheme：\(s)"
        case .unsupportedHost(let h): return "不支持的主机：\(h)"
        case .missingRecipeToken: return "URL 中找不到配方载荷或 id"
        }
    }
}

public enum RecipeCodec {

    /// 当前载荷格式版本。预留给未来不兼容升级（届时可在 query 加 `v=` 或换路径前缀）。
    public static let formatVersion = 1

    // MARK: - Encode

    /// 将配方编码为 base64url 载荷字符串（不含 scheme / host）。
    public static func encode(_ recipe: Recipe) throws -> String {
        let encoder = JSONEncoder()
        // 稳定、紧凑：固定 key 顺序让同一配方生成同一二维码（利于缓存 / 比对）。
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let json = try encoder.encode(recipe)
        return Base64URL.encode(json)
    }

    // MARK: - Decode

    /// 容错解码：把载荷字符串还原成 Recipe。
    /// 接受 base64url、标准 base64、缺失填充、外层百分号转义、首尾空白等多种「脏」输入。
    public static func decode(payload rawInput: String) throws -> Recipe {
        let trimmed = rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw DeepLinkError.emptyPayload }

        // 容错①：有些渠道会对整段载荷再做一次百分号编码。
        let candidate = trimmed.removingPercentEncoding ?? trimmed

        guard let data = Base64URL.decodeTolerant(candidate) else {
            throw DeepLinkError.malformedBase64
        }

        do {
            return try JSONDecoder().decode(Recipe.self, from: data)
        } catch {
            throw DeepLinkError.invalidJSON(String(describing: error))
        }
    }

    // MARK: - URL builders（与员工⑤ 共用的统一出口）

    /// Custom scheme：`yun://recipe?c=<payload>`
    public static func customSchemeURL(for recipe: Recipe) throws -> URL {
        let payload = try encode(recipe)
        var comps = URLComponents()
        comps.scheme = DeepLinkParser.customScheme
        comps.host = DeepLinkParser.recipeAction
        comps.queryItems = [URLQueryItem(name: DeepLinkParser.payloadKey, value: payload)]
        guard let url = comps.url else { throw DeepLinkError.missingRecipeToken }
        return url
    }

    /// Universal Link：`https://yun53.com/r/<payload>`
    /// 自包含（离线可还原），适合快闪店 / 桌牌，无需服务端查表。
    public static func universalLinkURL(for recipe: Recipe) throws -> URL {
        let payload = try encode(recipe)
        var comps = URLComponents()
        comps.scheme = "https"
        comps.host = DeepLinkParser.universalHost
        comps.path = "/\(DeepLinkParser.recipePathPrefix)/\(payload)"
        guard let url = comps.url else { throw DeepLinkError.missingRecipeToken }
        return url
    }
}

// MARK: - Base64URL helper

/// RFC 4648 §5 base64url，附带对标准 base64 / 缺填充的容错解码。
enum Base64URL {

    static func encode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    /// 宽松解码：同时接受 base64url 与标准 base64，自动补齐 `=` 填充。
    static func decodeTolerant(_ string: String) -> Data? {
        var s = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        // 去掉所有空白（换行、空格——二维码长串被排版软件折行时常见）。
        s.removeAll { $0 == " " || $0 == "\n" || $0 == "\r" || $0 == "\t" }
        // 补齐到 4 的倍数。
        let remainder = s.count % 4
        if remainder > 0 {
            s.append(String(repeating: "=", count: 4 - remainder))
        }
        return Data(base64Encoded: s)
    }
}
