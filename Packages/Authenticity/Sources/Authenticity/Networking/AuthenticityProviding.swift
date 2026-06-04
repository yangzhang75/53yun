import Foundation

// MARK: - 验真服务抽象
//
// UI / ViewModel 只依赖 `AuthenticityProviding` 协议，不关心具体实现。
// - 开发期注入 `MockAuthenticityService`。
// - 后端就绪后注入 `RemoteAuthenticityService`，无需改动上层代码。

/// 验真服务统一接口。
public protocol AuthenticityProviding: Sendable {
    /// 校验防伪码并返回结果。
    /// - Parameters:
    ///   - code: 瓶身防伪码（扫码或手输）。
    ///   - channel: 来源渠道（扫码 / 手输），用于后端风控统计。
    /// - Throws: `AuthenticityError`
    func verify(code: String, channel: VerificationChannel) async throws -> VerificationResult
}

// MARK: 错误

/// 验真过程中可能出现的错误（已本地化，可直接展示）。
public enum AuthenticityError: LocalizedError, Sendable, Equatable {
    case emptyCode                 // 未输入防伪码
    case malformedCode             // 防伪码格式不合法（本地预校验未通过）
    case network(String)           // 网络层错误
    case server(status: Int)       // 服务端非 2xx
    case decoding                  // 响应解析失败
    case cancelled                 // 请求被取消

    public var errorDescription: String? {
        switch self {
        case .emptyCode:
            return "请输入或扫描瓶身防伪码"
        case .malformedCode:
            return "防伪码格式不正确，请核对后重试"
        case .network(let msg):
            return "网络连接异常：\(msg)"
        case .server(let status):
            return "验真服务暂时不可用（\(status)），请稍后再试"
        case .decoding:
            return "验真结果解析失败，请稍后再试"
        case .cancelled:
            return "验真已取消"
        }
    }
}

// MARK: 防伪码本地预校验

/// 防伪码格式工具：在发起网络请求前做一次廉价的本地校验，过滤明显非法输入。
public enum AuthCodeValidator {
    /// 规范化：去空格、转大写。
    public static func normalize(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .uppercased()
    }

    /// 是否为合法的防伪码（规范：12~24 位，字母 + 数字）。
    /// 注意：本地校验只挡明显错误，真伪以服务端为准。
    public static func isValid(_ raw: String) -> Bool {
        let code = normalize(raw)
        guard (12...24).contains(code.count) else { return false }
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
        return code.unicodeScalars.allSatisfy { allowed.contains($0) }
    }
}
