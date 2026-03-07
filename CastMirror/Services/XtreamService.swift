import Foundation

/// Handles all Xtream Codes API communication.
enum XtreamService {

    enum XtreamError: LocalizedError {
        case invalidURL
        case authenticationFailed
        case networkError(Error)
        case decodingError(Error)
        case accountDisabled

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid server URL."
            case .authenticationFailed:
                return "Authentication failed. Check your credentials."
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .decodingError(let error):
                return "Failed to parse server response: \(error.localizedDescription)"
            case .accountDisabled:
                return "Account is disabled or expired."
            }
        }
    }

    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        return URLSession(configuration: config)
    }()

    // MARK: - Authentication

    /// Authenticate with the Xtream server and return server info.
    static func authenticate(credentials: XtreamCredentials) async throws -> XtreamServerInfo {
        let urlString = credentials.playerAPIURL
        guard let url = URL(string: urlString) else {
            throw XtreamError.invalidURL
        }

        let data: Data
        do {
            let (responseData, _) = try await session.data(from: url)
            data = responseData
        } catch {
            throw XtreamError.networkError(error)
        }

        let serverInfo: XtreamServerInfo
        do {
            serverInfo = try JSONDecoder().decode(XtreamServerInfo.self, from: data)
        } catch {
            throw XtreamError.authenticationFailed
        }

        guard let userInfo = serverInfo.userInfo,
              let status = userInfo.status,
              status == "Active" else {
            if serverInfo.userInfo?.status == "Disabled" || serverInfo.userInfo?.status == "Banned" {
                throw XtreamError.accountDisabled
            }
            throw XtreamError.authenticationFailed
        }

        return serverInfo
    }

    // MARK: - Live Categories

    /// Fetch live TV categories.
    static func getLiveCategories(credentials: XtreamCredentials) async throws -> [XtreamCategory] {
        let urlString = "\(credentials.playerAPIURL)&action=get_live_categories"
        guard let url = URL(string: urlString) else {
            throw XtreamError.invalidURL
        }

        let data: Data
        do {
            let (responseData, _) = try await session.data(from: url)
            data = responseData
        } catch {
            throw XtreamError.networkError(error)
        }

        do {
            return try JSONDecoder().decode([XtreamCategory].self, from: data)
        } catch {
            throw XtreamError.decodingError(error)
        }
    }

    // MARK: - Live Streams

    /// Fetch live streams (channels), optionally filtered by category.
    static func getLiveStreams(
        credentials: XtreamCredentials,
        categoryID: String? = nil
    ) async throws -> [XtreamChannel] {
        var urlString = "\(credentials.playerAPIURL)&action=get_live_streams"
        if let categoryID {
            urlString += "&category_id=\(categoryID)"
        }

        guard let url = URL(string: urlString) else {
            throw XtreamError.invalidURL
        }

        let data: Data
        do {
            let (responseData, _) = try await session.data(from: url)
            data = responseData
        } catch {
            throw XtreamError.networkError(error)
        }

        do {
            return try JSONDecoder().decode([XtreamChannel].self, from: data)
        } catch {
            throw XtreamError.decodingError(error)
        }
    }
}
