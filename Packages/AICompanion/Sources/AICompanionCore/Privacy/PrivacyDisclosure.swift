//
//  PrivacyDisclosure.swift
//  AICompanionCore
//
//  隐私合规（上架红线）：
//  - 任何上传云端的文本，必须在隐私清单声明，并在上传前向用户明示、取得同意。
//  - 默认优先本地兜底，不上传。
//
//  本类型集中描述「会上传什么 / 用途 / 保留策略」，供 UI 在征求同意时展示，
//  同时与 App 的 PrivacyInfo.xcprivacy / App Store 隐私问卷保持一致。
//

import Foundation

public struct PrivacyDisclosure: Sendable, Equatable {
    /// 会被上传的数据项（人类可读）。
    public var collectedItems: [String]
    /// 用途说明。
    public var purpose: String
    /// 是否用于追踪用户（影响 App 隐私分级）。
    public var usedForTracking: Bool
    /// 数据保留策略说明。
    public var retention: String
    /// 给用户的一句话提示文案（上传前显示）。
    public var userPrompt: String

    public init(
        collectedItems: [String],
        purpose: String,
        usedForTracking: Bool,
        retention: String,
        userPrompt: String
    ) {
        self.collectedItems = collectedItems
        self.purpose = purpose
        self.usedForTracking = usedForTracking
        self.retention = retention
        self.userPrompt = userPrompt
    }

    /// 「AI 调酒师」默认隐私声明 —— 与 PrivacyInfo.xcprivacy 中
    /// NSPrivacyCollectedDataTypeOtherUserContent（不追踪）一致。
    public static let bartender = PrivacyDisclosure(
        collectedItems: ["你输入的口味描述文本"],
        purpose: "仅用于生成本次调酒推荐，不构建用户画像、不用于广告。",
        usedForTracking: false,
        retention: "推荐生成后即丢弃，不与账号绑定、不长期留存。",
        userPrompt: "为获得更智能的推荐，本次将把你的口味描述发送至云端 AI。不同意也可使用「本地推荐」，全程不联网。"
    )
}
