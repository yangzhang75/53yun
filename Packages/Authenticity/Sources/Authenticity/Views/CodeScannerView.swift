import SwiftUI

#if os(iOS)
import AVFoundation

// MARK: - 相机扫码视图（仅 iOS）
//
// 隐私合规：使用相机前需在主工程 Info.plist 配置 NSCameraUsageDescription，
// 文案见 README。本视图对「未授权 / 已拒绝 / 设备不可用」均有清晰兜底 UI，
// 不会在无权限时强行调起相机。

/// 扫码结果回调。
public struct CodeScannerView: View {
    /// 扫到码后的回调（已是原始字符串，未规范化）。
    public let onScanned: (String) -> Void
    /// 用户主动关闭。
    public let onClose: () -> Void

    @State private var authorization: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)

    public init(onScanned: @escaping (String) -> Void, onClose: @escaping () -> Void) {
        self.onScanned = onScanned
        self.onClose = onClose
    }

    public var body: some View {
        ZStack {
            AuthTheme.ink.ignoresSafeArea()

            switch authorization {
            case .authorized:
                scannerLayer
            case .notDetermined:
                requestView
            default:
                deniedView
            }

            VStack {
                header
                Spacer()
            }
        }
        .task {
            if authorization == .notDetermined {
                let granted = await AVCaptureDevice.requestAccess(for: .video)
                authorization = granted ? .authorized : .denied
            }
        }
    }

    // MARK: 子视图

    private var scannerLayer: some View {
        ZStack {
            CameraPreview { value in
                onScanned(value)
            }
            .ignoresSafeArea()

            // 扫描取景框（烫金描边）。
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(AuthTheme.goldGradient, lineWidth: 2)
                .frame(width: 240, height: 240)
                .shadow(color: AuthTheme.gold.opacity(0.35), radius: 12)

            VStack {
                Spacer()
                Text("将瓶身防伪码 / 二维码置于框内")
                    .font(AuthTheme.serifTitle(16))
                    .foregroundStyle(AuthTheme.textPrimary)
                    .padding(.bottom, 80)
            }
        }
    }

    private var requestView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 48))
                .foregroundStyle(AuthTheme.gold)
            Text("正在请求相机权限…")
                .foregroundStyle(AuthTheme.textSecondary)
        }
    }

    private var deniedView: some View {
        VStack(spacing: 18) {
            Image(systemName: "camera.metering.unknown")
                .font(.system(size: 48))
                .foregroundStyle(AuthTheme.goldDim)
            Text("未获得相机权限")
                .font(AuthTheme.serifTitle(20))
                .foregroundStyle(AuthTheme.textPrimary)
            Text("扫码验真需要使用相机。\n请前往「设置」开启相机权限，或返回手动输入防伪码。")
                .multilineTextAlignment(.center)
                .font(.system(size: 14))
                .foregroundStyle(AuthTheme.textSecondary)
                .padding(.horizontal, 32)

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("前往设置")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AuthTheme.ink)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(AuthTheme.gold))
            }
        }
    }

    private var header: some View {
        HStack {
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(AuthTheme.textSecondary)
                    .padding()
            }
        }
    }
}

// MARK: - AVFoundation 预览层封装

private struct CameraPreview: UIViewRepresentable {
    let onScanned: (String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onScanned: onScanned) }

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        context.coordinator.configure(in: view)
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    static func dismantleUIView(_ uiView: PreviewView, coordinator: Coordinator) {
        coordinator.stop()
    }

    // MARK: 协调器：管理会话与扫码回调
    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        private let session = AVCaptureSession()
        private let sessionQueue = DispatchQueue(label: "com.yun53.authenticity.camera")
        private let onScanned: (String) -> Void
        private var didEmit = false

        init(onScanned: @escaping (String) -> Void) {
            self.onScanned = onScanned
        }

        func configure(in view: PreviewView) {
            sessionQueue.async { [weak self, weak view] in
                guard let self, let view else { return }
                self.session.beginConfiguration()
                guard
                    let device = AVCaptureDevice.default(for: .video),
                    let input = try? AVCaptureDeviceInput(device: device),
                    self.session.canAddInput(input)
                else {
                    self.session.commitConfiguration()
                    return
                }
                self.session.addInput(input)

                let output = AVCaptureMetadataOutput()
                if self.session.canAddOutput(output) {
                    self.session.addOutput(output)
                    output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                    // 支持二维码与常见一维条码（防伪码可能印成条码）。
                    output.metadataObjectTypes = [.qr, .code128, .code39, .ean13, .pdf417, .dataMatrix]
                }
                self.session.commitConfiguration()

                Task { @MainActor in
                    view.previewLayer.session = self.session
                    view.previewLayer.videoGravity = .resizeAspectFill
                }
                self.session.startRunning()
            }
        }

        func stop() {
            sessionQueue.async { [session] in
                if session.isRunning { session.stopRunning() }
            }
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput,
                            didOutput metadataObjects: [AVMetadataObject],
                            from connection: AVCaptureConnection) {
            guard !didEmit,
                  let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  let value = obj.stringValue else { return }
            didEmit = true
            // 轻微触觉反馈
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            onScanned(value)
        }
    }
}

/// 承载 AVCaptureVideoPreviewLayer 的 UIView。
final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}

#else

// MARK: - 非 iOS 平台兜底（macOS 预览 / 编译用）
public struct CodeScannerView: View {
    public let onScanned: (String) -> Void
    public let onClose: () -> Void

    public init(onScanned: @escaping (String) -> Void, onClose: @escaping () -> Void) {
        self.onScanned = onScanned
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 48))
                .foregroundStyle(AuthTheme.gold)
            Text("相机扫码仅在 iOS 设备上可用")
                .foregroundStyle(AuthTheme.textSecondary)
            Button("关闭", action: onClose)
                .foregroundStyle(AuthTheme.gold)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AuthTheme.ink)
    }
}
#endif
