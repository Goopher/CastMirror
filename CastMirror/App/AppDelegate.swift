import UIKit
import GoogleCast

@MainActor
class AppDelegate: NSObject, UIApplicationDelegate {

    // MARK: – Replace with your registered Cast App ID
    static let castAppID = "YOUR_APP_ID"

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let criteria = GCKDiscoveryCriteria(applicationID: Self.castAppID)
        let options = GCKCastOptions(discoveryCriteria: criteria)
        options.physicalVolumeButtonsWillControlDeviceVolume = true
        GCKCastContext.setSharedInstanceWith(options)

        GCKLogger.sharedInstance().delegate = self
        return true
    }
}

// MARK: - GCKLoggerDelegate

extension AppDelegate: GCKLoggerDelegate {
    func logMessage(
        _ message: String,
        at level: GCKLoggerLevel,
        fromFunction function: String,
        location: String
    ) {
        #if DEBUG
        if level == .error || level == .warning {
            print("📺 Cast [\(level)]: \(message)")
        }
        #endif
    }
}
