import SwiftUI
import AVFoundation

// MARK: - QRScannerView

struct QRScannerView: UIViewRepresentable {
    var onScan: (String) -> Void
    var onError: (String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onScan: onScan, onError: onError) }

    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        let session = AVCaptureSession()
        session.sessionPreset = .hd1280x720

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            onError(tr("カメラにアクセスできません"))
            return view
        }
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return view }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(context.coordinator, queue: .main)
        output.metadataObjectTypes = [.qr]

        view.session = session
        context.coordinator.session = session

        DispatchQueue.global(qos: .userInitiated).async { session.startRunning() }
        return view
    }

    func updateUIView(_ uiView: CameraPreviewView, context: Context) {}

    static func dismantleUIView(_ uiView: CameraPreviewView, coordinator: Coordinator) {
        coordinator.session?.stopRunning()
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var onScan: (String) -> Void
        var onError: (String) -> Void
        var session: AVCaptureSession?
        var hasScanned = false

        init(onScan: @escaping (String) -> Void, onError: @escaping (String) -> Void) {
            self.onScan = onScan
            self.onError = onError
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput,
                            didOutput objects: [AVMetadataObject],
                            from connection: AVCaptureConnection) {
            guard !hasScanned,
                  let obj = objects.first as? AVMetadataMachineReadableCodeObject,
                  let str = obj.stringValue else { return }
            hasScanned = true
            session?.stopRunning()
            onScan(str)
        }
    }
}

// MARK: - Camera Preview

class CameraPreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    var session: AVCaptureSession? {
        didSet {
            previewLayer.session = session
            previewLayer.videoGravity = .resizeAspectFill
        }
    }
}

// MARK: - QR Check-in Sheet

struct QRCheckinSheet: View {
    let tournamentId: String
    @EnvironmentObject var api: APIService
    @Environment(\.dismiss) private var dismiss
    @State private var scanning = true
    @State private var result: QRCheckinResult?
    @State private var errorMsg: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                if scanning {
                    QRScannerView(
                        onScan: { code in
                            scanning = false
                            Task { await handleScan(code) }
                        },
                        onError: { msg in
                            scanning = false
                            errorMsg = msg
                        }
                    )
                    .ignoresSafeArea()

                    // Overlay guide
                    VStack {
                        Spacer()
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.jfRed, lineWidth: 2)
                                .frame(width: 240, height: 240)
                            Text(tr("会員証のQRコードをスキャン"))
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Capsule())
                                .offset(y: 130)
                        }
                        Spacer()
                    }
                } else if let r = result {
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.15))
                                .frame(width: 100, height: 100)
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 56))
                                .foregroundStyle(.green)
                        }
                        VStack(spacing: 6) {
                            Text(tr("チェックイン完了"))
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                            Text(r.name)
                                .font(.title3.bold())
                                .foregroundStyle(Color.jfRed)
                            BeltBadge(belt: r.belt)
                        }
                        Button(tr("次の選手")) { scanning = true; result = nil; errorMsg = nil }
                            .buttonStyle(.borderedProminent)
                            .tint(Color.jfRed)
                    }
                } else if let err = errorMsg {
                    VStack(spacing: 16) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(.red)
                        Text(err)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                        Button(tr("再スキャン")) { scanning = true; result = nil; errorMsg = nil }
                            .buttonStyle(.borderedProminent)
                            .tint(Color.jfRed)
                    }
                    .padding()
                }
            }
            .navigationTitle(tr("QRチェックイン"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(tr("閉じる")) { dismiss() }
                        .foregroundStyle(Color.jfRed)
                }
            }
        }
    }

    private func handleScan(_ code: String) async {
        // Strip URL prefix if member card encodes a URL
        let memberNumber = code.components(separatedBy: "/").last ?? code
        do {
            let res = try await api.checkinByQR(tournamentId: tournamentId, memberNumber: memberNumber)
            result = res
        } catch {
            errorMsg = error.localizedDescription
        }
    }
}

// MARK: - BeltBadge (reusable)

struct BeltBadge: View {
    let belt: String
    private var color: Color {
        switch belt.lowercased() {
        case "white": return Color(white: 0.85)
        case "blue": return Color(red: 0.15, green: 0.39, blue: 0.92)
        case "purple": return Color(red: 0.49, green: 0.23, blue: 0.93)
        case "brown": return Color(red: 0.57, green: 0.25, blue: 0.05)
        case "black": return Color(white: 0.25)
        default: return Color.jfRed
        }
    }
    var body: some View {
        Text(belt.uppercased())
            .font(.caption2.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color)
            .clipShape(Capsule())
    }
}
