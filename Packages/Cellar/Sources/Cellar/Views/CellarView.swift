//  CellarView.swift
//  「我的酒柜」：收藏配方 + 常用原酒。可命名 / 编辑 / 删除 / 一键载入。

import SwiftUI
import SwiftData
import CellarCore

public struct CellarView: View {
    @Environment(CellarStore.self) private var store

    /// 「一键载入」回调：把还原的 Recipe 交给宿主（Engine / Mixing）触发计算。
    private let onLoad: (Recipe) -> Void

    @State private var renaming: SavedRecipe?
    @State private var renameText: String = ""
    @State private var showAddSpirit = false

    public init(onLoad: @escaping (Recipe) -> Void = { _ in }) {
        self.onLoad = onLoad
    }

    public var body: some View {
        let recipes = store.savedRecipes()
        let spirits = store.savedSpirits()

        List {
            Section {
                if recipes.isEmpty {
                    emptyHint("还没有收藏配方", system: "books.vertical")
                } else {
                    ForEach(recipes) { saved in
                        SavedRecipeRow(saved: saved) { onLoad(store.load(saved)) }
                            .listRowBackground(YunTheme.inkRaised)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) { store.delete(saved) } label: {
                                    Label("删除", systemImage: "trash")
                                }
                                Button {
                                    renameText = saved.name
                                    renaming = saved
                                } label: {
                                    Label("重命名", systemImage: "pencil")
                                }.tint(YunTheme.gold)
                            }
                    }
                }
            } header: {
                sectionHeader("收藏配方")
            }

            Section {
                if spirits.isEmpty {
                    emptyHint("还没有常用原酒", system: "drop")
                } else {
                    ForEach(spirits) { spirit in
                        SpiritRow(spirit: spirit)
                            .listRowBackground(YunTheme.inkRaised)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) { store.delete(spirit) } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                    }
                }
            } header: {
                HStack {
                    sectionHeader("常用原酒")
                    Spacer()
                    Button { showAddSpirit = true } label: {
                        Image(systemName: "plus.circle").foregroundStyle(YunTheme.gold)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(YunTheme.ink.ignoresSafeArea())
        .navigationTitle("我的酒柜")
        .alert("重命名配方", isPresented: Binding(get: { renaming != nil },
                                              set: { if !$0 { renaming = nil } })) {
            TextField("名称", text: $renameText)
            Button("取消", role: .cancel) { renaming = nil }
            Button("保存") {
                if let r = renaming { store.rename(r, to: renameText) }
                renaming = nil
            }
        }
        .sheet(isPresented: $showAddSpirit) {
            AddSpiritSheet { name, abv, stock, aroma in
                store.addSpirit(name: name, abv: abv, stockML: stock, aroma: aroma)
            }
            .presentationDetents([.medium])
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(YunTheme.serifTitle(15))
            .foregroundStyle(YunTheme.gold)
    }

    private func emptyHint(_ text: String, system: String) -> some View {
        HStack {
            Image(systemName: system)
            Text(text)
        }
        .font(.subheadline)
        .foregroundStyle(YunTheme.textSecondary)
        .listRowBackground(YunTheme.inkRaised)
    }
}

#Preview("我的酒柜") {
    NavigationStack {
        CellarView { recipe in print("载入: \(recipe.name)") }
            .environment(CellarSample.makeStore())
    }
    .preferredColorScheme(.dark)
}

#Preview("空酒柜") {
    NavigationStack {
        CellarView()
            .environment(CellarSample.makeStore(empty: true))
    }
    .preferredColorScheme(.dark)
}
