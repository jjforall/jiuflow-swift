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
    let website: String?
    let tier: String?       // "official", "partner", "listed"
    let can_book: Int?      // 1 = can book, 0 = external only

    var displayName: String {
        name_ja ?? name ?? "不明"
    }

    var displayDescription: String {
        description_ja ?? description ?? ""
    }

    var displayLocation: String {
        location ?? ""
    }

    // MARK: - Tier system

    var isOfficial: Bool { tier == "official" }
    var isPartner: Bool { tier == "partner" }
    var canBook: Bool { (can_book ?? 0) == 1 }

    var tierBadge: (String, Color)? {
        switch tier {
        case "official": return ("SJJJF公認", .jfGold)
        case "partner": return ("提携道場", .blue)
        default: return nil
        }
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
    let role: String?

    var isPro: Bool {
        role == "pro" || role == "admin" || role == "instructor"
    }

    var isAdmin: Bool {
        role == "admin"
    }
}

struct MagicLinkVerifyResponse: Codable {
    let token: String
    let user: AuthUser
}

// MARK: - Monthly Video View Limit

struct MonthlyViewStatus: Codable {
    let count: Int
    let limit: Int
    let remaining: Int
    let is_premium: Bool
}

// MARK: - Tournament

struct Tournament: Codable, Identifiable {
    let id: String
    let name: String?
    let name_ja: String?
    let name_en: String?
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
    let is_international: Bool?
    let country: String?
    let gi: Bool?
    let nogi: Bool?
    let has_results: Bool?

    func displayName(lang: String) -> String {
        if lang == "en" { return name_en ?? name ?? name_ja ?? "Unknown" }
        return name_ja ?? name ?? "不明"
    }

    func displayDescription(lang: String) -> String {
        if lang == "en" { return description ?? description_ja ?? "" }
        return description_ja ?? description ?? ""
    }

    var displayDate: String {
        guard let start = date_start else { return "" }
        if let end = date_end, end != start {
            return "\(String(start.prefix(10))) ~ \(String(end.prefix(10)))"
        }
        return String(start.prefix(10))
    }

    // Keep backward compat
    var displayName: String { displayName(lang: "ja") }
    var displayDescription: String { displayDescription(lang: "ja") }
}

struct TournamentsResponse: Codable {
    let tournaments: [Tournament]
}

// MARK: - Tournament Detail

struct TournamentDetail: Codable {
    let id: String
    let name: String?
    let name_ja: String?
    let name_en: String?
    let slug: String?
    let date_start: String?
    let date_end: String?
    let location: String?
    let organizer: String?
    let description: String?
    let description_ja: String?
    let venue: String?
    let venue_image_url: String?
    let entry_fee: String?
    let registration_url: String?
    let weight_classes: [String]?
    let organization: String?
    let country: String?
    let gi: Bool?
    let nogi: Bool?
    let results: [TournamentResultYear]?

    func displayName(lang: String) -> String {
        if lang == "en" { return name_en ?? name ?? name_ja ?? "Unknown" }
        return name_ja ?? name ?? "不明"
    }

    func displayDescription(lang: String) -> String {
        if lang == "en" { return description ?? description_ja ?? "" }
        return description_ja ?? description ?? ""
    }

    var displayDate: String {
        guard let start = date_start else { return "" }
        if let end = date_end, end != start {
            return "\(String(start.prefix(10))) ~ \(String(end.prefix(10)))"
        }
        return String(start.prefix(10))
    }
}

struct TournamentResultYear: Codable, Identifiable {
    let year: Int
    let divisions: [TournamentResultDivision]
    var id: Int { year }
}

struct TournamentResultDivision: Codable, Identifiable {
    let division: String
    let gold: String
    let silver: String
    let bronze: [String]
    var id: String { division }
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

// MARK: - SJJJF Models

struct SjjjfMember: Codable, Identifiable {
    let id: String
    let user_id: String
    let member_number: String
    let belt: String
    let weight_class: String?
    let dojo_id: String?
    let dojo_name: String?
    let membership_type: String
    let valid_until: String?
    let points: Int
    let created_at: String

    var beltColor: Color {
        switch belt.lowercased() {
        case "white": return .white
        case "blue": return .blue
        case "purple": return .purple
        case "brown": return Color(red: 0.55, green: 0.27, blue: 0.07)
        case "black": return Color(red: 0.15, green: 0.15, blue: 0.15)
        default: return .gray
        }
    }
}

struct SjjjfMemberResponse: Codable {
    let member: SjjjfMember?
}

struct SjjjfRegisterResponse: Codable {
    let ok: Bool?
    let member: SjjjfMember?
    let error: String?
}

struct TournamentEntry: Codable, Identifiable {
    let id: String
    let user_id: String
    let member_id: String
    let tournament_id: String
    let weight_class: String
    let gi_nogi: String
    let belt: String
    let entry_number: String
    let payment_status: String
    let amount_jpy: Int
    let status: String
    let place: Int?
    let points_earned: Int?
    let created_at: String
    let display_name: String
    let member_number: String
    let dojo_name: String?
}

struct TournamentEntriesResponse: Codable {
    let entries: [TournamentEntry]
    let count: Int?
}

struct Ranking: Codable, Identifiable {
    let id: String
    let member_id: String
    let user_id: String
    let display_name: String
    let belt: String
    let weight_class: String
    let points: Int
    let rank: Int?
    let wins: Int
    let losses: Int
    let gold: Int
    let silver: Int
    let bronze: Int
    let season: String
    let dojo_name: String?

