import Foundation
import Swifter

final class MJPEGStreamServer {

    private var server: HttpServer?
    private let port: UInt16 = 8080
    private let boundary = "castmirror-frame"

    // Fix #1: UUID-keyed dict — removal is always correct regardless of other disconnects.
    // Write closure returns false when the client has disconnected.
    private var clients: [UUID: (Data) -> Bool] = [:]
    private let clientsLock = NSLock()

    // Fix #6: Separate lock for frame timing state, accessed from multiple threads.
    private let frameLock = NSLock()
    private var _lastFrameTime: CFAbsoluteTime = 0
    private var _frameCount: Int = 0

    private let minFrameInterval: TimeInterval = 1.0 / 15.0

    // Thread-safe read for FPS counter on the main thread.
    var frameCount: Int {
        clientsLock.lock()
        defer { clientsLock.unlock() }
        return _frameCount
    }

    func start() throws {
        let server = HttpServer()

        server["/stream"] = { [weak self] _ in
            guard let self else { return .raw(500, "Server Error", nil, nil) }
            let id = UUID()

            return .raw(200, "OK", [
                "Content-Type": "multipart/x-mixed-replace; boundary=\(self.boundary)",
                "Cache-Control": "no-cache, no-store",
                "Connection": "keep-alive",
                "Access-Control-Allow-Origin": "*"
            ]) { writer in
                // Fix #8: Write closure returns Bool — false means client is dead.
                let writeFrame: (Data) -> Bool = { jpegData in
                    let header = "--\(self.boundary)\r\nContent-Type: image/jpeg\r\nContent-Length: \(jpegData.count)\r\n\r\n"
                    do {
                        try writer.write(Array(header.utf8))
                        try writer.write(Array(jpegData))
                        try writer.write(Array("\r\n".utf8))
                        return true
                    } catch {
                        return false
                    }
                }

                self.clientsLock.lock()
                self.clients[id] = writeFrame
                self.clientsLock.unlock()

                while self.server != nil {
                    Thread.sleep(forTimeInterval: 0.5)
                }

                self.clientsLock.lock()
                self.clients.removeValue(forKey: id)
                self.clientsLock.unlock()
            }
        }

        server["/health"] = { _ in .ok(.text("ok")) }

        try server.start(port)
        self.server = server
        print("MJPEG server started on port \(port)")
    }

    func stop() {
        server?.stop()
        server = nil
        clientsLock.lock()
        clients.removeAll()
        clientsLock.unlock()
        frameLock.lock()
        _frameCount = 0
        _lastFrameTime = 0
        frameLock.unlock()
    }

    /// Push a JPEG frame to all connected clients, throttled to target FPS.
    func pushFrame(_ jpegData: Data) {
        // Fix #6: All timing state guarded by frameLock.
        let now = CFAbsoluteTimeGetCurrent()
        frameLock.lock()
        guard now - _lastFrameTime >= minFrameInterval else {
            frameLock.unlock()
            return
        }
        _lastFrameTime = now
        _frameCount += 1
        frameLock.unlock()

        // Snapshot clients without holding the lock during writes (writes can block).
        clientsLock.lock()
        let snapshot = clients
        clientsLock.unlock()

        // Fix #8: Collect dead clients and remove them after writes.
        var deadIDs: [UUID] = []
        for (id, write) in snapshot {
            if !write(jpegData) {
                deadIDs.append(id)
            }
        }

        if !deadIDs.isEmpty {
            clientsLock.lock()
            for id in deadIDs { clients.removeValue(forKey: id) }
            clientsLock.unlock()
        }
    }

    var streamURL: String? {
        guard let ip = NetworkUtility.getWiFiIPAddress() else { return nil }
        return "http://\(ip):\(port)/stream"
    }
}
