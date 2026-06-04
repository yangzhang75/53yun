import Foundation

// MARK: - Mock 验真服务
//
// 开发 / 预览 / 演示阶段使用。返回与真实协议完全一致的数据结构，
// 因此切换到 RemoteAuthenticityService 时上层零改动。
//
// 内置示例码（便于验收）：
//   YUN2018JX0427A    → 正品（酱香典藏 · 完整溯源时间线）
//   YUN2021QX1187C    → 正品（清香）
//   FAKE000000000000  → 仿冒（明确防伪提示）
//   YUN9999RESCAN001  → 已被多次扫描（二次流通预警）
//   其它合法格式码      → 系统未收录（unknown）

public struct MockAuthenticityService: AuthenticityProviding {
    /// 模拟网络往返耗时（秒），便于在 UI 上看到加载态。
    public let latency: Duration

    public init(latency: Duration = .milliseconds(700)) {
        self.latency = latency
    }

    public func verify(code: String, channel: VerificationChannel) async throws -> VerificationResult {
        let normalized = AuthCodeValidator.normalize(code)
        guard !normalized.isEmpty else { throw AuthenticityError.emptyCode }
        guard AuthCodeValidator.isValid(normalized) else { throw AuthenticityError.malformedCode }

        try await Task.sleep(for: latency)
        try Task.checkCancellation()

        switch normalized {
        case "YUN2018JX0427A":
            return Self.jiangxiangSample(code: normalized)
        case "YUN2021QX1187C":
            return Self.qingxiangSample(code: normalized)
        case "FAKE000000000000":
            return VerificationResult(status: .counterfeit, code: normalized, verifiedAt: "2026-06-03 20:14")
        case "YUN9999RESCAN001":
            return Self.rescannedSample(code: normalized)
        default:
            return VerificationResult(status: .unknown, code: normalized, verifiedAt: "2026-06-03 20:14")
        }
    }
}

// MARK: 示例数据

extension MockAuthenticityService {

    /// 酱香典藏：完整「酿造 → 封坛 → 出厂」时间线。
    static func jiangxiangSample(code: String) -> VerificationResult {
        VerificationResult(
            status: .authentic,
            code: code,
            product: AuthProduct(
                name: "53° 雲 · 酱香典藏",
                batch: "JX-20180917-0427",
                vintage: 2018,
                aroma: .jiangxiang,
                abv: 53,
                netVolumeML: 500,
                distillery: "赤水河畔 · 雲酒坊",
                story: "雲酒坊坐落于赤水河中游紫红泥岩谷地，承「12987」古法酿艺——一年一个生产周期，两次投粮，九次蒸煮，八次发酵，七次取酒。匠人以河谷红缨子糯高粱为骨，以微生物群落为魂，封坛静候时光，方得这一盏醇厚酱香。"
            ),
            trace: [
                TraceStep(
                    stage: "酿造",
                    title: "端午制曲 · 重阳下沙",
                    date: "2018-09-17",
                    location: "赤水河谷 · 雲酒坊制曲车间",
                    detail: "端午高温制曲，重阳河水回清时下沙投粮。红缨子糯高粱整粒润粮，开启一年一度的酿造周期。"
                ),
                TraceStep(
                    stage: "封坛",
                    title: "陶坛入库 · 洞藏陈放",
                    date: "2019-04-02",
                    location: "雲酒坊地下恒温酒库",
                    detail: "基酒按轮次分级，盛入贵州本地紫砂陶坛，于恒温恒湿酒库中封坛陈放，历经五年缔合老熟。"
                ),
                TraceStep(
                    stage: "出厂",
                    title: "勾调灌装 · 验真出厂",
                    date: "2023-11-20",
                    location: "雲酒坊灌装中心",
                    detail: "以老酒勾调定味，逐瓶赋予唯一防伪溯源码，经三道质检后封箱出厂。"
                )
            ],
            scanCount: 1,
            firstScannedAt: "2026-06-03 20:14",
            verifiedAt: "2026-06-03 20:14"
        )
    }

    /// 清香型：示例第二款正品。
    static func qingxiangSample(code: String) -> VerificationResult {
        VerificationResult(
            status: .authentic,
            code: code,
            product: AuthProduct(
                name: "53° 雲 · 清香原浆",
                batch: "QX-20210311-1187",
                vintage: 2021,
                aroma: .qingxiang,
                abv: 53,
                netVolumeML: 500,
                distillery: "汾水之源 · 雲酒坊北坊",
                story: "清香一脉，讲究「一清到底」。地缸分离发酵，杜绝杂味，酒体清雅纯净，入口绵甜，落口爽净，是为清香本味。"
            ),
            trace: [
                TraceStep(stage: "酿造", title: "清蒸二次清 · 地缸发酵", date: "2021-03-11",
                          location: "雲酒坊北坊 · 地缸车间",
                          detail: "高粱清蒸，地缸离地发酵，二次清茬，确保酒体纯净无杂。"),
                TraceStep(stage: "封坛", title: "不锈钢罐 · 低温储存", date: "2021-09-05",
                          location: "北坊恒温储酒区",
                          detail: "新酒低温储存，缓释新酒的暴烈，使酒体逐渐绵柔。"),
                TraceStep(stage: "出厂", title: "过滤灌装 · 赋码出厂", date: "2023-05-18",
                          location: "北坊灌装线",
                          detail: "冷冻过滤去除杂质，逐瓶赋防伪码，质检合格后出厂。")
            ],
            scanCount: 1,
            firstScannedAt: "2026-06-03 20:14",
            verifiedAt: "2026-06-03 20:14"
        )
    }

    /// 已被多次扫描：正品信息但伴随二次流通预警。
    static func rescannedSample(code: String) -> VerificationResult {
        var base = jiangxiangSample(code: code)
        base = VerificationResult(
            status: .alreadyScanned,
            code: code,
            product: base.product,
            trace: base.trace,
            scanCount: 7,
            firstScannedAt: "2024-01-08 11:32",
            verifiedAt: "2026-06-03 20:14"
        )
        return base
    }
}
