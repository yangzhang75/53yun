//
//  BartenderService.swift
//  AICompanionCore
//
//  对外门面：编排「云端优先 + 本地兜底」，并接入 Engine 的精确兑制预览。
//
//  - 隐私优先：preferLocal 或云端不可用 / 未同意上传 → 直接本地。
//  - 云端失败（断网 / 超时 / 解析错）→ 自动兜底本地，绝不让用户卡住。
//  - mixPreview：由 App 侧注入 Engine 的计算函数，用于把精确配比回填进推荐；
//    未注入时推荐仍可用（展示估算值），**本包不自行实现度数公式**。
//

import Foundation

public actor BartenderService {

    private var config: AICompanionConfig
    private let local: RecipeRecommending
    private let makeRemote: @Sendable (AICompanionConfig) -> RecipeRecommending
    private let mixPreview: (@Sendable (Recipe) -> MixResult?)?

    /// - Parameters:
    ///   - config: 接口配置（可运行时更新）。
    ///   - local: 本地兜底推荐器（默认规则引擎）。
    ///   - remoteFactory: 由 config 构造云端推荐器（默认 LLMRecommender）。便于注入测试桩。
    ///   - mixPreview: 注入 Engine 的兑制计算（可选）。`Recipe -> MixResult`。
    public init(
        config: AICompanionConfig = .localOnly,
        local: RecipeRecommending = LocalRuleRecommender(),
        remoteFactory: (@Sendable (AICompanionConfig) -> RecipeRecommending)? = nil,
        mixPreview: (@Sendable (Recipe) -> MixResult?)? = nil
    ) {
        self.config = config
        self.local = local
        self.makeRemote = remoteFactory ?? { cfg in LLMRecommender(config: cfg) }
        self.mixPreview = mixPreview
    }

    /// 运行时更新配置（例如用户在隐私提示里同意 / 撤回云端上传）。
    public func update(config: AICompanionConfig) {
        self.config = config
    }

    public var currentConfig: AICompanionConfig { config }

    /// 是否需要在调用前向用户征求云端上传同意。
    public var requiresCloudConsent: Bool {
        // 已启用 LLM 模式、配置了 endpoint，但用户尚未同意上传。
        config.llmMode != .disabled && config.endpoint != nil && !config.allowCloudUpload
    }

    /// 主入口：返回一条推荐（云端优先 / 本地兜底）。
    public func recommend(for query: BartenderQuery) async throws -> Recommendation {
        var recommendation = try await produce(for: query)
        recommendation = applyEnginePreview(to: recommendation)
        return recommendation
    }

    // MARK: - 编排

    private func produce(for query: BartenderQuery) async throws -> Recommendation {
        // 隐私 / 配置：优先本地或云端不可用 → 本地。
        if config.preferLocal || !config.isCloudUsable {
            return try await local.recommend(for: query)
        }
        // 云端优先，失败兜底本地。
        do {
            return try await makeRemote(config).recommend(for: query)
        } catch {
            // 兜底：本地引擎。
            return try await local.recommend(for: query)
        }
    }

    /// 若注入了 Engine 计算，把精确配比 / 标准杯回填进 ratioSummary。
    private func applyEnginePreview(to rec: Recommendation) -> Recommendation {
        guard let mixPreview, let result = mixPreview(rec.recipe) else { return rec }
        var copy = rec
        let added = format(result.addedML)
        let total = format(result.totalML)
        let units = String(format: "%.1f", result.standardUnits)
        copy.ratioSummary = "加入约 \(added) mL → 共 \(total) mL · 约 \(units) 标准杯（Engine 计算）"
        return copy
    }

    private func format(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v)
    }
}
