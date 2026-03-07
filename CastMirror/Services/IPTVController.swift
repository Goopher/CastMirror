import Foundation
import Combine

@MainActor
final class IPTVController: ObservableObject {

    enum ViewState: Equatable {
        case login
        case loading(String)
        case categories
        case channels
        case playing(String) // channel name
        case error(String)
    }

    @Published var viewState: ViewState = .login
    @Published var credentials = XtreamCredentials(server: "", username: "", password: "")
    @Published var categories: [XtreamCategory] = []
    @Published var channels: [XtreamChannel] = []
    @Published var selectedCategory: XtreamCategory?
    @Published var currentChannel: XtreamChannel?
    @Published var isAuthenticated = false
    @Published var searchText = ""

    private let credentialsKey = "xtream_credentials"

    var filteredChannels: [XtreamChannel] {
        guard !searchText.isEmpty else { return channels }
        return channels.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    init() {
        loadSavedCredentials()
    }

    // MARK: - Authentication

    func login() async {
        guard !credentials.server.isEmpty,
              !credentials.username.isEmpty,
              !credentials.password.isEmpty else {
            viewState = .error("Please fill in all fields.")
            return
        }

        viewState = .loading("Authenticating...")

        do {
            let _ = try await XtreamService.authenticate(credentials: credentials)
            isAuthenticated = true
            saveCredentials()
            await loadCategories()
        } catch {
            viewState = .error(error.localizedDescription)
        }
    }

    func logout() {
        isAuthenticated = false
        categories = []
        channels = []
        selectedCategory = nil
        currentChannel = nil
        viewState = .login
        clearSavedCredentials()
    }

    // MARK: - Data Loading

    func loadCategories() async {
        viewState = .loading("Loading categories...")

        do {
            categories = try await XtreamService.getLiveCategories(credentials: credentials)
            viewState = .categories
        } catch {
            viewState = .error(error.localizedDescription)
        }
    }

    func loadChannels(for category: XtreamCategory) async {
        selectedCategory = category
        viewState = .loading("Loading channels...")

        do {
            channels = try await XtreamService.getLiveStreams(
                credentials: credentials,
                categoryID: category.categoryID
            )
            viewState = .channels
        } catch {
            viewState = .error(error.localizedDescription)
        }
    }

    // MARK: - Playback

    func playChannel(_ channel: XtreamChannel, castSession: CastSessionManager) {
        currentChannel = channel
        let streamURL = credentials.liveStreamURL(streamID: channel.streamID)
        castSession.sendVideoURL(streamURL)
        viewState = .playing(channel.displayName)
    }

    func stopPlayback(castSession: CastSessionManager) {
        castSession.sendStopCommand()
        currentChannel = nil
        viewState = .channels
    }

    // MARK: - Navigation

    func goBackToCategories() {
        channels = []
        selectedCategory = nil
        searchText = ""
        viewState = .categories
    }

    func goBackToChannels() {
        currentChannel = nil
        viewState = .channels
    }

    // MARK: - Credential Persistence

    private func saveCredentials() {
        if let data = try? JSONEncoder().encode(credentials) {
            UserDefaults.standard.set(data, forKey: credentialsKey)
        }
    }

    private func loadSavedCredentials() {
        guard let data = UserDefaults.standard.data(forKey: credentialsKey),
              let saved = try? JSONDecoder().decode(XtreamCredentials.self, from: data) else {
            return
        }
        credentials = saved
    }

    private func clearSavedCredentials() {
        UserDefaults.standard.removeObject(forKey: credentialsKey)
        credentials = XtreamCredentials(server: "", username: "", password: "")
    }
}
