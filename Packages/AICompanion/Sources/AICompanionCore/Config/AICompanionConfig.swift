//
//  AICompanionConfig.swift
//  AICompanionCore
//
//  AI 调酒师的可配置项。
//
//  🔐 密钥红线：
//  - 本包**绝不硬编码任何 API Key**。
//  - 推荐走「服务端代理」(useServerProxy = true)：App 只请求自家代理 URL，密钥保存在服务端。
//  - 若确需直连大模型，密钥通过 `bearerTokenProvider` 在运行时注入（取自 Keychain / 远程配置），
//    仍不落代码、不入仓。
//

import Foundation

/// 大模型接入模式。
public enum LLMMode: Sendable, Equatable {
    /// 走自家服务端代理（推荐）：密钥在服务端，App 不持有。
    case serverProxy
    /// 直连大模型：运行时注入 Bearer Token（取自 Keychain），仍不硬编码。
    case directWithInjectedToken
    /// 完全关闭云端，仅本地规则引擎。
    case disabled
}

/// AICompanion 配置。可由 App 侧（员工①）通过远程配置 / Info.plist / Keychain 装配。
public struct AICompanionConfig: Sendable {
    /// 大模型接入模式。
    public var llmMode: LLMMode
    /// 接口地址（serverProxy = 自家代理；direct = 模型厂商 endpoint）。
    public var endpoint: URL?
    /// 模型名（如 "claude-..." / 自家路由标识）。
    public var modelName: String
    /// 请求超时（秒）。超时即兜底本地。
    public var requestTimeout: TimeInterval
    /// 是否允许把用户文本上传云端（隐私开关，默认 false → 优先本地兜底）。
    /// 仅当用户在隐私提示中同意后才置 true。
    public var allowCloudUpload: Bool
    /// 是否始终优先本地（即便云端可用，也先本地；用于弱网 / 隐私优先体验）。
    public var preferLocal: Bool
    /// 直连模式下的运行时令牌提供者（不落代码）。serverProxy 模式可为 nil。
    public var bearerTokenProvider: (@Sendable () -> String?)?

    public init(
        llmMode: LLMMode = .disabled,
        endpoint: URL? = nil,
        modelName: String = "yun-bartender-default",
        requestTimeout: TimeInterval = 12,
        allowCloudUpload: Bool = false,
        preferLocal: Bool = true,
        bearerTokenProvider: (@Sendable () -> String?)? = nil
    ) {
        self.llmMode = llmMode
        self.endpoint = endpoint
        self.modelName = modelName
        self.requestTimeout = requestTimeout
        self.allowCloudUpload = allowCloudUpload
        self.preferLocal = preferLocal
        self.bearerTokenProvider = bearerTokenProvider
    }

    /// 默认：纯本地、不上传云端、断网可用。
    public static let localOnly = AICompanionConfig(
        llmMode: .disabled,
        allowCloudUpload: false,
        preferLocal: true
    )

    /// 云端是否可用（已启用且地址已配置且用户已同意上传）。
    public var isCloudUsable: Bool {
        guard allowCloudUpload, endpoint != nil else { return false }
        switch llmMode {
        case .serverProxy, .directWithInjectedToken: return true
        case .disabled: return false
        }
    }
}
