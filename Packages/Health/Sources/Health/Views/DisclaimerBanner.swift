import SwiftUI

/// 全程显著的免责声明横幅 + 理性饮酒提示。
public struct DisclaimerBanner: View {

    @State private var showFull = false

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(HealthTheme.gold)
                    .font(.footnote)
                Text(HealthDisclaimer.primary)
                    .font(.footnote)
                    .foregroundStyle(HealthTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                Text(HealthDisclaimer.responsibleDrinking)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(HealthTheme.gold)
                Spacer()
                Button("了解更多") { showFull = true }
                    .font(.caption)
                    .foregroundStyle(HealthTheme.textSecondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(HealthTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(HealthTheme.gold.opacity(0.35), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
        .sheet(isPresented: $showFull) {
            disclaimerSheet
        }
    }

    private var disclaimerSheet: some View {
        ScrollView {
            Text(HealthDisclaimer.full)
                .font(.callout)
                .foregroundStyle(HealthTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
        }
        .background(HealthTheme.ink)
    }
}

#if DEBUG
struct DisclaimerBanner_Previews: PreviewProvider {
    static var previews: some View {
        DisclaimerBanner()
            .padding()
            .background(HealthTheme.ink)
    }
}
#endif
