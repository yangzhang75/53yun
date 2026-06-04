import SwiftUI

// MARK: - 验真失败 / 防伪提示
//
// 覆盖两类失败：
//  1) 业务失败：仿冒 / 未收录（VerificationResult.status）。
//  2) 系统失败：网络、解析等（错误文案字符串）。

public struct VerificationFailureView: View {

    public enum Kind: Equatable {
        case counterfeit          // 明确仿冒
        case unknownCode(String)  // 系统未收录该码
        case systemError(String)  // 网络/解析等

        var icon: String {
            switch self {
            case .counterfeit:  return "xmark.seal.fill"
            case .unknownCode:  return "questionmark.circle.fill"
            case .systemError:  return "wifi.exclamationmark"
            }
        }
        var tint: Color {
            switch self {
            case .counterfeit:  return AuthTheme.danger
            case .unknownCode:  return AuthTheme.warning
            case .systemError:  return AuthTheme.textSecondary
            }
        }
        var title: String {
            switch self {
            case .counterfeit:  return "警惕！未通过验真"
            case .unknownCode:  return "未查询到该防伪码"
            case .systemError:  return "验真未完成"
            }
        }
        var message: String {
            switch self {
            case .counterfeit:
                return "该防伪码未能通过官方验真，存在仿冒风险。\n请立即停止饮用，并通过官方渠道核实购买来源。"
            case .unknownCode(let code):
                return "防伪码 \(code) 不在官方溯源库中。\n请核对是否输入有误；若为正规渠道购买，请联系官方客服。"
            case .systemError(let msg):
                return msg
            }
        }
        /// 防伪安全提示（仅业务失败展示）。
        var tips: [String] {
            switch self {
            case .counterfeit, .unknownCode:
                return [
                    "认准瓶身烫金「雲」字镭射防伪标",
                    "刮开涂层后核对防伪码与瓶盖内码是否一致",
                    "通过官方小程序 / 官网二次复核",
                    "切勿购买明显低于市场价的产品"
                ]
            case .systemError:
                return []
            }
        }
    }

    public let kind: Kind
    public let onRetry: () -> Void

    public init(kind: Kind, onRetry: @escaping () -> Void) {
        self.kind = kind
        self.onRetry = onRetry
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .strokeBorder(kind.tint.opacity(0.6), lineWidth: 1.5)
                        .frame(width: 76, height: 76)
                    Image(systemName: kind.icon)
                        .font(.system(size: 36))
                        .foregroundStyle(kind.tint)
                }
                .padding(.top, 12)

                Text(kind.title)
                    .font(AuthTheme.serifTitle(24, weight: .semibold))
                    .foregroundStyle(AuthTheme.textPrimary)

                Text(kind.message)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 14))
                    .foregroundStyle(AuthTheme.textSecondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 8)

                if !kind.tips.isEmpty {
                    tipsCard
                }

                Button(action: onRetry) {
                    Text("重新验真")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AuthTheme.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(AuthTheme.goldGradient))
                }
                .padding(.top, 4)

                Text("请理性饮酒 · 未成年人请勿饮酒")
                    .font(.system(size: 11))
                    .foregroundStyle(AuthTheme.textSecondary)
            }
            .padding(20)
        }
        .background(AuthTheme.ink.ignoresSafeArea())
    }

    private var tipsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "shield.lefthalf.filled")
                    .foregroundStyle(AuthTheme.gold)
                Text("防伪自查指引")
                    .font(AuthTheme.serifTitle(17))
                    .foregroundStyle(AuthTheme.textPrimary)
            }
            ForEach(Array(kind.tips.enumerated()), id: \.offset) { index, tip in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(index + 1)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AuthTheme.ink)
                        .frame(width: 18, height: 18)
                        .background(Circle().fill(AuthTheme.gold))
                    Text(tip)
                        .font(.system(size: 13))
                        .foregroundStyle(AuthTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .goldCard()
    }
}

#if os(iOS)
#Preview("仿冒") {
    VerificationFailureView(kind: .counterfeit, onRetry: {})
}

#Preview("未收录") {
    VerificationFailureView(kind: .unknownCode("YUN0000NOTFOUND9"), onRetry: {})
}

#Preview("网络错误") {
    VerificationFailureView(kind: .systemError("网络连接异常：请检查网络后重试"), onRetry: {})
}
#endif
