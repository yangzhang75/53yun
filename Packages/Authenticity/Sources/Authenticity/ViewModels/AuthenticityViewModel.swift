import Foundation
import Observation

// MARK: - 验真 ViewModel（MVVM）
//
// 仅依赖 `AuthenticityProviding` 协议，与具体网络实现解耦。
// 负责：输入态、加载态、结果态、错误态的统一管理。

@MainActor
@Observable
public final class AuthenticityViewModel {

    /// 界面阶段。
    public enum Phase: Equatable {
        case idle            // 等待输入
        case verifying       // 验真中
        case result(VerificationResult)
        case failure(String) // 错误提示文案
    }

    // MARK: 状态
    public var code: String = ""
    public private(set) var phase: Phase = .idle

    /// 当前输入是否可提交（本地预校验）。
    public var canSubmit: Bool {
        AuthCodeValidator.isValid(code) && !isVerifying
    }

    public var isVerifying: Bool {
        if case .verifying = phase { return true }
        return false
    }

    // MARK: 依赖
    private let service: AuthenticityProviding
    private var task: Task<Void, Never>?

    public init(service: AuthenticityProviding) {
        self.service = service
    }

    // MARK: 动作

    /// 提交验真（来源：手输或扫码）。
    /// - Parameters:
    ///   - rawCode: 若传入则覆盖当前 `code`（扫码回调使用）。
    ///   - channel: 来源渠道。
    public func verify(rawCode: String? = nil, channel: VerificationChannel = .manual) {
        if let rawCode { code = rawCode }
        let submitted = code

        task?.cancel()
        phase = .verifying

        task = Task { [service] in
            do {
                let result = try await service.verify(code: submitted, channel: channel)
                guard !Task.isCancelled else { return }
                phase = .result(result)
            } catch let error as AuthenticityError {
                guard !Task.isCancelled, error != .cancelled else { return }
                phase = .failure(error.errorDescription ?? "验真失败，请稍后再试")
            } catch is CancellationError {
                // 主动取消，保持现状。
            } catch {
                guard !Task.isCancelled else { return }
                phase = .failure("验真失败，请稍后再试")
            }
        }
    }

    /// 重置回输入态。
    public func reset() {
        task?.cancel()
        phase = .idle
    }

    /// 清空输入与状态。
    public func clear() {
        task?.cancel()
        code = ""
        phase = .idle
    }
}
