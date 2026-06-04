//
//  LLMRecommender.swift
//  AICompanionCore
//
//  大模型实现：通过「服务端代理」或「运行时注入令牌」调用 LLM。
//  🔐 绝不硬编码密钥。请求体只含本次诉求文本（隐私：调用方须已取得用户同意）。
//
//  模型被要求返回与 `LLMRecipeDTO` 对应的 JSON；解析后映射成标准 `Recipe`。
//  任何网络 / 解析失败都会抛错，交由 BartenderService 兜底本地。
//

import Foundation

/// 大模型返回的结构化配方（与提示词约定一致）。
struct LLMRecipeDTO: Decodable {
    var headline: String
    var aroma: String          // "qingxiang" / "jiangxiang" / "nongxiang"
    var method: String         // MixingMethod.rawValue
    var targetABV: Double
    var baseABV: Double
    var ratioSummary: String
    var steps: [String]
    var rationale: String
    var tastingNote: String
    var mellow: Double
    var strength: Double
    var confidence: Double?
}

/// 抽象底层传输，便于单测注入假数据（不打真实网络）。
public protocol LLMTransport: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, URLResponse)
}

struct URLSessionTransport: LLMTransport {
    let session: URLSession
    func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}

public struct LLMRecommender: RecipeRecommending {

    private let config: AICompanionConfig
    private let transport: LLMTransport
    private let baseVolumeML: Double

    public init(config: AICompanionConfig, baseVolumeML: Double = 100) {
        self.config = config
        let session = URLSession(configuration: .ephemeral)
        self.transport = URLSessionTransport(session: session)
        self.baseVolumeML = baseVolumeML
    }

    /// 测试 / 自定义传输用。
    init(config: AICompanionConfig, transport: LLMTransport, baseVolumeML: Double = 100) {
        self.config = config
        self.transport = transport
        self.baseVolumeML = baseVolumeML
    }

    public func recommend(for query: BartenderQuery) async throws -> Recommendation {
        guard config.llmMode != .disabled else { throw BartenderError.llmDisabled }
        guard let endpoint = config.endpoint else { throw BartenderError.notConfigured }
        let trimmed = query.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty || !query.fruitHints.isEmpty else { throw BartenderError.emptyQuery }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = config.requestTimeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // 直连模式：运行时注入 Bearer（不落代码）。代理模式：服务端持密钥，无需 header。
        if config.llmMode == .directWithInjectedToken {
            guard let token = config.bearerTokenProvider?(), !token.isEmpty else {
                throw BartenderError.notConfigured
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: requestPayload(query: query, trimmed: trimmed))

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await transport.send(request)
        } catch {
            throw BartenderError.llmUnreachable(error.localizedDescription)
        }

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw BartenderError.llmUnreachable("HTTP \(http.statusCode)")
        }

        let dto: LLMRecipeDTO
        do {
            dto = try Self.decodeDTO(from: data)
        } catch {
            throw BartenderError.llmBadResponse(error.localizedDescription)
        }

        return try map(dto: dto, query: query)
    }

    // MARK: - 请求体

    private func requestPayload(query: BartenderQuery, trimmed: String) -> [String: Any] {
        // 仅发送本次诉求所需信息；约定模型以 LLMRecipeDTO 结构回 JSON。
        [
            "model": config.modelName,
            "task": "yun_bartender_recipe",
            "locale": "zh-Hans",
            "schema": "LLMRecipeDTO",
            "userRequest": trimmed,
            "fruitHints": query.fruitHints,
            "aromaOptions": AromaType.allCases.map { $0.rawValue },
            "methodOptions": MixingMethod.allCases.map { $0.rawValue }
        ]
    }

    // MARK: - 解析（兼容裸 JSON 与 {recipe:{...}} / OpenAI 风格 content 包裹）

    static func decodeDTO(from data: Data) throws -> LLMRecipeDTO {
        let decoder = JSONDecoder()
        if let dto = try? decoder.decode(LLMRecipeDTO.self, from: data) {
            return dto
        }
        // 尝试从 {"recipe": {...}} 或 OpenAI-style choices[].message.content 文本中抽取 JSON。
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw BartenderError.llmBadResponse("非 JSON")
        }
        if let recipe = obj["recipe"] {
            let inner = try JSONSerialization.data(withJSONObject: recipe)
            return try decoder.decode(LLMRecipeDTO.self, from: inner)
        }
        if let content = extractContentString(obj),
           let jsonRange = content.range(of: "\\{[\\s\\S]*\\}", options: .regularExpression),
           let inner = String(content[jsonRange]).data(using: .utf8) {
            return try decoder.decode(LLMRecipeDTO.self, from: inner)
        }
        throw BartenderError.llmBadResponse("缺少 recipe 字段")
    }

    private static func extractContentString(_ obj: [String: Any]) -> String? {
        if let choices = obj["choices"] as? [[String: Any]],
           let message = choices.first?["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content
        }
        return obj["content"] as? String
    }

    // MARK: - 映射为标准 Recipe

    private func map(dto: LLMRecipeDTO, query: BartenderQuery) throws -> Recommendation {
        let aroma = AromaType(rawValue: dto.aroma) ?? .jiangxiang
        let method = MixingMethod(rawValue: dto.method) ?? .neat
        let base = dto.baseABV > 0 ? dto.baseABV : 53
        let target = min(max(dto.targetABV, 1), base)

        var components = [Component(volumeML: baseVolumeML, abv: base)]
        if let diluentABV = method.diluentABV {
            components.append(Component(volumeML: 0, abv: diluentABV))
        }

        let recipe = Recipe(
            name: dto.headline,
            aroma: aroma,
            components: components,
            targetABV: target,
            tastingNote: dto.tastingNote,
            flavor: FlavorProfile(
                mellow: min(1, max(0, dto.mellow)),
                strength: min(1, max(0, dto.strength))
            )
        )

        return Recommendation(
            headline: dto.headline,
            aroma: aroma,
            method: method,
            ratioSummary: dto.ratioSummary,
            steps: dto.steps,
            rationale: dto.rationale,
            recipe: recipe,
            source: .llm,
            confidence: min(1, max(0, dto.confidence ?? 0.9))
        )
    }
}
