import XCTest
@testable import AICompanionCore

final class BartenderServiceTests: XCTestCase {

    // MARK: - 兜底：云端失败 → 本地

    /// 总是失败的云端推荐器。
    private struct FailingRemote: RecipeRecommending {
        func recommend(for query: BartenderQuery) async throws -> Recommendation {
            throw BartenderError.llmUnreachable("test")
        }
    }

    func testFallsBackToLocalWhenRemoteFails() async throws {
        var cfg = AICompanionConfig(
            llmMode: .serverProxy,
            endpoint: URL(string: "https://example.com/proxy"),
            allowCloudUpload: true,
            preferLocal: false
        )
        cfg.preferLocal = false
        let service = BartenderService(
            config: cfg,
            remoteFactory: { _ in FailingRemote() }
        )
        let rec = try await service.recommend(for: BartenderQuery(text: "酱香 8 度清爽"))
        // 云端失败 → 本地兜底
        XCTAssertEqual(rec.source, .localRules)
    }

    func testPreferLocalSkipsRemote() async throws {
        let service = BartenderService(
            config: .localOnly,
            remoteFactory: { _ in FailingRemote() } // 即便存在也不应被调用
        )
        let rec = try await service.recommend(for: BartenderQuery(text: "清香纯饮"))
        XCTAssertEqual(rec.source, .localRules)
    }

    // MARK: - 隐私同意闸门

    func testRequiresCloudConsentWhenNotYetAgreed() async {
        let cfg = AICompanionConfig(
            llmMode: .serverProxy,
            endpoint: URL(string: "https://example.com/proxy"),
            allowCloudUpload: false
        )
        let service = BartenderService(config: cfg)
        let requires = await service.requiresCloudConsent
        XCTAssertTrue(requires)
    }

    func testLocalOnlyNeedsNoConsent() async {
        let service = BartenderService(config: .localOnly)
        let requires = await service.requiresCloudConsent
        XCTAssertFalse(requires)
    }

    // MARK: - Engine 预览注入

    func testEnginePreviewRewritesRatio() async throws {
        let service = BartenderService(
            config: .localOnly,
            mixPreview: { _ in MixResult(addedML: 562, totalML: 662, standardUnits: 4.2) }
        )
        let rec = try await service.recommend(for: BartenderQuery(text: "酱香 8 度清爽"))
        XCTAssertTrue(rec.ratioSummary.contains("Engine 计算"))
        XCTAssertTrue(rec.ratioSummary.contains("662"))
    }

    // MARK: - LLM 解析（假传输，不打真实网络）

    private struct StubTransport: LLMTransport {
        let json: String
        func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
            let resp = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (Data(json.utf8), resp)
        }
    }

    func testLLMParsesPlainJSON() async throws {
        let json = """
        {"headline":"浓香微醺·加冰","aroma":"nongxiang","method":"ice",
         "targetABV":12,"baseABV":52,"ratioSummary":"1:3",
         "steps":["加冰"],"rationale":"理由","tastingNote":"窖香",
         "mellow":0.7,"strength":0.3,"confidence":0.95}
        """
        let cfg = AICompanionConfig(
            llmMode: .serverProxy,
            endpoint: URL(string: "https://example.com/proxy"),
            allowCloudUpload: true
        )
        let llm = LLMRecommender(config: cfg, transport: StubTransport(json: json))
        let rec = try await llm.recommend(for: BartenderQuery(text: "浓香加冰"))
        XCTAssertEqual(rec.source, .llm)
        XCTAssertEqual(rec.aroma, .nongxiang)
        XCTAssertEqual(rec.method, .ice)
        XCTAssertEqual(rec.recipe.targetABV, 12)
        XCTAssertEqual(rec.confidence, 0.95, accuracy: 0.001)
    }

    func testLLMParsesOpenAIStyleWrappedContent() async throws {
        let inner = "{\\\"headline\\\":\\\"清香\\\",\\\"aroma\\\":\\\"qingxiang\\\",\\\"method\\\":\\\"neat\\\",\\\"targetABV\\\":48,\\\"baseABV\\\":48,\\\"ratioSummary\\\":\\\"净饮\\\",\\\"steps\\\":[],\\\"rationale\\\":\\\"r\\\",\\\"tastingNote\\\":\\\"n\\\",\\\"mellow\\\":0.5,\\\"strength\\\":0.8}"
        let json = "{\"choices\":[{\"message\":{\"content\":\"\(inner)\"}}]}"
        let cfg = AICompanionConfig(
            llmMode: .serverProxy,
            endpoint: URL(string: "https://example.com/proxy"),
            allowCloudUpload: true
        )
        let llm = LLMRecommender(config: cfg, transport: StubTransport(json: json))
        let rec = try await llm.recommend(for: BartenderQuery(text: "清香纯饮"))
        XCTAssertEqual(rec.aroma, .qingxiang)
        XCTAssertEqual(rec.method, .neat)
    }

    func testLLMDisabledThrows() async {
        let llm = LLMRecommender(config: .localOnly, transport: StubTransport(json: "{}"))
        do {
            _ = try await llm.recommend(for: BartenderQuery(text: "x"))
            XCTFail("应抛 llmDisabled")
        } catch let e as BartenderError {
            XCTAssertEqual(e, .llmDisabled)
        } catch { XCTFail("类型不符") }
    }
}
