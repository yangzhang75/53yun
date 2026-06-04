import Foundation

/// 一键叫代驾的「服务入口」（占位 / 可跳第三方）。
///
/// 合规说明：本 App 不在内部完成任何酒类或代驾交易，仅提供跳转到第三方 App / 网页的入口。
/// 若第三方未安装或无深链，回退到占位提示。
public struct DesignatedDriverOption: Equatable, Sendable, Identifiable {

    public let id: String
    /// 展示名称，如「滴滴代驾」。
    public let name: String
    /// 简短说明。
    public let subtitle: String
    /// 跳转深链（占位；集成时由 App 层注入真实第三方 scheme / Universal Link）。
    public let deepLink: URL?

    public init(id: String, name: String, subtitle: String, deepLink: URL?) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.deepLink = deepLink
    }
}

/// 代驾服务目录。默认提供占位选项；真实第三方入口由 App 层在集成时注入。
public struct DesignatedDriverService: Sendable {

    public let options: [DesignatedDriverOption]

    public init(options: [DesignatedDriverOption] = DesignatedDriverService.placeholderOptions) {
        self.options = options
    }

    /// 占位选项：不指向任何真实交易，仅作 UI 演示与集成锚点。
    public static let placeholderOptions: [DesignatedDriverOption] = [
        DesignatedDriverOption(
            id: "third-party-1",
            name: "呼叫代驾（第三方）",
            subtitle: "跳转合作代驾平台 · 不在本 App 内交易",
            deepLink: nil),
        DesignatedDriverOption(
            id: "taxi",
            name: "改打车回家",
            subtitle: "为了安全，今晚把方向盘交出去",
            deepLink: nil)
    ]

    /// 紧急/兜底文案：当没有可用第三方入口时展示。
    public static let fallbackHint =
        "已为你预留代驾入口。集成正式版后将跳转合作平台；现在也可直接联系代驾或家人朋友接送。"
}
