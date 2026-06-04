import Foundation

// MARK: - 真实验真服务（URLSession + async/await）
//
// 预留真实 API 协议（详见 README）。后端就绪后直接注入即可，无需改 UI。
//   POST {baseURL}/v1/authenticity/verify
//   Body: VerificationRequest (JSON)
//   200 : VerificationResult (JSON)
//   4xx/5xx: AuthenticityError.server

/// 后端环境配置。
public struct AuthenticityEndpoint: Sendable {
    public let baseURL: URL
    /// 可选的鉴权头（如 "Bearer xxx"）。
    public let authorization: String?
    /// 应用渠道标识，便于后端区分客户端来源。
    public let appKey: String?

    public init(baseURL: URL, authorization: String? = nil, appKey: String? = nil) {
        self.baseURL = baseURL
        self.authorization = authorization
        self.appKey = appKey
    }

    /// 示例：生产环境地址。
    public static let production = AuthenticityEndpoint(
        baseURL: URL(string: "https://api.yun53.com")!
    )
}

/// 基于 URLSession 的验真服务实现。
public struct RemoteAuthenticityService: AuthenticityProviding {
    private let endpoint: AuthenticityEndpoint
    private let session: URLSession

    public init(endpoint: AuthenticityEndpoint, session: URLSession = .shared) {
        self.endpoint = endpoint
        self.session = session
    }

    public func verify(code: String, channel: VerificationChannel) async throws -> VerificationResult {
        let normalized = AuthCodeValidator.normalize(code)
        guard !normalized.isEmpty else { throw AuthenticityError.emptyCode }
        guard AuthCodeValidator.isValid(normalized) else { throw AuthenticityError.malformedCode }

        var request = URLRequest(url: endpoint.baseURL.appendingPathComponent("/v1/authenticity/verify"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let auth = endpoint.authorization {
            request.setValue(auth, forHTTPHeaderField: "Authorization")
        }
        if let appKey = endpoint.appKey {
            request.setValue(appKey, forHTTPHeaderField: "X-Yun-App-Key")
        }

        do {
            request.httpBody = try JSONEncoder().encode(
                VerificationRequest(code: normalized, channel: channel)
            )
        } catch {
            throw AuthenticityError.decoding
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch is CancellationError {
            throw AuthenticityError.cancelled
        } catch let urlError as URLError where urlError.code == .cancelled {
            throw AuthenticityError.cancelled
        } catch {
            throw AuthenticityError.network(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw AuthenticityError.network("无效的响应")
        }
        guard (200..<300).contains(http.statusCode) else {
            throw AuthenticityError.server(status: http.statusCode)
        }

        do {
            return try JSONDecoder().decode(VerificationResult.self, from: data)
        } catch {
            throw AuthenticityError.decoding
        }
    }
}
