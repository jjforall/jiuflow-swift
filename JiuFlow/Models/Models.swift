import Foundation

// MARK: - Video

struct Video: Codable, Identifiable {
    let id: String
    let title: String?
    let description: String?
    let thumbnail_url: String?
    let video_url: String?
    let video_type: String?
    let view_count: Int?
    let created_at: String?
    let author_name: String?
    let author_avatar: String?

    var displayTitle: String {
        title ?? "無題"
    }

    var displayDescription: String {
        description ?? ""
    }

    func fullThumbnailURL(baseURL: String) -> URL? {
        guard let thumb = thumbnail_url else { return nil }
        if thumb.hasPrefix("http") { return URL(string: thumb) }
        return URL(string: "\(baseURL)\(thumb)")
    }

    var videoTypeColor: String {
        switch video_type {
        case "tutorial": return "blue"
        case "match": return "red"
        case "highlight": return "orange"
        case "breakdown": return "purple"
        default: return "gray"
        }
    }
}

struct VideosResponse: Codable {
    let videos: [Video]
}

// MARK: - Athlete

struct Athlete: Codable, Identifiable {
    let id: String
    let display_name: String?
    let name_ja: String?
    let slug: String?
    let home_dojo: String?
    let avatar_url: String?
    let featured: Bool?

    var displayName: String {
        display_name ?? name_ja ?? "不明"
    }
}

struct AthletesResponse: Codable {
    let athletes: [Athlete]
}

// MARK: - News

struct NewsItem: Codable, Identifiable {
    let id: Int
    let title: String?
    let summary: String?
    let slug: String?
    let category: String?
    let author: String?
    let published_at: String?
    let is_featured: Bool?
    let og_image_url: String?

    var displayTitle: String {
        title ?? "無題"
    }

    var displaySummary: String {
        summary ?? ""
    }

    var categoryLabel: String {
        switch category {
        case "bjj": return "大会"
        case "site": return "サイト"
        case "technique": return "テクニック"
        default: return category ?? ""
        }
    }

    var relativeDate: String {
        guard let dateStr = published_at else { return "" }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateStr) {
            let diff = Calendar.current.dateComponents([.day, .hour, .minute], from: date, to: Date())
            if let days = diff.day, days > 0 {
                return days == 1 ? "昨日" : "\(days)日前"
            }
            if let hours = diff.hour, hours > 0 {
                return "\(hours)時間前"
            }
            if let minutes = diff.minute, minutes > 0 {
                return "\(minutes)分前"
            }
            return "たった今"
        }
        // Try simpler format
        let simple = DateFormatter()
        simple.dateFormat = "yyyy-MM-dd"
        if let date = simple.date(from: String(dateStr.prefix(10))) {
            let diff = Calendar.current.dateComponents([.day], from: date, to: Date())
            if let days = diff.day, days > 0 {
                return days == 1 ? "昨日" : "\(days)日前"
            }
            return "今日"
        }
        return String(dateStr.prefix(10))
    }
}

struct NewsResponse: Codable {
    let news: [NewsItem]
}

// MARK: - Dojo (matches actual API response)

struct Dojo: Codable, Identifiable {
    let id: String
    let name: String?
    let name_ja: String?
    let slug: String?
    let location: String?
    let description: String?
    let description_ja: String?
    let logo_url: String?
    let is_verified: Bool?

    var displayName: String {
        name_ja ?? name ?? "不明"
    }

    var displayDescription: String {
        description_ja ?? description ?? ""
    }

    var displayLocation: String {
        location ?? ""
    }
}

struct DojosResponse: Codable {
    let dojos: [Dojo]
}

// MARK: - TechniqueNode (tree structure, matches actual API)

struct TechniqueNode: Codable, Identifiable {
    let id: String
    let label: String?
    let emoji: String?
    let prob: Int?
    let desc: String?
    let priority: Int?
    let recommended: Bool?
    let warning: Bool?
    let children: [TechniqueNode]?

    var displayLabel: String {
        if let e = emoji, let l = label {
            return "\(e) \(l)"
        }
        return label ?? "不明"
    }

    var childCount: Int {
        (children?.count ?? 0) + (children?.reduce(0) { $0 + $1.childCount } ?? 0)
    }
}

// MARK: - Technique Flow (graph structure)

struct FlowNode: Codable, Identifiable {
    let id: String
    let label: String?
    let node_type: String?  // start, decision, action, position, submission
    let x: Double?
    let y: Double?
}

struct FlowEdge: Codable, Identifiable {
    let id: String
    let source_id: String?
    let target_id: String?
    let label: String?
    let category: String?  // flow, yes, no, counter, transition
}

struct TechniqueFlowResponse: Codable {
    let nodes: [FlowNode]
    let edges: [FlowEdge]
}

// MARK: - Magic Link Auth

struct MagicLinkRequest: Codable {
    let email: String
}

struct MagicLinkResponse: Codable {
    let message: String?
    let error: String?
}

// MARK: - Auth

struct AuthUser: Codable {
    let id: String
    let email: String
    let display_name: String?
}

struct MagicLinkVerifyResponse: Codable {
    let token: String
    let user: AuthUser
}
