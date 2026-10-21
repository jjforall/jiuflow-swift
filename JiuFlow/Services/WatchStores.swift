import Foundation

// MARK: - Watch History (recently watched)

struct WatchHistoryEntry: Codable {
    let videoId: String
    let watchedAt: Date
}

/// Records which videos the user opened, most recent first.
/// Persisted to UserDefaults as JSON. This is "recently watched", not true resume —
/// WKWebView playback position is not accessible without a JS bridge.
final class WatchHistoryStore: ObservableObject {
    static let shared = WatchHistoryStore()

    private let key = "watchHistory"
    private let maxEntries = 20

    @Published private(set) var entries: [WatchHistoryEntry] = []

    private init() {
        load()
    }

    func record(videoId: String) {
        entries.removeAll { $0.videoId == videoId }
        entries.insert(WatchHistoryEntry(videoId: videoId, watchedAt: Date()), at: 0)
        if entries.count > maxEntries {
            entries = Array(entries.prefix(maxEntries))
        }
        save()
    }

    /// Most recent video IDs (up to `limit`).
    func recentVideoIds(limit: Int = 10) -> [String] {
        Array(entries.prefix(limit)).map(\.videoId)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([WatchHistoryEntry].self, from: data)
        else { return }
        entries = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}

// MARK: - Favorites

/// Writer for the `favoriteVideoIds` AppStorage key that FavoritesView reads.
/// Persists a JSON-encoded Set<String> so both stay in sync.
final class FavoritesStore: ObservableObject {
    static let shared = FavoritesStore()

    private let key = "favoriteVideoIds"

    @Published private(set) var ids: Set<String> = []

    private init() {
        load()
    }

    func isFavorite(_ videoId: String) -> Bool {
        ids.contains(videoId)
    }

    func toggle(_ videoId: String) {
        if ids.contains(videoId) {
            ids.remove(videoId)
        } else {
            ids.insert(videoId)
        }
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode(Set<String>.self, from: data)
        else { return }
        ids = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(ids) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
