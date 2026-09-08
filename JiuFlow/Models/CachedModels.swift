import Foundation
import SwiftData

// MARK: - SwiftData Models for offline caching

/// TTL for cached data: 24 hours
private let cacheTTLSeconds: TimeInterval = 24 * 60 * 60

@Model
final class CachedAthlete {
    @Attribute(.unique) var id: String
    var displayName: String
    var slug: String?
    var avatarUrl: String?
    var homeDojo: String?
    var bioJa: String?
    var nationality: String?
    var featured: Bool
    var cachedAt: Date

    var isExpired: Bool {
        Date().timeIntervalSince(cachedAt) > cacheTTLSeconds
    }

    init(from athlete: Athlete) {
        self.id = athlete.id
        self.displayName = athlete.displayName
        self.slug = athlete.slug
        self.avatarUrl = athlete.avatar_url
        self.homeDojo = athlete.home_dojo
        self.bioJa = athlete.bio_ja
        self.nationality = athlete.stats?.nationality
        self.featured = athlete.featured ?? false
        self.cachedAt = Date()
    }

    func update(from athlete: Athlete) {
        self.displayName = athlete.displayName
        self.slug = athlete.slug
        self.avatarUrl = athlete.avatar_url
        self.homeDojo = athlete.home_dojo
        self.bioJa = athlete.bio_ja
        self.nationality = athlete.stats?.nationality
        self.featured = athlete.featured ?? false
        self.cachedAt = Date()
    }

    func toAthlete() -> Athlete {
        Athlete(
            id: id,
            display_name: displayName,
            slug: slug,
            home_dojo: homeDojo,
            avatar_url: avatarUrl,
            featured: featured,
            bio_ja: bioJa,
            stats: nationality != nil
                ? AthleteStats(lineage: nil, style: nil, weight: nil, nationality: nationality, team: nil)
                : nil
        )
    }
}

@Model
final class CachedTournament {
    @Attribute(.unique) var id: String
    var name: String
    var nameJa: String?
    var slug: String?
    var year: Int?
    var dateStart: String?
    var location: String?
    var organizer: String?
    var cachedAt: Date

    var isExpired: Bool {
        Date().timeIntervalSince(cachedAt) > cacheTTLSeconds
    }

    init(from tournament: Tournament) {
        self.id = tournament.id
        self.name = tournament.name ?? "不明"
        self.nameJa = tournament.name_ja
        self.slug = tournament.slug
        self.year = tournament.year
        self.dateStart = tournament.date_start
        self.location = tournament.location
        self.organizer = tournament.organization
        self.cachedAt = Date()
    }

    func update(from tournament: Tournament) {
        self.name = tournament.name ?? "不明"
        self.nameJa = tournament.name_ja
        self.slug = tournament.slug
        self.year = tournament.year
        self.dateStart = tournament.date_start
        self.location = tournament.location
        self.organizer = tournament.organization
        self.cachedAt = Date()
    }

    func toTournament() -> Tournament {
        Tournament(
            id: id,
            name: name,
            name_ja: nameJa,
            name_en: nil,
            slug: slug,
            year: year,
            date_start: dateStart,
            date_end: nil,
            location: location,
            description: nil,
            description_ja: nil,
            organization: organizer,
            level: nil,
            is_featured: nil,
            is_international: nil,
            country: nil,
            gi: nil,
            nogi: nil,
            has_results: nil
        )
    }
}
