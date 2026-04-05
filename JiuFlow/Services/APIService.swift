import Foundation
import SwiftUI
import SwiftData

@MainActor
class APIService: ObservableObject {
    let baseURL = "https://jiuflow-ssr.fly.dev"
    private let session: URLSession
    /// ModelContext injected from SwiftUI environment for SwiftData caching
    var modelContext: ModelContext?

    @Published var videos: [Video] = []
    @Published var athletes: [Athlete] = []
    @Published var news: [NewsItem] = []
    @Published var dojos: [Dojo] = []
    @Published var techniqueRoot: TechniqueNode?
    @Published var flowNodes: [FlowNode] = []
    @Published var flowEdges: [FlowEdge] = []
    @Published var tournaments: [Tournament] = []
    @Published var forumThreads: [ForumThread] = []
    @Published var instructorCourses: [InstructorCourse] = []
    @Published var gamePlanTemplates: [[String: Any]] = []
    @Published var isLoading = false
    @Published var error: String?

    // Auth state
    @Published var isLoggedIn = false
    @Published var currentUser: AuthUser?
    @Published var authToken: String?
    @Published var isAuthenticating = false
    @Published var authError: String?
    @Published var isGuestMode = false  // Demo mode without login

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        // Large URL cache for thumbnails (50MB memory, 200MB disk)
        config.urlCache = URLCache(memoryCapacity: 50_000_000, diskCapacity: 200_000_000)
        config.requestCachePolicy = .returnCacheDataElseLoad
        self.session = URLSession(configuration: config)

