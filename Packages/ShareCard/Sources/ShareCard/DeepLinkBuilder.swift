import Foundation
import Engine

/// 深链生成 / 解析（员工⑤⑥ 共用契约）。
///
/// 统一规范：
/// - Custom scheme:  `yun://recipe?c=<base64配方JSON>`
/// - Universal Link: `https://yun53.com/r/<id>`
/// - 打开后还原配方并自动计算。
///
/// 编码细节（与员工⑥ 对齐）：
/// - `c` = **base64url(无填充)** 编码后的配方 JSON。
///   选用 base64url 而非标准 base64，是因为标准 base64 的 `+ / =` 在 URL query 中需转义、易出错；
///   base64url 用 `-_` 替换 `+/` 并去掉 `=`，可安全直放 query。两端必须一致。
/// - JSON 使用 `sortedKeys`，保证同一配方编码结果稳定（利于二维码缓存与测试）。
public enum DeepLinkBuilder {

    // MARK: - 常量（与员工⑥ 对齐）

    public static let scheme = "yun"
    public static let recipeHost = "recipe"
    public static let codeQueryItem = "c"
    public static let universalLinkBase = "https://yun53.com/r/"

    // MARK: - 编码

    /// 将配方编码为 `c` 参数的字符串值（base64url，无填充）。
    public static func encode(_ recipe: Recipe) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(recipe)
        return base64urlEncode(data)
    }

    /// 生成 Custom scheme 深链：`yun://recipe?c=<...>`
    public static func customSchemeURL(for recipe: Recipe) throws -> URL {
        let code = try encode(recipe)
        var components = URLComponents()
        components.scheme = scheme
        components.host = recipeHost
        components.queryItems = [URLQueryItem(name: codeQueryItem, value: code)]
        guard let url = components.url else {
            throw DeepLinkError.malformedURL
        }
        return url
    }

    /// 生成 Universal Link：`https://yun53.com/r/<id>`
    /// 仅承载配方 id，服务端 / App 据此拉取或还原配方。
    public static func universalLink(for recipe: Recipe) -> URL? {
        URL(string: universalLinkBase + recipe.id.uuidString)
    }

    // MARK: - 解析（供员工⑥ / 主工程还原配方时复用）

    /// 从 `c` 参数还原配方。
    public static func decode(code: String) throws -> Recipe {
        guard let data = base64urlDecode(code) else {
            throw DeepLinkError.invalidBase64
        }
        return try JSONDecoder().decode(Recipe.self, from: data)
    }

    /// 从任意深链 URL 还原配方（仅支持 custom scheme 内嵌的 `c`）。
    public static func recipe(from url: URL) throws -> Recipe {
        guard url.scheme == scheme, url.host == recipeHost else {
            throw DeepLinkError.unsupportedURL
        }
        let comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
        guard let code = comps?.queryItems?.first(where: { $0.name == codeQueryItem })?.value else {
            throw DeepLinkError.missingCode
        }
        return try decode(code: code)
    }

    // MARK: - base64url

    static func base64urlEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    static func base64urlDecode(_ string: String) -> Data? {
        var s = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        // 补回填充
        let remainder = s.count % 4
        if remainder > 0 {
            s.append(String(repeating: "=", count: 4 - remainder))
        }
        return Data(base64Encoded: s)
    }
}

public enum DeepLinkError: Error, Equatable {
    case malformedURL
    case invalidBase64
    case unsupportedURL
    case missingCode
}
