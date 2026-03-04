import Foundation
import CoreMedia
import Combine

@MainActor
final class MirrorController: NSObject, ObservableObject {

    @Published var state: MirrorState = .idle
    @Published var fps: Int = 0
    @Published var jpegQuality: CGFloat = 0.5 {
        didSet { encoder.jpegQuality = jpegQuality }
    }
    // Fix #4: Expose scale factor so the UI can control resolution vs. bandwidth.
    @Published var scaleFactor: CGFloat = 0.5 {
        didSet { encoder.scaleFactor = scaleFactor }
    }

    private let captureService = ScreenCaptureService()
    private let encoder = FrameEncoder()
    private let streamServer = MJPEGStreamServer()

    // Fix #7: Dedicated serial queue keeps encoding off the ReplayKit callback thread
    // and off the main actor, preventing frame drops and UI jank.
    private let encodingQueue = DispatchQueue(
        label: "com.castmirror.encoding",
        qos: .userInteractive
    )

    private var fpsTimer: Timer?
    private var lastFrameCount = 0

    override init() {
        super.init()
        captureService.delegate = self
    }

    // MARK: - Public API

    func startMirroring(castSession: CastSessionManager) async {
        guard state != .mirroring else { return }
        state = .connecting

        do {
            try streamServer.start()
        } catch {
            state = .error("Failed to start stream server: \(error.localizedDescription)")
            return
        }

        guard let streamURL = streamServer.streamURL else {
            state = .error("Could not determine WiFi IP address. Ensure device is on WiFi.")
            streamServer.stop()
            return
        }

        castSession.sendStreamURL(streamURL)

        do {
            try await captureService.startCapture()
        } catch {
            state = .error("Screen capture failed: \(error.localizedDescription)")
            streamServer.stop()
            return
        }

        state = .mirroring
        startFPSCounter()
    }

    func stopMirroring(castSession: CastSessionManager) async {
        guard state == .mirroring || state == .connecting else { return }
        castSession.sendStopCommand()

        do {
            try await captureService.stopCapture()
        } catch {
            print("Stop capture error: \(error)")
        }

        streamServer.stop()
        stopFPSCounter()
        state = .idle
        fps = 0
    }

    // MARK: - FPS Counter

    private func startFPSCounter() {
        lastFrameCount = 0
        fpsTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            let current = self.streamServer.frameCount
            Task { @MainActor in
                self.fps = current - self.lastFrameCount
                self.lastFrameCount = current
            }
        }
    }

    private func stopFPSCounter() {
        fpsTimer?.invalidate()
        fpsTimer = nil
    }
}

// MARK: - ScreenCaptureDelegate

extension MirrorController: ScreenCaptureDelegate {

    // Fix #7: Encoding dispatched to a dedicated serial queue instead of blocking
    // the ReplayKit callback thread. FrameEncoder is only ever touched on encodingQueue.
    nonisolated func screenCapture(didReceive sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        encodingQueue.async { [weak self] in
            guard let self else { return }
            guard let jpegData = self.encoder.encode(pixelBuffer) else { return }
            self.streamServer.pushFrame(jpegData)
        }
    }
}
