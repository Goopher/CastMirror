import Foundation

enum MirrorState: Equatable {
    case idle
    case connecting
    case mirroring
    case error(String)

    var statusText: String {
        switch self {
        case .idle:
            return "Ready"
        case .connecting:
            return "Connecting…"
        case .mirroring:
            return "Mirroring"
        case .error(let message):
            return "Error: \(message)"
        }
    }

    var isActive: Bool {
        if case .mirroring = self { return true }
        return false
    }
}
