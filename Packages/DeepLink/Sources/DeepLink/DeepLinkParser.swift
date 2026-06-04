//  DeepLinkParser.swift
//  DeepLink —— 深链 / Universal Link 解析（解码权威：员工⑥）
//
//  支持两种入口：
//    1. Custom scheme :  yun://recipe?c=<base64url 配方>
//    2. Universal Link:  https://yun53.com/r/<token>[?c=<base64url 配方>]
//
//  其中 Universal Link 的 <token>：
//    - 若能解码成自包含配方载荷 → 直接还原（离线，快闪店首选）。
//    - 否则当作「短 id」交回主工程 / 服务端查表还原（.needsLookup）。
//  优先级：query `c` > path token。两者都给时以 `c` 为准（显式覆盖）。

import Foundation
import Engine

/// 一次解析的结果。主工程据此决定：直接还原、查表、还是报错。
public enum DeepLinkResolution: Equatable, Sendable {
    /// 成功解出自包含配方，可立即还原 + 自动计算。
    case recipe(Recipe)
    /// 只拿到短 id，需主工程 / 服务端进一步还原（容错保底，不直接失败）。
    case needsLookup(id: String)
    /// 解析失败，附带可诊断的错误。
    case failed(DeepLinkError)
}

public enum DeepLinkParser {

    // MARK: 统一规范常量（与员工⑤ 共用）

    public static let customScheme = "yun"          // yun://
    public static let recipeAction = "recipe"        // yun://recipe
    public static let payloadKey = "c"               // ?c=<payload>
    public static let universalHost = "yun53.com"    // https://yun53.com
    public static let recipePathPrefix = "r"         // /r/<token>

    /// 备用 / 同源主机白名单（含 www. 与历史域名，体现容错）。
    public static let allowedHosts: Set<String> = [
        "yun53.com", "www.yun53.com"
    ]

    // MARK: 主入口

    /// 解析任意进入 App 的 URL。永不抛错——失败封装进 `.failed`，便于 UI 友好兜底。
    public static func resolve(_ url: URL) -> DeepLinkResolution {
        guard let scheme = url.scheme?.lowercased() else {
            return .failed(.unsupportedScheme("(无 scheme)"))
        }

        switch scheme {
        case customScheme:
            return resolveCustomScheme(url)
        case "https", "http": // http 也放行后跳 https，纯容错
            return resolveUniversalLink(url)
        default:
            return .failed(.unsupportedScheme(scheme))
        }
    }

    /// 快速判断该 URL 是否「可能」属于本包，供主工程在 onOpenURL 处分流。
    public static func canHandle(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased() else { return false }
        if scheme == customScheme { return true }
        if scheme == "https" || scheme == "http" {
            return allowedHosts.contains(url.host?.lowercased() ?? "")
        }
        return false
    }

    // MARK: - 内部

    private static func resolveCustomScheme(_ url: URL) -> DeepLinkResolution {
        // 期望 host == "recipe"，但对大小写 / 缺失做容错：只要能找到 c= 就还原。
        if let payload = queryValue(url, key: payloadKey) {
            return decodePayloadOrLookup(payload)
        }
        // 容错：yun://recipe/<payload> 这种把载荷放进 path 的写法也接。
        if let token = firstNonEmptyPathComponent(url) {
            return decodePayloadOrLookup(token)
        }
        return .failed(.missingRecipeToken)
    }

    private static func resolveUniversalLink(_ url: URL) -> DeepLinkResolution {
        let host = url.host?.lowercased() ?? ""
        guard allowedHosts.contains(host) else {
            return .failed(.unsupportedHost(host.isEmpty ? "(无主机)" : host))
        }
        // 显式 query 优先。
        if let payload = queryValue(url, key: payloadKey) {
            return decodePayloadOrLookup(payload)
        }
        // 取 /r/<token> 里的 token。
        let parts = url.pathComponents.filter { $0 != "/" && !$0.isEmpty }
        guard let idx = parts.firstIndex(where: { $0.lowercased() == recipePathPrefix }),
              idx + 1 < parts.count else {
            // 没有 /r/ 前缀但仍想容错：取最后一段当 token。
            if let last = parts.last { return decodePayloadOrLookup(last) }
            return .failed(.missingRecipeToken)
        }
        return decodePayloadOrLookup(parts[idx + 1])
    }

    /// 先尝试当自包含载荷解码；失败则把它当短 id 交回上层查表（容错保底）。
    private static func decodePayloadOrLookup(_ token: String) -> DeepLinkResolution {
        do {
            let recipe = try RecipeCodec.decode(payload: token)
            return .recipe(recipe)
        } catch {
            // 短而「干净」的 token 视为合法 id（交回主工程）；否则才算彻底失败。
            if looksLikeShortID(token) {
                return .needsLookup(id: token)
            }
            return .failed((error as? DeepLinkError) ?? .malformedBase64)
        }
    }

    // MARK: 小工具

    private static func queryValue(_ url: URL, key: String) -> String? {
        guard let comps = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        let value = comps.queryItems?.first { $0.name == key }?.value
        if let v = value, !v.trimmingCharacters(in: .whitespaces).isEmpty { return v }
        return nil
    }

    private static func firstNonEmptyPathComponent(_ url: URL) -> String? {
        url.pathComponents.first { $0 != "/" && !$0.isEmpty }
    }

    /// 短 id 的启发式判定：纯字母数字、长度 1...32（避免把畸形 base64 误判成 id）。
    private static func looksLikeShortID(_ token: String) -> Bool {
        guard (1...32).contains(token.count) else { return false }
        return token.allSatisfy { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
    }
}
