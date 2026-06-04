//  CellarRows.swift
//  酒柜列表行：收藏配方行（含一键载入）、原酒行、新增原酒表单。

import SwiftUI
import CellarCore

/// 收藏配方行
struct SavedRecipeRow: View {
    let saved: SavedRecipe
    let onLoad: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(saved.name)
                    .font(YunTheme.serifTitle(17))
                    .foregroundStyle(YunTheme.textPrimary)
                HStack(spacing: 8) {
                    Tag(text: aromaName)
                    Tag(text: "目标 \(abvText)%vol")
                }
                if !saved.tastingNote.isEmpty {
                    Text(saved.tastingNote)
                        .font(.caption)
                        .foregroundStyle(YunTheme.textSecondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Button(action: onLoad) {
                Text("载入")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(YunTheme.ink)
                    .padding(.horizontal, 14).padding(.vertical, 7)
                    .background(Capsule().fill(YunTheme.gold))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("载入配方 \(saved.name)")
        }
        .padding(.vertical, 4)
    }

    private var aromaName: String {
        (AromaType(rawValue: saved.aromaRaw) ?? .nongxiang).displayName
    }
    private var abvText: String {
        String(format: "%g", saved.targetABV)
    }
}

/// 常用原酒行
struct SpiritRow: View {
    let spirit: SavedSpirit

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(spirit.name)
                    .font(YunTheme.serifBody(16))
                    .foregroundStyle(YunTheme.textPrimary)
                Text("\(spirit.aroma.displayName) · \(String(format: "%g", spirit.abv))%vol")
                    .font(.caption)
                    .foregroundStyle(YunTheme.textSecondary)
            }
            Spacer()
            if spirit.stockML > 0 {
                Text("\(String(format: "%g", spirit.stockML)) mL")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(YunTheme.gold)
            }
        }
        .padding(.vertical, 4)
    }
}

/// 小标签
private struct Tag: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption2)
            .foregroundStyle(YunTheme.textSecondary)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .overlay(Capsule().strokeBorder(YunTheme.hairline))
    }
}

/// 新增原酒表单
struct AddSpiritSheet: View {
    let onAdd: (String, Double, Double, AromaType) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var abv = "53"
    @State private var stock = "500"
    @State private var aroma: AromaType = .jiangxiang

    var body: some View {
        NavigationStack {
            Form {
                TextField("名称（如 雲·53° 飞天）", text: $name)
                TextField("度数 %vol", text: $abv)
                    .keyboardType(.decimalPad)
                TextField("库存 mL", text: $stock)
                    .keyboardType(.decimalPad)
                Picker("香型", selection: $aroma) {
                    ForEach(AromaType.allCases, id: \.self) { Text($0.displayName).tag($0) }
                }
            }
            .navigationTitle("新增原酒")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        onAdd(trimmed, Double(abv) ?? 0, Double(stock) ?? 0, aroma)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
}

#Preview("配方行", traits: .sizeThatFitsLayout) {
    let store = CellarSample.makeStore()
    return List(store.savedRecipes()) { saved in
        SavedRecipeRow(saved: saved) {}
            .listRowBackground(YunTheme.inkRaised)
    }
    .environment(store)
    .preferredColorScheme(.dark)
}
