//
//  BartenderViewModel.swift
//  AICompanion
//
//  对话界面的状态机（MVVM）。
//

import Foundation
import SwiftUI
import AICompanionCore

/// 一条对话消息。
public struct ChatMessage: Identifiable, Sendable {
    public enum Role: Sendable { case user, bartender }
    public let id = UUID()
    public var role: Role
    public var text: String
    /// 若该条携带一份可载入的推荐。
    public var recommendation: Recommendation?

    public init(role: Role, text: String, recommendation: Recommendation? = nil) {
        self.role = role
        self.text = text
        self.recommendation = recommendation
    }
}

@MainActor
public final class BartenderViewModel: ObservableObject {

    @Published public private(set) var messages: [ChatMessage] = []
    @Published public var input: String = ""
    @Published public private(set) var isThinking: Bool = false
    /// 待用户确认的云端上传提示（非 nil 时 UI 弹出同意框）。
    @Published public var pendingConsent: PrivacyDisclosure?

    /// 常见诉求示例（引导用户）。
    public let examples: [String] = [
        "清爽不上头、8 度左右、酱香打底",
        "想要绵柔顺口，浓香，加冰",
        "够劲一点的清香，纯饮",
        "解腻的低度气泡喝法"
    ]

    private let service: BartenderService
    /// 一键载入计算器回调（由 App 侧接 Engine / Mixing 的计算器界面）。
    private let onLoadRecipe: (Recipe) -> Void
    /// 暂存用户在等待同意期间的诉求。
    private var queuedQuery: BartenderQuery?

    public init(
        service: BartenderService = BartenderService(),
        onLoadRecipe: @escaping (Recipe) -> Void = { _ in }
    ) {
        self.service = service
        self.onLoadRecipe = onLoadRecipe
        messages.append(
            ChatMessage(
                role: .bartender,
                text: "我是 53° 雲 的 AI 调酒师。说说你的口味，比如「清爽不上头、8 度左右、酱香打底」，我来给配方。\n请理性饮酒，未成年人请勿饮酒。"
            )
        )
    }

    /// 发送当前输入。
    public func send() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        input = ""
        submit(BartenderQuery(text: text))
    }

    /// 点击示例。
    public func useExample(_ example: String) {
        submit(BartenderQuery(text: example))
    }

    private func submit(_ query: BartenderQuery) {
        messages.append(ChatMessage(role: .user, text: query.text))

        Task {
            // 隐私：若需要云端上传同意且尚未授权，先弹提示。
            if await service.requiresCloudConsent {
                queuedQuery = query
                pendingConsent = .bartender
                return
            }
            await run(query)
        }
    }

    /// 用户对云端上传作出选择。
    public func resolveConsent(agreed: Bool) {
        let query = queuedQuery
        queuedQuery = nil
        pendingConsent = nil

        Task {
            if agreed {
                var cfg = await service.currentConfig
                cfg.allowCloudUpload = true
                cfg.preferLocal = false
                await service.update(config: cfg)
            }
            if let query {
                await run(query)
            }
        }
    }

    private func run(_ query: BartenderQuery) async {
        isThinking = true
        defer { isThinking = false }
        do {
            let rec = try await service.recommend(for: query)
            messages.append(
                ChatMessage(role: .bartender, text: rec.rationale, recommendation: rec)
            )
        } catch let error as BartenderError {
            messages.append(ChatMessage(role: .bartender, text: error.errorDescription ?? "出了点问题，再试一次。"))
        } catch {
            messages.append(ChatMessage(role: .bartender, text: "出了点问题，再试一次。"))
        }
    }

    /// 一键载入计算器。
    public func load(_ recommendation: Recommendation) {
        onLoadRecipe(recommendation.recipe)
    }
}
