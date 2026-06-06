import Foundation
import SwiftUI
import SwiftData

@MainActor
class APIService: ObservableObject {
    /// App-wide instance (one APIService is created in JiuFlowApp). Lets non-View
    /// stores (e.g. JournalStore) reach the authed session without DI plumbing.
    static weak var shared: APIService?

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
        config.timeoutIntervalForRequest = 8   // 15→8秒
        config.timeoutIntervalForResource = 20  // 30→20秒
        config.waitsForConnectivity = true      // オフライン時にキャッシュ返す
        config.allowsConstrainedNetworkAccess = true
        // Large URL cache for thumbnails (50MB memory, 200MB disk)
        config.urlCache = URLCache(memoryCapacity: 50_000_000, diskCapacity: 200_000_000)
        config.requestCachePolicy = .returnCacheDataElseLoad
        self.session = URLSession(configuration: config)

        APIService.shared = self

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

    /// Server-side video search via `/api/v1/videos/search`. Returns an empty
    /// array on failure so callers can show "no results" without an error UI.
    func searchVideos(query: String, limit: Int = 50) async -> [Video] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        guard let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return []
        }
        do {
            let result = try await fetch("/api/v1/videos/search?q=\(encoded)&limit=\(limit)", as: VideosResponse.self)
            return result.videos
        } catch {
            print("Video search error: \(error)")
            return []
        }
    }

    func loadVideos() async {
        // SWR: キャッシュがあれば即座に表示
        if let cached = UserDefaults.standard.data(forKey: "cache_videos"),
           let decoded = try? JSONDecoder().decode(VideosResponse.self, from: cached),
           !decoded.videos.isEmpty, videos.isEmpty {
            videos = decoded.videos
        }
        isLoading = videos.isEmpty
        error = nil
        do {
            let result = try await fetch("/api/v1/videos", as: VideosResponse.self)
            videos = result.videos
            if let encoded = try? JSONEncoder().encode(result) {
                UserDefaults.standard.set(encoded, forKey: "cache_videos")
            }
        } catch {
            if videos.isEmpty { self.error = "動画の読み込みに失敗しました" }
            print("Videos error: \(error)")
        }
        isLoading = false
    }

    func loadAthletes() async {
        // SWR: SwiftDataキャッシュがあれば即座に表示
        if athletes.isEmpty, let cached = loadCachedAthletes(), !cached.isEmpty {
            athletes = cached
            print("Athletes pre-loaded from SwiftData cache (\(cached.count) items)")
        }
        isLoading = athletes.isEmpty
        error = nil
        do {
            let result = try await fetch("/api/v1/athletes", as: AthletesResponse.self)
            athletes = result.athletes
            // Cache to SwiftData
            cacheAthletes(result.athletes)
        } catch {
            // Offline fallback: load from SwiftData cache
            if athletes.isEmpty {
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
        // SWR: キャッシュがあれば即座に表示
        if let cached = UserDefaults.standard.data(forKey: "cache_news"),
           let decoded = try? JSONDecoder().decode(NewsResponse.self, from: cached),
           !decoded.news.isEmpty, news.isEmpty {
            news = decoded.news
        }
        isLoading = news.isEmpty
        error = nil
        do {
            let result = try await fetch("/api/v1/news", as: NewsResponse.self)
            news = result.news
            if let encoded = try? JSONEncoder().encode(result) {
                UserDefaults.standard.set(encoded, forKey: "cache_news")
            }
        } catch {
            if news.isEmpty { self.error = "ニュースの読み込みに失敗しました" }
            print("News error: \(error)")
        }
        isLoading = false
    }

    func loadDojos() async {
        // SWR: キャッシュがあれば即座に表示
        if let cached = UserDefaults.standard.data(forKey: "cache_dojos"),
           let decoded = try? JSONDecoder().decode(DojosResponse.self, from: cached),
           !decoded.dojos.isEmpty, dojos.isEmpty {
            dojos = decoded.dojos
        }
        isLoading = dojos.isEmpty
        error = nil
        do {
            let result = try await fetch("/api/v1/dojos", as: DojosResponse.self)
            dojos = result.dojos
            if let encoded = try? JSONEncoder().encode(result) {
                UserDefaults.standard.set(encoded, forKey: "cache_dojos")
            }
        } catch {
            if dojos.isEmpty { self.error = "道場情報の読み込みに失敗しました" }
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
        // SWR: SwiftDataキャッシュがあれば即座に表示
        if tournaments.isEmpty, let cached = loadCachedTournaments(), !cached.isEmpty {
            tournaments = cached
            print("Tournaments pre-loaded from SwiftData cache (\(cached.count) items)")
        }
        do {
            let result = try await fetch("/api/v1/tournaments", as: TournamentsResponse.self)
            tournaments = result.tournaments
            // Cache to SwiftData
            cacheTournaments(result.tournaments)
        } catch {
            if tournaments.isEmpty {
                print("Tournaments error (no cache available): \(error)")
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
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        // Bypass cache for auth requests (POST, but ensure fresh response)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        // Use longer timeout for App Review (reviewers connect from overseas)
        request.timeoutInterval = 30
        let encodedEmail = email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? email
        request.httpBody = "email=\(encodedEmail)&platform=ios".data(using: .utf8)

        do {
            let (data, response) = try await session.data(for: request)
            if let http = response as? HTTPURLResponse, 200..<400 ~= http.statusCode {
                // App Review reviewer bypass: server may return JSON with immediate session token
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   json["reviewer_bypass"] as? Bool == true,
                   let result = try? JSONDecoder().decode(MagicLinkVerifyResponse.self, from: data) {
                    // Already on @MainActor — set state directly without unnecessary await
                    self.authToken = result.token
                    self.currentUser = result.user
                    self.isLoggedIn = true
                    KeychainHelper.save("auth_token", string: result.token)
                    if let userData = try? JSONEncoder().encode(result.user) {
                        KeychainHelper.save("auth_user", data: userData)
                    }
                    return (true, "reviewer_bypass")
                }
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
                    // Sync tier to PremiumManager via UserDefaults (@AppStorage bridge)
                    if let t = tier, !t.isEmpty {
                        UserDefaults.standard.set(t, forKey: "user_tier")
                        UserDefaults.standard.set(t != "free", forKey: "is_premium_user")
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

    func registerSjjjfMember(belt: String, weightClass: String?, dojoName: String?, fullName: String? = nil, birthDate: String? = nil) async throws -> SjjjfMember? {
        var body: [String: Any] = ["belt": belt]
        if let wc = weightClass { body["weight_class"] = wc }
        if let dn = dojoName { body["dojo_name"] = dn }
        if let fn = fullName, !fn.isEmpty { body["full_name"] = fn }
        if let bd = birthDate { body["birth_date"] = bd }
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

    // MARK: - Practice journal sync
    //
    // Mirror the on-device practice journal to the server so activation, streaks,
    // and win-back are measurable server-side (previously the journal never left the
    // device). Fire-and-forget: never blocks the UI, no-op without a token. The full
    // set is sent each time; the server upserts by entry id, so any previously
    // unsynced entries self-heal on the next save.
    func syncJournal(_ entries: [JournalEntry]) {
        guard let token = authToken, !entries.isEmpty,
              let url = URL(string: "\(baseURL)/api/v1/practice/sync") else { return }

        struct SyncEntry: Encodable {
            let id: String
            let date: String
            let duration_minutes: Int
            let type: String
            let notes: String
            let techniques: [String]
        }
        struct SyncBody: Encodable { let entries: [SyncEntry] }

        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "yyyy-MM-dd"
        let dtos = entries.map {
            SyncEntry(id: $0.id, date: fmt.string(from: $0.date),
                      duration_minutes: $0.duration, type: $0.type,
                      notes: $0.notes, techniques: $0.techniques)
        }
        guard let body = try? JSONEncoder().encode(SyncBody(entries: dtos)) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = body
        Task { _ = try? await session.data(for: request) }
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

    // MARK: - Bracket

    func fetchBracket(tournamentId: String) async throws -> BracketResponse {
        return try await fetch("/api/v1/sjjjf/bracket/\(tournamentId)", as: BracketResponse.self)
    }

    // MARK: - Organizer

    func fetchOrganizerTournaments() async throws -> [OrganizerTournament] {
        let response = try await fetch("/api/v1/sjjjf/organizer/tournaments", as: OrganizerTournamentsResponse.self)
        return response.tournaments
    }

    func fetchOrganizerEntries(tournamentId: String) async throws -> [TournamentEntry] {
        let response = try await fetch("/api/v1/sjjjf/organizer/\(tournamentId)/entries", as: TournamentEntriesResponse.self)
        return response.entries
    }

    func updateCheckin(tournamentId: String, entryId: String, checkedIn: Bool) async throws {
        guard let url = URL(string: "\(baseURL)/api/v1/sjjjf/organizer/\(tournamentId)/checkin") else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        request.httpBody = try JSONSerialization.data(withJSONObject: ["entry_id": entryId, "checked_in": checkedIn])
        let (_, resp) = try await session.data(for: request)
        guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else { throw URLError(.badServerResponse) }
    }

    func recordResults(tournamentId: String, entries: [(entryId: String, place: Int)]) async throws {
        guard let url = URL(string: "\(baseURL)/api/v1/sjjjf/results") else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        let entriesJSON = entries.map { ["entry_id": $0.entryId, "place": $0.place] }
        request.httpBody = try JSONSerialization.data(withJSONObject: ["tournament_id": tournamentId, "entries": entriesJSON])
        let (_, resp) = try await session.data(for: request)
        guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else { throw URLError(.badServerResponse) }
    }

    // MARK: - Push Notifications

    func registerPushToken(_ token: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/v1/push-token") else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let t = authToken { request.setValue("Bearer \(t)", forHTTPHeaderField: "Authorization") }
        request.httpBody = try JSONEncoder().encode(["token": token])
        try await session.data(for: request)
    }

    func sendNotification(tournamentId: String, title: String, body: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/v1/sjjjf/organizer/\(tournamentId)/notify") else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let t = authToken { request.setValue("Bearer \(t)", forHTTPHeaderField: "Authorization") }
        let payload = ["title": title, "body": body]
        request.httpBody = try JSONEncoder().encode(payload)
        let (_, resp) = try await session.data(for: request)
        guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else { throw URLError(.badServerResponse) }
    }

    // MARK: - QR Check-in

    func checkinByQR(tournamentId: String, memberNumber: String) async throws -> QRCheckinResult {
        guard let url = URL(string: "\(baseURL)/api/v1/sjjjf/organizer/\(tournamentId)/checkin-qr") else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let t = authToken { request.setValue("Bearer \(t)", forHTTPHeaderField: "Authorization") }
        request.httpBody = try JSONEncoder().encode(["member_number": memberNumber])
        let (data, resp) = try await session.data(for: request)
        let httpResp = resp as? HTTPURLResponse
        guard let httpResp, 200..<300 ~= httpResp.statusCode else {
            let msg = (try? JSONDecoder().decode([String: String].self, from: data))?["error"] ?? "Check-in failed"
            throw NSError(domain: "QRCheckin", code: httpResp?.statusCode ?? 0, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        return try JSONDecoder().decode(QRCheckinResult.self, from: data)
    }

    // MARK: - Bracket with matches

    func fetchBracketV2(tournamentId: String) async throws -> BracketV2Response {
        guard let url = URL(string: "\(baseURL)/api/v1/sjjjf/bracketv2/\(tournamentId)") else { throw URLError(.badURL) }
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode(BracketV2Response.self, from: data)
    }

    func setMatchWinner(tournamentId: String, matchId: String, winnerId: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/v1/sjjjf/organizer/\(tournamentId)/matches/\(matchId)/winner") else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let t = authToken { request.setValue("Bearer \(t)", forHTTPHeaderField: "Authorization") }
        request.httpBody = try JSONEncoder().encode(["winner_id": winnerId])
        let (_, resp) = try await session.data(for: request)
        guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else { throw URLError(.badServerResponse) }
    }

    // MARK: - Parallel Startup Load

    /// 起動時に全データを並列フェッチ（async let で同時スタート）
    func loadAllInParallel() async {
        async let _v: () = loadVideos()
        async let _a: () = loadAthletes()
        async let _n: () = loadNews()
        async let _d: () = loadDojos()
        async let _t: () = loadTournaments()
        // 全部同時スタート、完了まで待つ
        _ = await (_v, _a, _n, _d, _t)
    }

    // MARK: - Image Prefetch

    /// サムネイルURLをバックグラウンドでプリフェッチ（URLCacheに積極的先読み）
    func prefetchImages(_ urls: [URL]) {
        for url in urls.prefix(10) {
            Task.detached(priority: .background) { [weak self] in
                guard let self else { return }
                _ = try? await self.session.data(from: url)
            }
        }
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
