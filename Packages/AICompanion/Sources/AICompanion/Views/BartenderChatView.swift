//
//  BartenderChatView.swift
//  AICompanion
//
//  「AI 调酒师」对话主界面。对外暴露的入口 View。
//

import SwiftUI
import AICompanionCore

public struct BartenderChatView: View {

    @StateObject private var viewModel: BartenderViewModel

    /// - Parameters:
    ///   - service: 注入的服务（默认本地兜底）。
    ///   - onLoadRecipe: 一键载入计算器回调（App 侧接 Engine/Mixing 计算器）。
    public init(
        service: BartenderService = BartenderService(),
        onLoadRecipe: @escaping (Recipe) -> Void = { _ in }
    ) {
        _viewModel = StateObject(wrappedValue: BartenderViewModel(service: service, onLoadRecipe: onLoadRecipe))
    }

    /// 直接注入 ViewModel（测试 / 预览）。
    public init(viewModel: BartenderViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        ZStack {
            YunInk.background.ignoresSafeArea()
            VStack(spacing: 0) {
                transcript
                if viewModel.messages.count <= 1 {
                    examplesStrip
                }
                inputBar
            }
        }
        .tint(YunInk.gold)
        .overlay(alignment: .center) { consentOverlay }
    }

    // MARK: - 对话流

    private var transcript: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    ForEach(viewModel.messages) { message in
                        messageView(message).id(message.id)
                    }
                    if viewModel.isThinking {
                        thinkingBubble.id("thinking")
                    }
                }
                .padding(16)
            }
            .onChange(of: viewModel.messages.count) {
                if let last = viewModel.messages.last {
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func messageView(_ message: ChatMessage) -> some View {
        switch message.role {
        case .user:
            HStack {
                Spacer(minLength: 40)
                Text(message.text)
                    .font(.body)
                    .foregroundStyle(YunInk.textPrimary)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(YunInk.userBubble)
                    )
            }
        case .bartender:
            VStack(alignment: .leading, spacing: 10) {
                Text(message.text)
                    .font(.body)
                    .foregroundStyle(YunInk.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                if let rec = message.recommendation {
                    RecommendationCardView(recommendation: rec) {
                        viewModel.load(rec)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, 24)
        }
    }

    private var thinkingBubble: some View {
        HStack(spacing: 6) {
            ProgressView().controlSize(.small).tint(YunInk.gold)
            Text("调配中…").font(.footnote).foregroundStyle(YunInk.textSecondary)
        }
    }

    // MARK: - 示例

    private var examplesStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.examples, id: \.self) { example in
                    Button {
                        viewModel.useExample(example)
                    } label: {
                        Text(example)
                            .font(.footnote)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .overlay(
                                Capsule().stroke(YunInk.gold.opacity(0.5), lineWidth: 0.8)
                            )
                            .foregroundStyle(YunInk.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16).padding(.bottom, 8)
        }
    }

    // MARK: - 输入栏

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("描述你的口味…", text: $viewModel.input, axis: .vertical)
                .lineLimit(1...4)
                .font(.body)
                .foregroundStyle(YunInk.textPrimary)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(YunInk.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(YunInk.gold.opacity(0.3), lineWidth: 0.8)
                )
                .onSubmit(viewModel.send)

            Button(action: viewModel.send) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(canSend ? YunInk.gold : YunInk.textSecondary.opacity(0.4))
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(YunInk.background)
    }

    private var canSend: Bool {
        !viewModel.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isThinking
    }

    // MARK: - 隐私同意

    @ViewBuilder
    private var consentOverlay: some View {
        if let disclosure = viewModel.pendingConsent {
            ZStack {
                Color.black.opacity(0.6).ignoresSafeArea()
                    .onTapGesture { viewModel.resolveConsent(agreed: false) }
                ConsentDialogView(disclosure: disclosure) { agreed in
                    viewModel.resolveConsent(agreed: agreed)
                }
                .padding(28)
            }
            .transition(.opacity)
        }
    }
}

// MARK: - 隐私同意弹窗

struct ConsentDialogView: View {
    let disclosure: PrivacyDisclosure
    let onChoice: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("云端 AI 提示")
                .font(.yunSerifTitle(18))
                .foregroundStyle(YunInk.textPrimary)
            Text(disclosure.userPrompt)
                .font(.footnote)
                .foregroundStyle(YunInk.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: 4) {
                Label(disclosure.collectedItems.joined(separator: "、"), systemImage: "doc.text")
                Label(disclosure.purpose, systemImage: "target")
                Label(disclosure.retention, systemImage: "trash")
            }
            .font(.caption2)
            .foregroundStyle(YunInk.textSecondary.opacity(0.85))

            HStack(spacing: 10) {
                Button { onChoice(false) } label: {
                    Text("仅用本地推荐")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(YunInk.textSecondary.opacity(0.5)))
                        .foregroundStyle(YunInk.textSecondary)
                }
                .buttonStyle(.plain)
                Button { onChoice(true) } label: {
                    Text("同意并继续")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(YunInk.gold.opacity(0.2)))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(YunInk.gold))
                        .foregroundStyle(YunInk.goldBright)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .yunGoldCard()
        .frame(maxWidth: 360)
    }
}

// 使用 PreviewProvider（而非 #Preview 宏），以便在 Xcode 与命令行工具链下均可编译。
struct BartenderChatView_Previews: PreviewProvider {
    static var previews: some View {
        BartenderChatView(viewModel: PreviewFixtures.populatedViewModel())
            .previewDisplayName("对话 · 本地兜底")

        BartenderChatView(service: BartenderService())
            .previewDisplayName("空态")
    }
}
