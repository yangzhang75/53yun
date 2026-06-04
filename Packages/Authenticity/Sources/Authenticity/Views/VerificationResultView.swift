import SwiftUI

// MARK: - 验真成功展示
//
// 包含：验真徽章 + 批次/年份/香型 + 酒厂故事 + 溯源时间线。
// 「已扫描」状态复用本视图，但顶部展示二次流通预警。

public struct VerificationResultView: View {
    public let result: VerificationResult
    public let onVerifyAnother: () -> Void

    public init(result: VerificationResult, onVerifyAnother: @escaping () -> Void) {
        self.result = result
        self.onVerifyAnother = onVerifyAnother
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                badge
                if result.status == .alreadyScanned {
                    rescanWarning
                }
                if let product = result.product {
                    productCard(product)
                    storyCard(product)
                    if !result.trace.isEmpty {
                        timelineSection
                    }
                }
                footer
            }
            .padding(20)
        }
        .background(AuthTheme.ink.ignoresSafeArea())
    }

    // MARK: 验真徽章
    private var badge: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .strokeBorder(AuthTheme.goldGradient, lineWidth: 1.5)
                    .frame(width: 76, height: 76)
                Image(systemName: result.status == .alreadyScanned ? "checkmark.seal" : "checkmark.seal.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(AuthTheme.goldGradient)
            }
            Text(result.status == .alreadyScanned ? "正品 · 已多次验证" : "正品验真通过")
                .font(AuthTheme.serifTitle(24, weight: .semibold))
                .foregroundStyle(AuthTheme.textPrimary)
            Text("防伪码 \(result.code)")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(AuthTheme.textSecondary)
            if let verifiedAt = result.verifiedAt {
                Text("验证时间 \(verifiedAt)")
                    .font(.system(size: 11))
                    .foregroundStyle(AuthTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: 二次流通预警
    private var rescanWarning: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AuthTheme.warning)
            VStack(alignment: .leading, spacing: 4) {
                Text("该防伪码已被验证 \(result.scanCount) 次")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AuthTheme.textPrimary)
                Text("首次验证于 \(result.firstScannedAt ?? "—")。多次验证可能意味着空瓶回收或二次流通，请向官方渠道核实购买来源。")
                    .font(.system(size: 12))
                    .foregroundStyle(AuthTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .goldCard()
        .overlay(
            RoundedRectangle(cornerRadius: AuthTheme.corner, style: .continuous)
                .strokeBorder(AuthTheme.warning.opacity(0.5), lineWidth: 1)
        )
    }

    // MARK: 产品信息卡
    private func productCard(_ product: AuthProduct) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(product.name)
                .font(AuthTheme.serifTitle(22))
                .foregroundStyle(AuthTheme.textPrimary)
            Divider().overlay(AuthTheme.goldDim.opacity(0.4))
            HStack(spacing: 0) {
                infoColumn("批次", product.batch)
                infoColumn("年份", "\(product.vintage)")
            }
            HStack(spacing: 0) {
                infoColumn("香型", product.aroma.displayName)
                infoColumn("酒精度", "\(Int(product.abv))° vol")
            }
            HStack(spacing: 0) {
                infoColumn("净含量", "\(product.netVolumeML) mL")
                infoColumn("酒厂", product.distillery)
            }
        }
        .goldCard()
    }

    private func infoColumn(_ key: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(key)
                .font(.system(size: 11))
                .foregroundStyle(AuthTheme.textSecondary)
            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AuthTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: 酒厂故事
    private func storyCard(_ product: AuthProduct) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("酒厂故事")
            Text(product.story)
                .font(.system(size: 14))
                .foregroundStyle(AuthTheme.textSecondary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .goldCard()
    }

    // MARK: 溯源时间线
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("溯源时间线")
            TraceTimelineView(steps: result.trace)
        }
        .goldCard()
    }

    private func sectionTitle(_ text: String) -> some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(AuthTheme.goldGradient)
                .frame(width: 3, height: 16)
            Text(text)
                .font(AuthTheme.serifTitle(18))
                .foregroundStyle(AuthTheme.textPrimary)
        }
    }

    // MARK: 底部
    private var footer: some View {
        VStack(spacing: 12) {
            Button(action: onVerifyAnother) {
                Text("验证下一瓶")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AuthTheme.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(AuthTheme.goldGradient))
            }
            Text("请理性饮酒 · 未成年人请勿饮酒")
                .font(.system(size: 11))
                .foregroundStyle(AuthTheme.textSecondary)
        }
        .padding(.top, 8)
    }
}

#if os(iOS)
#Preview("验真成功 · 酱香") {
    VerificationResultView(
        result: MockAuthenticityService.jiangxiangSample(code: "YUN2018JX0427A"),
        onVerifyAnother: {}
    )
}

#Preview("已多次扫描") {
    VerificationResultView(
        result: MockAuthenticityService.rescannedSample(code: "YUN9999RESCAN001"),
        onVerifyAnother: {}
    )
}
#endif
