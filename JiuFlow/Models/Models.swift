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
    let name_en: String?
    let slug: String?
    let home_dojo: String?
    let avatar_url: String?
    let featured: Bool?
    let bio: String?
    let bio_ja: String?
    let bio_en: String?
    let achievements: String?
    let titles: String?
    let stats: String?
    let social_links: String?

    var displayName: String {
        display_name ?? name_ja ?? "不明"
    }

    var displayBio: String {
        bio_ja ?? bio ?? bio_en ?? ""
    }

    /// Parse lineage from stats JSON
    var lineage: String? {
        guard let s = stats, let data = s.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return json["lineage"] as? String
    }

    var style: String? {
        guard let s = stats, let data = s.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return json["style"] as? String
    }

    var weight: String? {
        guard let s = stats, let data = s.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return json["weight"] as? String
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
    let description: String?
    let video_url: String?
    let video_title: String?
    let tips: String?
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

// MARK: - Tournament

struct Tournament: Codable, Identifiable {
    let id: String
    let name: String?
    let name_ja: String?
    let slug: String?
    let year: Int?
    let date_start: String?
    let date_end: String?
    let location: String?
    let description: String?
    let description_ja: String?
    let organization: String?
    let level: String?
    let is_featured: Bool?

    var displayName: String {
        name_ja ?? name ?? "不明"
    }

    var displayDescription: String {
        description_ja ?? description ?? ""
    }

    var displayDate: String {
        guard let start = date_start else { return "" }
        if let end = date_end, end != start {
            return "\(String(start.prefix(10))) ~ \(String(end.prefix(10)))"
        }
        return String(start.prefix(10))
    }
}

struct TournamentsResponse: Codable {
    let tournaments: [Tournament]
}

// MARK: - Forum Thread

struct ForumThread: Codable, Identifiable {
    let id: String
    let display_name: String?
    let category: String?
    let title: String?
    let body: String?
    let created_at: String?
    let updated_at: String?
    let reply_count: Int?
    let is_pinned: Bool?

    var displayTitle: String {
        title ?? "無題"
    }

    var categoryLabel: String {
        switch category {
        case "general": return "一般"
        case "technique": return "テクニック"
        case "tournament": return "大会"
        case "dojo": return "道場"
        case "gear": return "道具"
        default: return category ?? ""
        }
    }

    var relativeDate: String {
        guard let dateStr = created_at else { return "" }
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

struct ForumThreadsResponse: Codable {
    let threads: [ForumThread]
}

// MARK: - Instructor Course

struct InstructorCourse: Codable, Identifiable {
    let id: String
    let instructor_name: String?
    let instructor_dojo: String?
    let instructor_belt: String?
    let title: String?
    let description: String?
    let thumbnail_url: String?
    let price_jpy: Int?
    let video_count: Int?
    let published_at: String?

    var displayTitle: String {
        title ?? "無題"
    }

    var priceLabel: String {
        guard let price = price_jpy else { return "無料" }
        if price == 0 { return "無料" }
        return "¥\(price.formatted())"
    }

    var beltColor: Color {
        switch instructor_belt?.lowercased() {
        case "black": return .white
        case "brown": return .brown
        case "purple": return .purple
        case "blue": return .blue
        default: return .gray
        }
    }
}

struct InstructorsResponse: Codable {
    let courses: [InstructorCourse]
}

// MARK: - Game Plan

struct GamePlan: Codable, Identifiable {
    let id: String
    let name: String?
    let description: String?
    let style: String?
    let difficulty: String?
    let positions: [GamePlanPosition]?

    var displayName: String {
        name ?? "無題のゲームプラン"
    }
}

struct GamePlanPosition: Codable, Identifiable {
    var id: String { position ?? UUID().uuidString }
    let position: String?
    let techniques: [String]?
}

import SwiftUI