    var beltColor: Color {
        switch belt.lowercased() {
        case "white": return .white
        case "blue": return .blue
        case "purple": return .purple
        case "brown": return Color(red: 0.55, green: 0.27, blue: 0.07)
        case "black": return Color(red: 0.15, green: 0.15, blue: 0.15)
        default: return .gray
        }
    }
}

struct RankingsResponse: Codable {
    let rankings: [Ranking]
}

struct ShopProduct: Codable, Identifiable {
    let id: String
    let name: String
    let name_ja: String?
    let description: String?
    let description_ja: String?
    let price_jpy: Int
    let compare_price_jpy: Int?
    let category: String
    let images: String?
    let stock: Int
    let is_limited: Int
    let sort_order: Int

    var displayName: String { name_ja ?? name }
    var displayDescription: String { description_ja ?? description ?? "" }
    var imageUrls: [String] {
        guard let images = images,
              let parsed = try? JSONDecoder().decode([String].self, from: Data(images.utf8))
        else { return [] }
        return parsed
    }
    var isLimited: Bool { is_limited == 1 }
}

struct ProductsResponse: Codable {
    let products: [ShopProduct]
}

struct LiveStream: Codable, Identifiable {
    let id: String
    let tournament_id: String?
    let title: String
    let description: String?
    let stream_url: String?
    let status: String
    let is_ppv: Int
    let ppv_price_jpy: Int?
    let scheduled_at: String?
    let viewer_count: Int?
    let tournament_name: String?

    var isLive: Bool { status == "live" }
    var isPPV: Bool { is_ppv == 1 }
}

struct LiveStreamsResponse: Codable {
    let streams: [LiveStream]
}

struct Sponsor: Codable, Identifiable {
    let id: String
    let name: String
    let logo_url: String?
    let website_url: String?
    let tier: String
    let banner_url: String?
}

struct SponsorsResponse: Codable {
    let sponsors: [Sponsor]
}

// MARK: - Daily Drills & Streaks

struct DailyDrill: Codable {
    let id: String
    let technique_id: String
    let technique_name: String?
    let technique_name_ja: String?
    let category: String?
    let belt_level: String?
    let video_url: String?
    let date: String

    var displayName: String { technique_name_ja ?? technique_name ?? "Today's Technique" }
}

struct DailyDrillResponse: Codable {
    let drill: DailyDrill?
}

struct UserStreak: Codable {
    let current_streak: Int
    let longest_streak: Int
    let last_completed_date: String?
    let total_completed: Int
}

struct StreakResponse: Codable {
    let streak: UserStreak
}

struct DrillCompleteResponse: Codable {
    let ok: Bool?
    let streak: UserStreak?
}

// MARK: - Social Feed

struct FeedEvent: Codable, Identifiable {
    let id: String
    let user_id: String
    let display_name: String
    let event_type: String
    let title: String
    let detail: String?
    let kudos_count: Int
    let has_kudoed: Bool
    let created_at: String

    var eventIcon: String {
        switch event_type {
        case "drill_complete": return "flame.fill"
        case "practice": return "figure.martial.arts"
        case "roll": return "person.2.fill"
        case "tournament_entry": return "trophy.fill"
        case "ai_analysis": return "brain.head.profile"
        case "belt_promotion": return "medal.fill"
        default: return "star.fill"
        }
    }

    var eventColor: Color {
        switch event_type {
        case "drill_complete": return .orange
        case "tournament_entry": return .jfGold
        case "ai_analysis": return .purple
        case "belt_promotion": return .jfGold
        default: return .jfRed
        }
    }
}

struct FeedResponse: Codable {
    let events: [FeedEvent]
}

// MARK: - Live Classes

struct LiveClass: Codable, Identifiable {
    let id: String
    let title: String
    let description: String?
    let instructor_name: String
    let instructor_belt: String
    let scheduled_at: String
    let duration_minutes: Int
    let stream_url: String?
    let status: String
    let is_pro_only: Int
    let attendee_count: Int?
    let recording_url: String?

    var isLive: Bool { status == "live" }
    var isProOnly: Bool { is_pro_only == 1 }
}

struct LiveClassesResponse: Codable {
    let classes: [LiveClass]
}

// MARK: - AI Analysis

struct AIAnalysis: Codable {
    let score: Int
    let positions: [PositionStat]?
    let strengths: [String]?
    let weaknesses: [String]?
    let recommendations: [TechniqueRecommendation]?
}

struct PositionStat: Codable {
    let name: String
    let time_pct: Int
    let transitions: Int
}

struct TechniqueRecommendation: Codable, Identifiable {
    let technique_id: String
    let name: String
    let reason: String
    var id: String { technique_id }
}

struct AIAnalysisResponse: Codable {
    let ok: Bool?
    let analysis: AIAnalysis?
    let error: String?
}
