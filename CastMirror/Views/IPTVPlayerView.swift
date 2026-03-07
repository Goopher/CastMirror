import SwiftUI

struct IPTVPlayerView: View {
    @EnvironmentObject var iptvController: IPTVController
    @EnvironmentObject var castSession: CastSessionManager

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Now playing indicator
            VStack(spacing: 16) {
                Image(systemName: "tv.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)
                    .symbolEffect(.pulse, isActive: true)

                if let channel = iptvController.currentChannel {
                    Text(channel.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    if let categoryName = iptvController.selectedCategory?.categoryName {
                        Text(categoryName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                if castSession.isConnected, let deviceName = castSession.connectedDeviceName {
                    HStack(spacing: 6) {
                        Image(systemName: "cast")
                        Text("Casting to \(deviceName)")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                }
            }

            Spacer()

            // Controls
            VStack(spacing: 16) {
                // Stop button
                Button {
                    iptvController.stopPlayback(castSession: castSession)
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 56))
                        Text("Stop Casting")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .padding(.horizontal, 40)

                // Back to channels
                Button {
                    iptvController.stopPlayback(castSession: castSession)
                    iptvController.goBackToChannels()
                } label: {
                    Label("Back to Channels", systemImage: "list.bullet")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
            }
            .padding(.bottom, 32)
        }
    }
}
