//  DeepLinkRouter.swift
//  DeepLink —— 解析 → 回调主工程（路由由员工① 接）
//
//  本包只负责「把 URL 解析成 Recipe / id / 错误」并通过回调交出去；
//  还原后的页面跳转、自动计算的触发，全部由主工程（员工①）在回调里完成。
//  这样 DeepLink 不依赖任何 UI 路由实现，符合「包之间不直接依赖 UI」。

import Foundation
import Engine

/// 深链路由器：在主工程的 `.onOpenURL` / SceneDelegate 里接住 URL，转交回调。
///
/// 用法（主工程，员工①）：
/// ```swift
/// @StateObject private var router = DeepLinkRouter(
///     onRecipe: { recipe in appModel.restore(recipe) },      // 还原 + 自动计算
///     onNeedsLookup: { id in appModel.fetchRecipe(id: id) }, // 查表还原
///     onFailure: { err in appModel.toast("无法识别的二维码：\(err)") }
/// )
/// .onOpenURL { router.handle($0) }
/// ```
@MainActor
public final class DeepLinkRouter: ObservableObject {

    /// 成功解出自包含配方 —— 主工程应「还原 + 自动计算」。
    public var onRecipe: (Recipe) -> Void
    /// 只拿到短 id —— 主工程 / 服务端查表还原。
    public var onNeedsLookup: (String) -> Void
    /// 解析失败 —— 主工程给用户友好提示。
    public var onFailure: (DeepLinkError) -> Void

    /// 最近一次解析结果（可被 SwiftUI 观察，便于调试 / 展示）。
    @Published public private(set) var lastResolution: DeepLinkResolution?

    public init(
        onRecipe: @escaping (Recipe) -> Void = { _ in },
        onNeedsLookup: @escaping (String) -> Void = { _ in },
        onFailure: @escaping (DeepLinkError) -> Void = { _ in }
    ) {
        self.onRecipe = onRecipe
        self.onNeedsLookup = onNeedsLookup
        self.onFailure = onFailure
    }

    /// 处理一个进入 App 的 URL。返回解析结果，便于调用方按需自取。
    @discardableResult
    public func handle(_ url: URL) -> DeepLinkResolution {
        let resolution = DeepLinkParser.resolve(url)
        lastResolution = resolution
        switch resolution {
        case .recipe(let recipe): onRecipe(recipe)
        case .needsLookup(let id): onNeedsLookup(id)
        case .failed(let error): onFailure(error)
        }
        return resolution
    }
}
