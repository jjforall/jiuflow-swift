import Foundation

/// Maps original video Cloudflare Stream UIDs to dubbed versions by language
/// Source: dubbed-videos.json (Supabase UUIDs → language → Modal-hosted MP4 URLs)
/// Also maps CF Stream UIDs to Supabase UUIDs for lookup
@MainActor
class DubbedVideoService: ObservableObject {
    static let shared = DubbedVideoService()

    // Supabase UUID → { lang: url }
    private var dubbedMap: [String: [String: String]] = [:]

    // CF Stream UID → Supabase UUID (for reverse lookup)
    // Built from CF Stream video names like "technique-UUID-en"
    private var cfToSupabase: [String: String] = [:]

    // Known mappings: CF Stream UID of Japanese original → Supabase UUID
    private let knownMappings: [String: String] = [
        // These are the CF Stream UIDs used in our tutorial video seeds
        "e56b9cc9691157a5531b0df4ef049983": "ae0b996c-ef9b-4296-97bf-c495f37b6f5f", // クローズドガードのポスチャー
        "4c4dd31416d4c4ef687f5ebef6bb9112": "22471163-b674-4cd6-8ffd-dcab8bf537bb", // 三角絞め
        "3445644e19e3df5a1e1529144cd30263": "12b6bc61-e8a3-4058-aa4a-a5163d26c440", // アームバー
        "1606d1aa938c8ca0f4ce243d69ed3d86": "8a2a241b-fe77-4742-9a2e-82dcb3a45322", // クロスチョーク
        "890bdeb0fb621bb0677d75b8c9620a24": "d3473439-3fb4-4e26-b913-1b98b3a487ac", // テレフォンスイープ
        "28cab1aeb8059ccdb49f9c335391de7e": "b8cc2ea5-3cd2-4681-94d2-52f93d66c94d", // スイープ
        "c984c530fe70a747114c84c23ba693ba": "6dc84b1b-0c09-456d-b8f7-f4249998cdcc", // 連携技
        "7cd3ed96c240ecc77c80e4dea85acbf6": "2285246e-e393-4a70-8f75-d3b55d98d356", // ベース崩しQ&A
    ]

    init() {
        loadDubbedVideos()
    }

    private func loadDubbedVideos() {
        guard let url = Bundle.main.url(forResource: "dubbed-videos", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let map = try? JSONDecoder().decode([String: [String: String]].self, from: data) else {
            return
        }
        dubbedMap = map
    }

    /// Get the best video URL for the given language
    /// - Parameters:
    ///   - originalURL: The original Cloudflare Stream embed URL (Japanese)
    ///   - language: Target language code (ja, en, pt, es, etc.)
    /// - Returns: The dubbed URL if available, otherwise the original
    func videoURL(for originalURL: String, language: String) -> String {
        // Japanese = always use original
        if language == "ja" { return originalURL }

        // Extract CF Stream UID from URL
        // Format: https://iframe.cloudflarestream.com/STREAM_UID
        guard let cfUID = extractStreamUID(from: originalURL) else {
            return originalURL
        }

        // Look up Supabase UUID
        if let supabaseUUID = knownMappings[cfUID] ?? cfToSupabase[cfUID],
           let langs = dubbedMap[supabaseUUID] {
            // Try exact language match first
            if let url = langs[language] { return url }
            // Fall back to English
            if let url = langs["en"] { return url }
        }

        return originalURL
    }

    /// Check if dubbed version exists for a language
    func hasDub(for originalURL: String, language: String) -> Bool {
        if language == "ja" { return true }
        guard let cfUID = extractStreamUID(from: originalURL) else { return false }
        guard let supabaseUUID = knownMappings[cfUID] ?? cfToSupabase[cfUID],
              let langs = dubbedMap[supabaseUUID] else { return false }
        return langs[language] != nil || langs["en"] != nil
    }

    /// Get available languages for a video
    func availableLanguages(for originalURL: String) -> [String] {
        guard let cfUID = extractStreamUID(from: originalURL) else { return ["ja"] }
        guard let supabaseUUID = knownMappings[cfUID] ?? cfToSupabase[cfUID],
              let langs = dubbedMap[supabaseUUID] else { return ["ja"] }
        return ["ja"] + langs.keys.sorted()
    }

    private func extractStreamUID(from url: String) -> String? {
        // https://iframe.cloudflarestream.com/STREAM_UID
        guard url.contains("cloudflarestream.com/") else { return nil }
        return url.components(separatedBy: "/").last
    }
}
