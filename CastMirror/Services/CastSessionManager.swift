import Foundation
import GoogleCast
import Combine

final class CastSessionManager: NSObject, ObservableObject {

    static let customNamespace = "urn:x-cast:com.castmirror.stream"

    @Published var discoveredDevices: [GCKDevice] = []
    @Published var isConnected = false
    @Published var connectedDeviceName: String?

    // Fix #5: Called when a live Cast session ends unexpectedly.
    var onSessionEnd: (() -> Void)?

    private var discoveryManager: GCKDiscoveryManager {
        GCKCastContext.sharedInstance().discoveryManager
    }

    private var sessionManager: GCKSessionManager {
        GCKCastContext.sharedInstance().sessionManager
    }

    // Fix #9: Removed unused `messageChannel: GCKGenericMediaControlChannel?`
    private var castChannel: CastMirrorChannel?

    override init() {
        super.init()
        discoveryManager.add(self)
        sessionManager.add(self)
        discoveryManager.startDiscovery()
    }

    deinit {
        discoveryManager.stopDiscovery()
        discoveryManager.remove(self)
        sessionManager.remove(self)
    }

    // MARK: - Public API

    func connectToDevice(_ device: GCKDevice) {
        sessionManager.startSession(with: device)
    }

    func disconnect() {
        sessionManager.endSessionAndStopCasting(true)
    }

    /// Sends the MJPEG stream URL to the Cast receiver.
    func sendStreamURL(_ url: String) {
        guard let channel = castChannel else {
            print("Cast channel not available")
            return
        }
        // Fix #3: Use JSONSerialization — safe for URLs with special characters.
        channel.sendJSON(["type": "stream", "url": url])
    }

    /// Sends a video stream URL (HLS / direct) to the Cast receiver for IPTV playback.
    func sendVideoURL(_ url: String) {
        guard let channel = castChannel else {
            print("Cast channel not available")
            return
        }
        channel.sendJSON(["type": "video", "url": url])
    }

    /// Sends a stop command to the Cast receiver.
    func sendStopCommand() {
        castChannel?.sendJSON(["type": "stop"])
    }
}

// MARK: - GCKDiscoveryManagerListener

extension CastSessionManager: GCKDiscoveryManagerListener {

    func didUpdateDeviceList() {
        let count = discoveryManager.deviceCount
        var devices: [GCKDevice] = []
        for i in 0..<count {
            devices.append(discoveryManager.device(at: i))
        }
        DispatchQueue.main.async {
            self.discoveredDevices = devices
        }
    }
}

// MARK: - GCKSessionManagerListener

extension CastSessionManager: GCKSessionManagerListener {

    func sessionManager(
        _ sessionManager: GCKSessionManager,
        didStart session: GCKCastSession
    ) {
        let channel = CastMirrorChannel(namespace: Self.customNamespace)
        session.add(channel)
        castChannel = channel

        DispatchQueue.main.async {
            self.isConnected = true
            self.connectedDeviceName = session.device.friendlyName
        }
    }

    func sessionManager(
        _ sessionManager: GCKSessionManager,
        didEnd session: GCKSession,
        withError error: Error?
    ) {
        castChannel = nil
        DispatchQueue.main.async {
            self.isConnected = false
            self.connectedDeviceName = nil
            // Fix #5: Notify so MirrorController can clean up if mirroring was active.
            if error != nil {
                self.onSessionEnd?()
            }
        }
    }

    func sessionManager(
        _ sessionManager: GCKSessionManager,
        didFailToStart session: GCKSession,
        withError error: Error
    ) {
        castChannel = nil
        DispatchQueue.main.async {
            self.isConnected = false
            self.connectedDeviceName = nil
        }
    }
}

// MARK: - Custom Cast Channel

final class CastMirrorChannel: GCKCastChannel {

    override func didReceiveTextMessage(_ message: String) {
        print("Receiver message: \(message)")
    }

    // Fix #3: JSON built with JSONSerialization, not string interpolation.
    func sendJSON(_ dict: [String: String]) {
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let message = String(data: data, encoding: .utf8) else { return }
        var error: GCKError?
        sendTextMessage(message, error: &error)
        if let error {
            print("Failed to send cast message: \(error.localizedDescription)")
        }
    }
}
