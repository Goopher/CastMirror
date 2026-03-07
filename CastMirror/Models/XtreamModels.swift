import Foundation

// MARK: - Credentials

struct XtreamCredentials: Codable, Equatable {
    var server: String
    var username: String
    var password: String

    /// Base URL with protocol, trimming trailing slashes.
    var baseURL: String {
        let trimmed = server.trimmingCharacters(in: CharacterSet(charactersIn: "/ "))
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return trimmed
        }
        return "http://\(trimmed)"
    }

    /// Player API endpoint.
    var playerAPIURL: String {
        "\(baseURL)/player_api.php?username=\(username)&password=\(password)"
    }

    /// Build a live stream URL for a given stream ID.
    func liveStreamURL(streamID: Int, extension ext: String = "m3u8") -> String {
        "\(baseURL)/live/\(username)/\(password)/\(streamID).\(ext)"
    }
}

// MARK: - Category

struct XtreamCategory: Codable, Identifiable, Equatable {
    let categoryID: String
    let categoryName: String
    let parentID: Int

    var id: String { categoryID }

    enum CodingKeys: String, CodingKey {
        case categoryID = "category_id"
        case categoryName = "category_name"
        case parentID = "parent_id"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        categoryID = try container.decode(String.self, forKey: .categoryID)
        categoryName = try container.decode(String.self, forKey: .categoryName)
        // parent_id can come as Int or String
        if let intVal = try? container.decode(Int.self, forKey: .parentID) {
            parentID = intVal
        } else if let strVal = try? container.decode(String.self, forKey: .parentID),
                  let intVal = Int(strVal) {
            parentID = intVal
        } else {
            parentID = 0
        }
    }
}

// MARK: - Live Stream (Channel)

struct XtreamChannel: Codable, Identifiable, Equatable {
    let num: Int?
    let name: String
    let streamType: String?
    let streamID: Int
    let streamIcon: String?
    let epgChannelID: String?
    let categoryID: String?

    var id: Int { streamID }

    var displayName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    enum CodingKeys: String, CodingKey {
        case num
        case name
        case streamType = "stream_type"
        case streamID = "stream_id"
        case streamIcon = "stream_icon"
        case epgChannelID = "epg_channel_id"
        case categoryID = "category_id"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        num = try? container.decode(Int.self, forKey: .num)
        name = try container.decode(String.self, forKey: .name)
        streamType = try? container.decode(String.self, forKey: .streamType)
        streamIcon = try? container.decode(String.self, forKey: .streamIcon)
        epgChannelID = try? container.decode(String.self, forKey: .epgChannelID)

        // stream_id may come as Int or String
        if let intVal = try? container.decode(Int.self, forKey: .streamID) {
            streamID = intVal
        } else if let strVal = try? container.decode(String.self, forKey: .streamID),
                  let intVal = Int(strVal) {
            streamID = intVal
        } else {
            streamID = 0
        }

        // category_id may come as Int or String
        if let strVal = try? container.decode(String.self, forKey: .categoryID) {
            categoryID = strVal
        } else if let intVal = try? container.decode(Int.self, forKey: .categoryID) {
            categoryID = String(intVal)
        } else {
            categoryID = nil
        }
    }
}

// MARK: - Server Info (for authentication check)

struct XtreamServerInfo: Codable {
    let userInfo: XtreamUserInfo?
    let serverInfo: XtreamServer?

    enum CodingKeys: String, CodingKey {
        case userInfo = "user_info"
        case serverInfo = "server_info"
    }
}

struct XtreamUserInfo: Codable {
    let username: String?
    let password: String?
    let status: String?
    let activeCons: String?
    let maxConnections: String?

    enum CodingKeys: String, CodingKey {
        case username, password, status
        case activeCons = "active_cons"
        case maxConnections = "max_connections"
    }
}

struct XtreamServer: Codable {
    let url: String?
    let port: String?
    let httpsPort: String?
    let rtmpPort: String?
    let serverProtocol: String?
    let timeZone: String?

    enum CodingKeys: String, CodingKey {
        case url, port
        case httpsPort = "https_port"
        case rtmpPort = "rtmp_port"
        case serverProtocol = "server_protocol"
        case timeZone = "timezone"
    }
}
