import SwiftUI

struct IPTVContainerView: View {
    @EnvironmentObject var iptvController: IPTVController
    @EnvironmentObject var castSession: CastSessionManager

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !castSession.isConnected && iptvController.isAuthenticated {
                    notConnectedBanner
                }

                content
            }
            .navigationTitle(navigationTitle)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if showBackButton {
                        Button {
                            navigateBack()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text(backButtonTitle)
                            }
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if iptvController.isAuthenticated {
                        Button("Logout") {
                            iptvController.logout()
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch iptvController.viewState {
        case .login:
            IPTVLoginView()
        case .loading(let message):
            VStack(spacing: 16) {
                Spacer()
                ProgressView()
                    .scaleEffect(1.2)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        case .categories:
            IPTVCategoryListView()
        case .channels:
            IPTVChannelListView()
        case .playing:
            IPTVPlayerView()
        case .error(let message):
            VStack(spacing: 16) {
                Spacer()
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48))
                    .foregroundStyle(.red)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Button("Try Again") {
                    if iptvController.isAuthenticated {
                        Task { await iptvController.loadCategories() }
                    } else {
                        iptvController.viewState = .login
                    }
                }
                .buttonStyle(.bordered)
                Spacer()
            }
        }
    }

    private var notConnectedBanner: some View {
        HStack {
            Image(systemName: "exclamationmark.circle")
            Text("Connect to a Chromecast device first to cast channels.")
                .font(.caption)
        }
        .foregroundStyle(.orange)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color.orange.opacity(0.1))
    }

    private var navigationTitle: String {
        switch iptvController.viewState {
        case .login: return "IPTV"
        case .loading: return "IPTV"
        case .categories: return "Categories"
        case .channels:
            return iptvController.selectedCategory?.categoryName ?? "Channels"
        case .playing(let name): return name
        case .error: return "IPTV"
        }
    }

    private var showBackButton: Bool {
        switch iptvController.viewState {
        case .channels, .playing: return true
        default: return false
        }
    }

    private var backButtonTitle: String {
        switch iptvController.viewState {
        case .playing: return "Channels"
        case .channels: return "Categories"
        default: return ""
        }
    }

    private func navigateBack() {
        switch iptvController.viewState {
        case .playing:
            iptvController.stopPlayback(castSession: castSession)
            iptvController.goBackToChannels()
        case .channels:
            iptvController.goBackToCategories()
        default:
            break
        }
    }
}
