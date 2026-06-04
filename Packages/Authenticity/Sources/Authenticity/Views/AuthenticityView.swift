import SwiftUI

// MARK: - 防伪验真主入口
//
// 这是 Authenticity 包对外暴露的顶层 View。
// 由主工程（员工①）以注入好的 service 直接放入导航栈即可。
//
//   AuthenticityView(viewModel: .init(service: MockAuthenticityService()))   // 开发
//   AuthenticityView(viewModel: .init(service: RemoteAuthenticityService(endpoint: .production)))  // 上线

public struct AuthenticityView: View {
    @State private var viewModel: AuthenticityViewModel
    @State private var showScanner = false
    @FocusState private var inputFocused: Bool

    public init(viewModel: AuthenticityViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        ZStack {
            AuthTheme.ink.ignoresSafeArea()
            content
        }
        .sheet(isPresented: $showScanner) {
            CodeScannerView(
                onScanned: { value in
                    showScanner = false
                    viewModel.verify(rawCode: value, channel: .scan)
                },
                onClose: { showScanner = false }
            )
        }
    }

    // MARK: 阶段路由
    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .idle:
            entry
        case .verifying:
            verifying
        case .result(let result):
            routedResult(result)
        case .failure(let message):
            VerificationFailureView(kind: .systemError(message), onRetry: { viewModel.reset() })
        }
    }

    // 业务结果路由：正品 → 成功页；仿冒/未收录 → 防伪提示页。
    @ViewBuilder
    private func routedResult(_ result: VerificationResult) -> some View {
        switch result.status {
        case .authentic, .alreadyScanned:
            VerificationResultView(result: result, onVerifyAnother: { viewModel.clear() })
        case .counterfeit:
            VerificationFailureView(kind: .counterfeit, onRetry: { viewModel.clear() })
        case .unknown:
            VerificationFailureView(kind: .unknownCode(result.code), onRetry: { viewModel.clear() })
        }
    }

    // MARK: 输入入口
    private var entry: some View {
        ScrollView {
            VStack(spacing: 26) {
                header
                scanCard
                manualCard
                disclaimer
            }
            .padding(20)
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "seal")
                .font(.system(size: 40))
                .foregroundStyle(AuthTheme.goldGradient)
                .padding(.top, 12)
            Text("扫码验真")
                .font(AuthTheme.serifTitle(28, weight: .semibold))
                .foregroundStyle(AuthTheme.textPrimary)
            Text("辨明真伪 · 溯源每一滴雲酿")
                .font(.system(size: 13))
                .foregroundStyle(AuthTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var scanCard: some View {
        Button {
            inputFocused = false
            showScanner = true
        } label: {
            VStack(spacing: 12) {
                Image(systemName: "viewfinder.circle")
                    .font(.system(size: 44))
                    .foregroundStyle(AuthTheme.goldGradient)
                Text("相机扫码")
                    .font(AuthTheme.serifTitle(18))
                    .foregroundStyle(AuthTheme.textPrimary)
                Text("对准瓶身防伪码 / 二维码")
                    .font(.system(size: 12))
                    .foregroundStyle(AuthTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .background(GoldCardBackground())
        }
        .buttonStyle(.plain)
    }

    private var manualCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Rectangle().fill(AuthTheme.goldGradient).frame(width: 3, height: 16)
                Text("手动输入防伪码")
                    .font(AuthTheme.serifTitle(17))
                    .foregroundStyle(AuthTheme.textPrimary)
            }

            codeField
                .focused($inputFocused)
                .autocorrectionDisabled()
                .font(.system(size: 16, design: .monospaced))
                .foregroundStyle(AuthTheme.textPrimary)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AuthTheme.ink)
                        .overlay(RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(AuthTheme.goldDim.opacity(0.6), lineWidth: 1))
                )

            Button {
                inputFocused = false
                viewModel.verify(channel: .manual)
            } label: {
                Text("立即验真")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(viewModel.canSubmit ? AuthTheme.ink : AuthTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        Capsule().fill(viewModel.canSubmit
                                       ? AnyShapeStyle(AuthTheme.goldGradient)
                                       : AnyShapeStyle(AuthTheme.surface))
                    )
            }
            .disabled(!viewModel.canSubmit)
        }
        .goldCard()
    }

    /// 防伪码输入框（`textInputAutocapitalization` 为 iOS 专有，按平台隔离）。
    private var codeField: some View {
        let field = TextField("", text: $viewModel.code,
                              prompt: Text("输入瓶身 12–24 位防伪码")
                                .foregroundColor(AuthTheme.textSecondary))
        #if os(iOS)
        return field.textInputAutocapitalization(.characters)
        #else
        return field
        #endif
    }

    private var disclaimer: some View {
        Text("请理性饮酒 · 未成年人请勿饮酒")
            .font(.system(size: 11))
            .foregroundStyle(AuthTheme.textSecondary)
            .padding(.top, 4)
    }

    // MARK: 验真中
    private var verifying: some View {
        VStack(spacing: 18) {
            ProgressView()
                .controlSize(.large)
                .tint(AuthTheme.gold)
            Text("正在验真…")
                .font(AuthTheme.serifTitle(18))
                .foregroundStyle(AuthTheme.textPrimary)
            Text(viewModel.code)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(AuthTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#if os(iOS)
#Preview("验真入口") {
    AuthenticityView(viewModel: .init(service: MockAuthenticityService()))
}
#endif
