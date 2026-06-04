import Foundation

/// 一条温柔的适饮提示。
public struct PaceTip: Equatable, Sendable, Identifiable {
    public enum Tone: Sendable {
        case calm      // 平和（清醒区）
        case caution   // 提醒（已不宜驾车）
        case strong    // 强提醒（醉意明显）
    }

    public let id: String
    public let title: String
    public let message: String
    public let tone: Tone

    public init(id: String, title: String, message: String, tone: Tone) {
        self.id = id
        self.title = title
        self.message = message
        self.tone = tone
    }
}

/// 「适饮节奏温柔提示」生成器。
///
/// 基于当前 BAC 估算，给出克制、不说教的建议。语气温柔，强调理性饮酒。
/// 注：所有提示均为健康关怀，非医学建议。
public struct DrinkingPaceAdvisor: Sendable {

    public init() {}

    /// 依据估算结果生成提示列表（按重要性排序）。
    public func tips(for estimate: BACEstimate) -> [PaceTip] {
        var tips: [PaceTip] = []

        switch estimate.level {
        case .sober:
            if estimate.currentBACMgPer100mL <= 0 {
                tips.append(PaceTip(
                    id: "clear",
                    title: "状态清爽",
                    message: "目前估算已基本清醒。若要继续小酌，记得佐以清水与小食，慢慢品。",
                    tone: .calm))
            } else {
                tips.append(PaceTip(
                    id: "near-clear",
                    title: "接近清醒",
                    message: "酒意正在退去。给身体一点时间，喝口温水，慢一点更舒服。",
                    tone: .calm))
            }

        case .driving:
            tips.append(PaceTip(
                id: "no-drive",
                title: "此刻请勿驾车",
                message: "估算已进入不宜驾车区间。把车钥匙收好，叫一程代驾或打车更稳妥。",
                tone: .caution))
            tips.append(PaceTip(
                id: "slow-down",
                title: "放慢节奏",
                message: "下一杯不妨先放一放，间隔久一些，配点水和食物，让身体跟上。",
                tone: .caution))

        case .intoxicated:
            tips.append(PaceTip(
                id: "stop",
                title: "建议先停一停",
                message: "估算酒意已较明显。这一杯可以放下了，多喝水、找个舒服的地方坐坐。",
                tone: .strong))
            tips.append(PaceTip(
                id: "company",
                title: "结伴照应",
                message: "尽量不要独处，让朋友知道你的状态；务必不要驾车，安排代驾或同行护送。",
                tone: .strong))
        }

        // 始终附带的通用关怀。
        tips.append(PaceTip(
            id: "hydrate",
            title: "节奏小贴士",
            message: "高度白酒入口柔，后劲足。一口酒、一口水，细品慢饮，是对身体的尊重。",
            tone: .calm))

        return tips
    }

    /// 一句话状态摘要（用于卡片副标题）。
    public func headline(for estimate: BACEstimate) -> String {
        switch estimate.level {
        case .sober where estimate.currentBACMgPer100mL <= 0:
            return "估算已清醒 · 仍请理性饮酒"
        case .sober:
            return "酒意渐退 · 仍请理性饮酒"
        case .driving:
            return "已不宜驾车 · 请安排代驾"
        case .intoxicated:
            return "酒意明显 · 请停杯并照应自己"
        }
    }
}
