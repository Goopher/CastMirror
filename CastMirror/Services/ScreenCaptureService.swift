import ReplayKit
import CoreMedia

protocol ScreenCaptureDelegate: AnyObject {
    func screenCapture(didReceive sampleBuffer: CMSampleBuffer)
}

final class ScreenCaptureService {

    weak var delegate: ScreenCaptureDelegate?

    private let recorder = RPScreenRecorder.shared()

    var isRecording: Bool { recorder.isRecording }
    var isAvailable: Bool { recorder.isAvailable }

    func startCapture() async throws {
        guard recorder.isAvailable else {
            throw CaptureError.notAvailable
        }

        try await recorder.startCapture { [weak self] sampleBuffer, sampleBufferType, error in
            guard error == nil else { return }
            guard sampleBufferType == .video else { return }
            self?.delegate?.screenCapture(didReceive: sampleBuffer)
        }
    }

    func stopCapture() async throws {
        guard recorder.isRecording else { return }
        try await recorder.stopCapture()
    }

    enum CaptureError: LocalizedError {
        case notAvailable

        var errorDescription: String? {
            switch self {
            case .notAvailable:
                return "Screen recording is not available on this device."
            }
        }
    }
}
