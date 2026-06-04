import Foundation

/// 全程显著的免责声明与理性饮酒提示文案（集中管理，便于审核与本地化）。
public enum HealthDisclaimer {

    /// 顶部常驻：核心免责声明。
    public static let primary =
        "本结果仅为基于 Widmark 公式的健康估算，存在显著个体差异，不能作为是否可驾车的依据，亦非法律或医学意见。"

    /// 强调：切勿酒后驾车。
    public static let neverDriveDrunk =
        "酒后切勿驾车。是否清醒请以专业检测为准。"

    /// 理性饮酒 / 未成年提示（合规红线，全程展示）。
    public static let responsibleDrinking =
        "请理性饮酒 · 未成年人请勿饮酒"

    /// 隐私说明。
    public static let privacy =
        "体重、性别等数据默认仅在本机参与计算，不会上传。"

    /// 合并的长文（用于「了解更多」弹窗）。
    public static let full = """
    重要提示

    · \(primary)
    · \(neverDriveDrunk)
    · \(privacy)
    · \(responsibleDrinking)

    血液酒精浓度受体质、空腹与否、药物、健康状况等众多因素影响，本估算可能与实际值存在较大偏差。请始终以安全为先。
    """
}
