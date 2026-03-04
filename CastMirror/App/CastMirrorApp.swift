import SwiftUI

@main
struct CastMirrorApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var castSession = CastSessionManager()
    @StateObject private var mirrorController = MirrorController()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(castSession)
                .environmentObject(mirrorController)
                // Fix #5: If the Cast session drops while mirroring, clean up the
                // stream server and capture session rather than hanging in .mirroring state.
                .onAppear {
                    castSession.onSessionEnd = { [weak mirrorController, weak castSession] in
                        guard let mirrorController, let castSession else { return }
                        Task { @MainActor in
                            await mirrorController.stopMirroring(castSession: castSession)
                        }
                    }
                }
        }
    }
}
