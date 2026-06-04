import Foundation

// MARK: - 防伪验真 共享数据模型
//
// 设计原则：数据模型与网络层、UI 层完全解耦。
// - 所有 `Codable` 模型对应后端 JSON 协议（详见 README「接口文档」）。
// - 使用稳定的 snake_case → camelCase 映射，便于后端无痛接入。
// - 不依赖 Engine 包：本包内自带轻量 `AuthAroma`（香型）枚举，避免跨包耦合。
//   集成阶段如需与 Engine.AromaType 对齐，仅需在适配层做一次映射。

// MARK: 香型

/// 白酒香型（本包自有，独立于计算模块）。
public enum AuthAroma: String, Codable, Sendable, CaseIterable {
    case qingxiang   // 清香
    case jiangxiang  // 酱香
    case nongxiang   // 浓香
    case unknown     // 未知 / 后端新增时的兜底

    /// 解码时对未知值做兜底，保证后端新增香型不会导致整体解析失败。
    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = AuthAroma(rawValue: raw) ?? .unknown
    }

    /// 中文展示名。
    public var displayName: String {
        switch self {
        case .qingxiang:  return "清香型"
        case .jiangxiang: return "酱香型"
        case .nongxiang:  return "浓香型"
        case .unknown:    return "—"
        }
    }
}

// MARK: 验真状态

/// 验真结果状态。
public enum VerificationStatus: String, Codable, Sendable {
    /// 正品
    case authentic
    /// 仿冒 / 验证为假
    case counterfeit
    /// 防伪码无法识别（系统中不存在）
    case unknown
    /// 该码此前已被扫描验证过（疑似翻新/二次流通，需警惕）
    case alreadyScanned = "already_scanned"

    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = VerificationStatus(rawValue: raw) ?? .unknown
    }

    /// 是否视为「验真通过」（仅 authentic 展示完整溯源）。
    public var isAuthentic: Bool { self == .authentic }
}

// MARK: 产品信息

/// 验真成功后返回的酒品信息。
public struct AuthProduct: Codable, Sendable, Hashable {
    public let name: String          // 商品名，如「53° 雲 · 酱香典藏」
    public let batch: String         // 批次号
    public let vintage: Int          // 年份
    public let aroma: AuthAroma      // 香型
    public let abv: Double           // 酒精度
    public let netVolumeML: Int      // 净含量（毫升）
    public let distillery: String    // 酒厂 / 酒坊
    public let story: String         // 酒厂故事

    public init(
        name: String,
        batch: String,
        vintage: Int,
        aroma: AuthAroma,
        abv: Double,
        netVolumeML: Int,
        distillery: String,
        story: String
    ) {
        self.name = name
        self.batch = batch
        self.vintage = vintage
        self.aroma = aroma
        self.abv = abv
        self.netVolumeML = netVolumeML
        self.distillery = distillery
        self.story = story
    }

    private enum CodingKeys: String, CodingKey {
        case name, batch, vintage, aroma, abv, story
        case netVolumeML = "net_volume_ml"
        case distillery
    }
}

// MARK: 溯源时间线

/// 溯源阶段（酿造 → 封坛 → 出厂 …）。
public struct TraceStep: Codable, Sendable, Identifiable, Hashable {
    public let id: UUID
    public let stage: String     // 阶段标签：酿造 / 封坛 / 出厂
    public let title: String     // 标题，如「端午制曲 · 重阳下沙」
    public let date: String      // 展示用日期（后端已格式化，UI 不做时区换算）
    public let location: String  // 地点
    public let detail: String    // 详情

    public init(
        id: UUID = UUID(),
        stage: String,
        title: String,
        date: String,
        location: String,
        detail: String
    ) {
        self.id = id
        self.stage = stage
        self.title = title
        self.date = date
        self.location = location
        self.detail = detail
    }

    // 后端通常不下发 id，这里允许缺省并本地生成，保证 Identifiable 稳定。
    private enum CodingKeys: String, CodingKey {
        case id, stage, title, date, location, detail
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        self.stage = try c.decode(String.self, forKey: .stage)
        self.title = try c.decode(String.self, forKey: .title)
        self.date = try c.decode(String.self, forKey: .date)
        self.location = try c.decode(String.self, forKey: .location)
        self.detail = try c.decode(String.self, forKey: .detail)
    }
}

// MARK: 验真完整结果

/// 一次验真调用的完整结果（领域模型，UI 直接消费）。
public struct VerificationResult: Codable, Sendable, Hashable {
    public let status: VerificationStatus
    public let code: String              // 被查询的防伪码
    public let product: AuthProduct?     // 仅正品/已扫描时存在
    public let trace: [TraceStep]        // 溯源时间线（可空）
    public let scanCount: Int            // 累计被验证次数
    public let firstScannedAt: String?   // 首次验证时间（展示用字符串）
    public let verifiedAt: String?       // 本次验证时间（展示用字符串）

    public init(
        status: VerificationStatus,
        code: String,
        product: AuthProduct? = nil,
        trace: [TraceStep] = [],
        scanCount: Int = 0,
        firstScannedAt: String? = nil,
        verifiedAt: String? = nil
    ) {
        self.status = status
        self.code = code
        self.product = product
        self.trace = trace
        self.scanCount = scanCount
        self.firstScannedAt = firstScannedAt
        self.verifiedAt = verifiedAt
    }

    private enum CodingKeys: String, CodingKey {
        case status, code, product, trace
        case scanCount = "scan_count"
        case firstScannedAt = "first_scanned_at"
        case verifiedAt = "verified_at"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.status = try c.decode(VerificationStatus.self, forKey: .status)
        self.code = try c.decode(String.self, forKey: .code)
        self.product = try c.decodeIfPresent(AuthProduct.self, forKey: .product)
        self.trace = (try? c.decode([TraceStep].self, forKey: .trace)) ?? []
        self.scanCount = (try? c.decode(Int.self, forKey: .scanCount)) ?? 0
        self.firstScannedAt = try c.decodeIfPresent(String.self, forKey: .firstScannedAt)
        self.verifiedAt = try c.decodeIfPresent(String.self, forKey: .verifiedAt)
    }
}

// MARK: 请求模型

/// 验真请求来源渠道。
public enum VerificationChannel: String, Codable, Sendable {
    case scan    // 相机扫码
    case manual  // 手动输入
}

/// 发送给后端的验真请求体。
public struct VerificationRequest: Codable, Sendable {
    public let code: String
    public let channel: VerificationChannel

    public init(code: String, channel: VerificationChannel) {
        self.code = code
        self.channel = channel
    }
}