        // Restore auth from Keychain (survives reinstall)
        if let token = KeychainHelper.loadString("auth_token"),
           let data = KeychainHelper.load("auth_user"),
           let user = try? JSONDecoder().decode(AuthUser.self, from: data) {
            self.authToken = token
            self.currentUser = user
            self.isLoggedIn = true
            // Refresh user profile from server (role may have changed)
            Task { await loadCurrentUser() }
        }
    }

    private func fetch<T: Codable>(_ path: String, as type: T.Type) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }

    func loadVideos() async {
        isLoading = true
        error = nil
        do {
            let result = try await fetch("/api/v1/videos", as: VideosResponse.self)
            videos = result.videos
        } catch {
            self.error = "動画の読み込みに失敗しました"
            print("Videos error: \(error)")
        }
        isLoading = false
    }

    func loadAthletes() async {
        isLoading = true
        error = nil
        do {
            let result = try await fetch("/api/v1/athletes", as: AthletesResponse.self)
            athletes = result.athletes
            // Cache to SwiftData
            cacheAthletes(result.athletes)
        } catch {
            // Offline fallback: load from SwiftData cache
            if let cached = loadCachedAthletes(), !cached.isEmpty {
                athletes = cached
                print("Athletes loaded from cache (\(cached.count) items)")
            } else {
                self.error = "選手情報の読み込みに失敗しました"
            }
            print("Athletes error: \(error)")
        }
        isLoading = false
    }

    // MARK: - SwiftData Cache (Athletes)

    private func cacheAthletes(_ athletes: [Athlete]) {
        guard let context = modelContext else { return }
        for athlete in athletes {
            let descriptor = FetchDescriptor<CachedAthlete>(
                predicate: #Predicate { $0.id == athlete.id }
            )
            if let existing = try? context.fetch(descriptor).first {
                existing.update(from: athlete)
            } else {
                context.insert(CachedAthlete(from: athlete))
            }
        }
        try? context.save()
    }

    private func loadCachedAthletes() -> [Athlete]? {
        guard let context = modelContext else { return nil }
        let descriptor = FetchDescriptor<CachedAthlete>(
            sortBy: [SortDescriptor(\.displayName)]
        )
        guard let cached = try? context.fetch(descriptor), !cached.isEmpty else { return nil }
        return cached.map { $0.toAthlete() }
    }

    func loadNews() async {
        isLoading = true
        error = nil
        do {
            let result = try await fetch("/api/v1/news", as: NewsResponse.self)
            news = result.news
        } catch {
            self.error = "ニュースの読み込みに失敗しました"
            print("News error: \(error)")
        }
        isLoading = false
    }

    func loadDojos() async {
        isLoading = true
        error = nil
        do {
            let result = try await fetch("/api/v1/dojos", as: DojosResponse.self)
            dojos = result.dojos
        } catch {
            self.error = "道場情報の読み込みに失敗しました"
            print("Dojos error: \(error)")
        }
        isLoading = false
    }

    func loadTechniques() async {
        isLoading = true
        error = nil
        do {
            let result = try await fetch("/api/v1/technique-map", as: TechniqueNode.self)
            techniqueRoot = result
        } catch {
            self.error = "テクニックの読み込みに失敗しました"
            print("Techniques error: \(error)")
        }
        isLoading = false
    }

    func loadTechniqueFlow() async {
        isLoading = true
        error = nil
        do {
            let result = try await fetch("/api/v1/technique-flow", as: TechniqueFlowResponse.self)
            flowNodes = result.nodes
            flowEdges = result.edges
        } catch {
            self.error = "フローの読み込みに失敗しました"
            print("TechniqueFlow error: \(error)")
        }
        isLoading = false
    }

    func loadTournaments() async {
        do {
            let result = try await fetch("/api/v1/tournaments", as: TournamentsResponse.self)
            tournaments = result.tournaments
            // Cache to SwiftData
            cacheTournaments(result.tournaments)
        } catch {
            // Offline fallback: load from SwiftData cache
            if let cached = loadCachedTournaments(), !cached.isEmpty {
                tournaments = cached
                print("Tournaments loaded from cache (\(cached.count) items)")
            }
            print("Tournaments error: \(error)")
        }
    }

    // MARK: - SwiftData Cache (Tournaments)

    private func cacheTournaments(_ tournaments: [Tournament]) {
        guard let context = modelContext else { return }
        for tournament in tournaments {
            let descriptor = FetchDescriptor<CachedTournament>(
                predicate: #Predicate { $0.id == tournament.id }
            )
            if let existing = try? context.fetch(descriptor).first {
                existing.update(from: tournament)
            } else {
                context.insert(CachedTournament(from: tournament))
            }
        }
        try? context.save()
    }

    private func loadCachedTournaments() -> [Tournament]? {
        guard let context = modelContext else { return nil }
        let descriptor = FetchDescriptor<CachedTournament>(
            sortBy: [SortDescriptor(\.dateStart)]
        )
        guard let cached = try? context.fetch(descriptor), !cached.isEmpty else { return nil }
        return cached.map { $0.toTournament() }
    }

    func loadTournamentDetail(year: Int, slug: String) async -> TournamentDetail? {
        do {
            let url = URL(string: "\(baseURL)/api/v1/tournaments/\(year)/\(slug)")!
            let (data, response) = try await session.data(from: url)
            if let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode {
                return try JSONDecoder().decode(TournamentDetail.self, from: data)
            }
        } catch {
            print("TournamentDetail error: \(error)")
        }
        return nil
    }

    func loadForumThreads() async {
        do {
            let result = try await fetch("/api/v1/forum/threads", as: ForumThreadsResponse.self)
            forumThreads = result.threads
        } catch {
            print("Forum error: \(error)")
        }
    }

    func createForumThread(title: String, body: String, category: String) async -> Bool {
        guard let url = URL(string: "\(baseURL)/api/v1/forum/threads") else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let payload = ["title": title, "body": body, "category": category]
        request.httpBody = try? JSONEncoder().encode(payload)
        do {
            let (_, response) = try await session.data(for: request)
            if let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode {
                await loadForumThreads()
                return true
            }
        } catch { }
        return false
    }

    func loadInstructorCourses() async {
        do {
            let result = try await fetch("/api/v1/instructors", as: InstructorsResponse.self)
            instructorCourses = result.courses
        } catch {
            print("Instructors error: \(error)")
        }
    }

    func loadGamePlans() async {
        do {
            let (data, _) = try await session.data(for: URLRequest(url: URL(string: "\(baseURL)/api/v1/game-plans")!))
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let templates = json["templates"] as? [[String: Any]] {
                gamePlanTemplates = templates
            }
        } catch {
            print("GamePlans error: \(error)")
        }
    }

    // MARK: - Magic Link Auth (correct endpoint)

    func sendMagicLink(email: String) async -> (success: Bool, message: String) {
        guard let url = URL(string: "\(baseURL)/api/v1/auth/magic") else {
            return (false, "URLエラー")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let encodedEmail = email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? email
        request.httpBody = "email=\(encodedEmail)&platform=ios".data(using: .utf8)

        do {
            let (_, response) = try await session.data(for: request)
            if let http = response as? HTTPURLResponse, 200..<400 ~= http.statusCode {
                return (true, "ログインリンクを送信しました！\nメールを確認してください。")
            }
            return (false, "送信に失敗しました")
        } catch {
            return (false, "ネットワークエラー: \(error.localizedDescription)")
        }
    }

    func verifyMagicLink(token: String) async -> (success: Bool, message: String) {
        guard let url = URL(string: "\(baseURL)/api/v1/auth/magic/verify?token=\(token)&platform=ios") else {
            return (false, "URLエラー")
        }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return (false, "サーバーからの応答がありません")
            }

            if 200..<300 ~= http.statusCode {
                let result = try JSONDecoder().decode(MagicLinkVerifyResponse.self, from: data)
                self.authToken = result.token
                self.currentUser = result.user
                self.isLoggedIn = true
                // Persist to Keychain
                KeychainHelper.save("auth_token", string: result.token)
                if let userData = try? JSONEncoder().encode(result.user) {
                    KeychainHelper.save("auth_user", data: userData)
                }
                return (true, "ログインしました！")
            } else if http.statusCode == 401 {
                return (false, "リンクが無効または期限切れです。もう一度ログインしてください")
            } else {
                return (false, "認証に失敗しました (エラー \(http.statusCode))")
            }
        } catch let error as URLError where error.code == .timedOut {
            return (false, "接続がタイムアウトしました。インターネット接続を確認してください")
        } catch let error as URLError {
            return (false, "ネットワークエラー: \(error.localizedDescription)")
        } catch {
            return (false, "認証エラー: \(error.localizedDescription)")
        }
    }

    /// Called from deep link — the server already created the session,
    /// so we just store the token and mark as logged in.
    func loginWithSessionToken(_ token: String) {
        self.authToken = token
        self.isLoggedIn = true
        // We don't have user details yet, fetch them
        KeychainHelper.save("auth_token", string: token)
        // Try to load user profile from server
        Task {
            await loadCurrentUser()
        }
    }

    private func loadCurrentUser() async {
        guard let token = authToken,
              let url = URL(string: "\(baseURL)/api/me") else { return }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("jiuflow_session=\(token)", forHTTPHeaderField: "Cookie")
        // Skip cache - always fetch fresh from server
        request.cachePolicy = .reloadIgnoringLocalCacheData
        do {
            let (data, response) = try await session.data(for: request)
            if let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let loggedIn = json["logged_in"] as? Bool ?? false
                let tier = json["tier"] as? String
                let isPremium = json["is_premium"] as? Bool ?? false
                // Use tier-derived role if available (Stripe subscribers get "pro" from server)
                let role = json["role"] as? String
                let name = json["display_name"] as? String ?? json["name"] as? String
                let email = json["email"] as? String
                let userId = json["id"] as? String

                print("[loadCurrentUser] logged_in=\(loggedIn) role=\(role ?? "nil") tier=\(tier ?? "nil") premium=\(isPremium) email=\(email ?? "nil")")

                if loggedIn, let uid = userId ?? self.currentUser?.id {
                    let updated = AuthUser(
                        id: uid,
                        email: email ?? self.currentUser?.email ?? "",
                        display_name: name ?? self.currentUser?.display_name,
                        role: role
                    )
                    self.currentUser = updated
                    self.isLoggedIn = true
                    if let userData = try? JSONEncoder().encode(updated) {
                        KeychainHelper.save("auth_user", data: userData)
                    }
                }
            }
        } catch {
            print("[loadCurrentUser] error: \(error)")
        }
    }

    func logout() {
        authToken = nil
        currentUser = nil
        isLoggedIn = false
        isGuestMode = false
        KeychainHelper.delete("auth_token")
        KeychainHelper.delete("auth_user")
    }

    /// Enter guest mode (demo mode without login) — allows browsing app content
    func enterGuestMode() {
        self.isGuestMode = true
        self.isLoggedIn = false
        self.currentUser = nil
        self.authToken = nil
    }

    /// Exit guest mode
    func exitGuestMode() {
        self.isGuestMode = false
    }

    // MARK: - Technique Progress

    func loadTechniqueProgress() async -> [String: TechniqueProgress] {
        guard isLoggedIn else { return [:] }
        do {
            let result = try await fetch("/api/technique-progress", as: TechniqueProgressMap.self)
            return result.progress
        } catch {
            print("TechniqueProgress load error: \(error)")
            return [:]
        }
    }

    func updateTechniqueProgress(techniqueId: String, level: Int) async -> Bool {
        guard let url = URL(string: "\(baseURL)/api/technique-progress") else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try? JSONEncoder().encode(TechniqueProgressUpdate(technique_id: techniqueId, level: level))
        do {
            let (_, response) = try await session.data(for: request)
            if let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode {
                return true
            }
        } catch {}
        return false
    }

    // MARK: - OTT Exchange (Deep Link secure auth)

    func exchangeOTTCode(_ code: String) async {
        guard let url = URL(string: "\(baseURL)/api/v1/auth/ott/exchange?code=\(code)") else {
            self.authError = "Invalid authentication URL"
            return
        }
        self.isAuthenticating = true
        self.authError = nil
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                self.authError = "Login failed. Please try again."
                self.isAuthenticating = false
                return
            }
            guard 200..<300 ~= http.statusCode else {
                // Try to extract server error message
                if let body = try? JSONDecoder().decode([String: String].self, from: data),
                   let serverError = body["error"] {
                    self.authError = "Login failed: \(serverError)"
                } else {
                    self.authError = "Login failed (error \(http.statusCode)). Please try again."
                }
                self.isAuthenticating = false
                return
            }
            let result = try JSONDecoder().decode(MagicLinkVerifyResponse.self, from: data)
            self.authToken = result.token
            self.currentUser = result.user
            self.isLoggedIn = true
            KeychainHelper.save("auth_token", string: result.token)
            if let userData = try? JSONEncoder().encode(result.user) {
                KeychainHelper.save("auth_user", data: userData)
            }
        } catch let error as URLError where error.code == .timedOut {
            self.authError = "Login timed out. Please check your connection and try again."
        } catch {
            self.authError = "Login failed: \(error.localizedDescription)"
        }
        self.isAuthenticating = false
    }

    /// Called from Universal Link — verifies magic token via API and logs in.
    /// This handles the case where the app intercepts the magic link URL directly
    /// (e.g., on iPad where Universal Links work but custom URL scheme redirects may not).
    /// This is especially important on iPad where custom URL schemes may be blocked by Safari.
    func verifyMagicLinkFromUniversalLink(token: String) async {
        self.isAuthenticating = true
        self.authError = nil

        // Log the action for debugging
        print("[Magic Link Verify] Verifying token from Universal Link (platform=ios)")

        let result = await verifyMagicLink(token: token)
        if !result.success {
            self.authError = result.message
            print("[Magic Link Verify] Failed: \(result.message)")
        } else {
            print("[Magic Link Verify] Success: User logged in")
        }
        self.isAuthenticating = false
    }

    // MARK: - Video View Limits

    func getMonthlyVideoViews() async throws -> MonthlyViewStatus {
        return try await fetch("/api/v1/video-views/monthly", as: MonthlyViewStatus.self)
    }

    // MARK: - SJJJF API

    func getSjjjfMember() async throws -> SjjjfMember? {
        let result = try await fetch("/api/v1/sjjjf/member", as: SjjjfMemberResponse.self)
        return result.member
    }

    func registerSjjjfMember(belt: String, weightClass: String?, dojoName: String?) async throws -> SjjjfMember? {
        var body: [String: Any] = ["belt": belt]
        if let wc = weightClass { body["weight_class"] = wc }
        if let dn = dojoName { body["dojo_name"] = dn }
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        var request = URLRequest(url: URL(string: "\(baseURL)/api/v1/sjjjf/register")!)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, _) = try await session.data(for: request)
        let response = try JSONDecoder().decode(SjjjfRegisterResponse.self, from: data)
        return response.member
    }

    func enterTournament(tournamentId: String, weightClass: String, giNogi: String = "gi") async throws -> Bool {
        let body: [String: Any] = ["tournament_id": tournamentId, "weight_class": weightClass, "gi_nogi": giNogi]
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        var request = URLRequest(url: URL(string: "\(baseURL)/api/v1/sjjjf/tournament/enter")!)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, _) = try await session.data(for: request)
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let ok = json["ok"] as? Bool { return ok }
        return false
    }

    func getRankings(belt: String = "all", weight: String = "all", season: String = "2026") async throws -> [Ranking] {
        let url = "\(baseURL)/api/v1/sjjjf/rankings?belt=\(belt)&weight=\(weight)&season=\(season)"
        let (data, _) = try await session.data(from: URL(string: url)!)
        let response = try JSONDecoder().decode(RankingsResponse.self, from: data)
        return response.rankings
    }

    func getMyEntries() async throws -> [TournamentEntry] {
        let result = try await fetch("/api/v1/sjjjf/my-entries", as: TournamentEntriesResponse.self)
        return result.entries
    }

    func getProducts(category: String? = nil) async throws -> [ShopProduct] {
        var url = "\(baseURL)/api/v1/sjjjf/products"
        if let cat = category { url += "?category=\(cat)" }
        let (data, _) = try await session.data(from: URL(string: url)!)
        let response = try JSONDecoder().decode(ProductsResponse.self, from: data)
        return response.products
    }

    func getLiveStreams() async throws -> [LiveStream] {
        let (data, _) = try await session.data(from: URL(string: "\(baseURL)/api/v1/sjjjf/live")!)
        let response = try JSONDecoder().decode(LiveStreamsResponse.self, from: data)
        return response.streams
    }

    // MARK: - Daily Drills & Streaks

    func getDailyDrill() async throws -> DailyDrill? {
        let response = try await fetch("/api/v1/daily-drill", as: DailyDrillResponse.self)
        return response.drill
    }

    func completeDrill(drillId: String) async throws -> UserStreak? {
        let body = try JSONSerialization.data(withJSONObject: ["drill_id": drillId])
        var request = URLRequest(url: URL(string: "\(baseURL)/api/v1/daily-drill/complete")!)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, _) = try await session.data(for: request)
        let response = try JSONDecoder().decode(DrillCompleteResponse.self, from: data)
        return response.streak
    }

    func getStreak() async throws -> UserStreak {
        return try await fetch("/api/v1/streak", as: StreakResponse.self).streak
    }

    // MARK: - Social Feed

    func getFeed() async throws -> [FeedEvent] {
        let response = try await fetch("/api/v1/feed", as: FeedResponse.self)
        return response.events
    }

    func toggleKudos(eventId: String) async throws -> Bool {
        let body = try JSONSerialization.data(withJSONObject: ["event_id": eventId])
        var request = URLRequest(url: URL(string: "\(baseURL)/api/v1/feed/kudos")!)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, _) = try await session.data(for: request)
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let kudoed = json["kudoed"] as? Bool { return kudoed }
        return false
    }

    // MARK: - Live Classes

    func getLiveClasses() async throws -> [LiveClass] {
        let response = try await fetch("/api/v1/live-classes", as: LiveClassesResponse.self)
        return response.classes
    }

    // MARK: - AI Analysis

    func requestAIAnalysis(videoUrl: String?) async throws -> AIAnalysis? {
        var body: [String: Any] = [:]
        if let url = videoUrl { body["video_url"] = url }
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        var request = URLRequest(url: URL(string: "\(baseURL)/api/v1/ai-analysis")!)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, _) = try await session.data(for: request)
        let response = try JSONDecoder().decode(AIAnalysisResponse.self, from: data)
        return response.analysis
    }
}
