import SwiftUI

struct ContentView: View {
    @EnvironmentObject var castSession: CastSessionManager
    @EnvironmentObject var mirrorController: MirrorController
    @EnvironmentObject var iptvController: IPTVController

    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            mirrorTab
                .tabItem {
                    Label("Mirror", systemImage: "rectangle.on.rectangle")
                }
                .tag(0)

            IPTVContainerView()
                .tabItem {
                    Label("IPTV", systemImage: "tv")
                }
                .tag(1)
        }
    }

    // MARK: - Mirror Tab

    private var mirrorTab: some View {
        NavigationStack {
            VStack(spacing: 0) {
                statusBanner
                    .animation(.easeInOut, value: mirrorController.state)

                if castSession.isConnected {
                    MirrorControlView()
                } else {
                    DeviceListView()
                }
            }
            .navigationTitle("CastMirror")
            .toolbar {
                if castSession.isConnected {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Disconnect") {
                            // Fix #2: Stop mirroring fully before ending the Cast session.
                            Task {
                                await mirrorController.stopMirroring(castSession: castSession)
                                castSession.disconnect()
                            }
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var statusBanner: some View {
        let state = mirrorController.state

        HStack {
            Circle()
                .fill(statusColor(for: state))
                .frame(width: 10, height: 10)

            Text(state.statusText)
                .font(.subheadline)
                .fontWeight(.medium)

            Spacer()

            if castSession.isConnected, let name = castSession.connectedDeviceName {
                Text(name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(statusColor(for: state).opacity(0.1))
    }

    private func statusColor(for state: MirrorState) -> Color {
        switch state {
        case .idle: return .gray
        case .connecting: return .orange
        case .mirroring: return .green
        case .error: return .red
        }
    }
}
