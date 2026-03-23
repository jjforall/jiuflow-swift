import SwiftUI

// MARK: - Admin Panel View

struct AdminPanelView: View {
    @EnvironmentObject var api: APIService
    @State private var stats: AdminStats?
    @State private var users: [AdminUser] = []
    @State private var feedback: [AdminFeedback] = []
    @State private var reservations: [AdminReservation] = []
    @State private var announcements: [AdminAnnouncement] = []
    @State private var isLoading = true
    @State private var selectedTab = 0
    @State private var searchText = ""
    @State private var errorMessage: String?

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                if isLoading {
                    ProgressView("読み込み中...")
                        .foregroundStyle(Color.jfTextTertiary)
                        .padding(.top, 60)
                } else if let error = errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.red)
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(Color.jfTextSecondary)
                    }
                    .padding(.top, 60)
                } else {
                    // Stats dashboard
                    if let stats = stats {
                        statsSection(stats)
                    }

                    // Tab picker (5 tabs)
                    Picker("", selection: $selectedTab) {
                        Text("ユーザー").tag(0)
                        Text("フィードバック").tag(1)
                        Text("予約").tag(2)
                        Text("お知らせ").tag(3)
                        Text("設定").tag(4)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    switch selectedTab {
                    case 0:
                        usersSection
                    case 1:
                        feedbackSection
                    case 2:
                        reservationsSection
                    case 3:
                        announcementsSection
                    case 4:
                        settingsSection
                    default:
                        EmptyView()
                    }
                }

                Spacer(minLength: 40)
            }
            .padding(.top, 8)
        }
        .background(Color.jfDarkBg)
        .navigationTitle("管理者パネル")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadAll()
        }
    }

    // MARK: - Stats

    private func statsSection(_ stats: AdminStats) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "chart.bar.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
                Text("ダッシュボード")
                    .font(.caption.bold())
                    .foregroundStyle(Color.jfTextTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 10) {
                AdminStatCard(icon: "person.3.fill", value: "\(stats.users)", label: "ユーザー", color: .blue)
                AdminStatCard(icon: "play.rectangle.fill", value: "\(stats.videos)", label: "動画", color: .purple)
                AdminStatCard(icon: "building.2.fill", value: "\(stats.dojos)", label: "道場", color: .green)
                AdminStatCard(icon: "bubble.left.fill", value: "\(stats.feedback)", label: "FB", color: .orange)
                AdminStatCard(icon: "text.bubble.fill", value: "\(stats.threads)", label: "スレッド", color: .cyan)
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Users

    private var filteredUsers: [AdminUser] {
        if searchText.isEmpty { return users }
        let q = searchText.lowercased()
        return users.filter {
            ($0.email?.lowercased().contains(q) ?? false) ||
            ($0.display_name?.lowercased().contains(q) ?? false) ||
            $0.id.lowercased().contains(q)
        }
    }

    private var usersSection: some View {
        VStack(spacing: 12) {
            // Search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.jfTextTertiary)
                TextField("ユーザーを検索...", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .foregroundStyle(Color.jfTextPrimary)
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.jfTextTertiary)
                    }
                }
            }
            .padding(12)
            .background(Color.jfCardBg)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.jfBorder, lineWidth: 1))
            .padding(.horizontal)

            // User list
            ForEach(filteredUsers) { user in
                AdminUserRow(user: user) { newRole in
                    await changeRole(userId: user.id, newRole: newRole)
                } onDelete: {
                    await deleteUser(userId: user.id)
                }
            }
            .padding(.horizontal)

            if filteredUsers.isEmpty {
                Text("ユーザーが見つかりません")
                    .font(.subheadline)
                    .foregroundStyle(Color.jfTextTertiary)
                    .padding(.top, 20)
            }
        }
    }

    // MARK: - Feedback

    private var feedbackSection: some View {
        VStack(spacing: 10) {
            ForEach(feedback) { fb in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(fb.page)
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.blue.opacity(0.15))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())

                        Spacer()

                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= fb.rating ? "star.fill" : "star")
                                    .font(.caption2)
                                    .foregroundStyle(star <= fb.rating ? .yellow : Color.jfTextTertiary)
                            }
                        }
                    }

                    if let message = fb.message, !message.isEmpty {
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(Color.jfTextPrimary)
                    }

                    HStack {
                        if let device = fb.device_info, !device.isEmpty {
                            Text(device)
                                .font(.caption2)
                                .foregroundStyle(Color.jfTextTertiary)
                        }
                        Spacer()
                        Text(fb.created_at)
                            .font(.caption2)
                            .foregroundStyle(Color.jfTextTertiary)
                    }
                }
                .padding(14)
                .glassCard(cornerRadius: 14)
            }
            .padding(.horizontal)

            if feedback.isEmpty {
                Text("フィードバックはまだありません")
                    .font(.subheadline)
                    .foregroundStyle(Color.jfTextTertiary)
                    .padding(.top, 20)
            }
        }
    }

    // MARK: - Reservations

    private var reservationsSection: some View {
        VStack(spacing: 10) {
            ForEach(reservations) { res in
                AdminReservationRow(reservation: res) { newStatus in
                    await updateReservationStatus(id: res.id, status: newStatus)
                }
            }
            .padding(.horizontal)

            if reservations.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.title)
                        .foregroundStyle(Color.jfTextTertiary)
                    Text("予約はまだありません")
                        .font(.subheadline)
                        .foregroundStyle(Color.jfTextTertiary)
                }
                .padding(.top, 20)
            }
        }
    }

    // MARK: - Announcements

    @State private var showNewAnnouncement = false
    @State private var newAnnouncementTitle = ""
    @State private var newAnnouncementMessage = ""
    @State private var newAnnouncementTarget = "all"

    private var announcementsSection: some View {
        VStack(spacing: 12) {
            // New announcement button
            Button {
                showNewAnnouncement.toggle()
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("新しいお知らせ")
                }
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)

            // New announcement form
            if showNewAnnouncement {
                VStack(spacing: 12) {
                    TextField("タイトル", text: $newAnnouncementTitle)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color.jfCardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.jfBorder, lineWidth: 1))
                        .foregroundStyle(Color.jfTextPrimary)

                    TextField("メッセージ", text: $newAnnouncementMessage, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(3...6)
                        .padding(12)
                        .background(Color.jfCardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.jfBorder, lineWidth: 1))
                        .foregroundStyle(Color.jfTextPrimary)

                    Picker("対象", selection: $newAnnouncementTarget) {
                        Text("全員").tag("all")
                        Text("Pro").tag("pro")
                        Text("Admin").tag("admin")
                    }
                    .pickerStyle(.segmented)

                    HStack(spacing: 12) {
                        Button("キャンセル") {
                            showNewAnnouncement = false
                            newAnnouncementTitle = ""
                            newAnnouncementMessage = ""
                            newAnnouncementTarget = "all"
                        }
                        .font(.subheadline)
                        .foregroundStyle(Color.jfTextTertiary)

                        Button {
                            Task { await postAnnouncement() }
                        } label: {
                            Text("送信")
                                .font(.subheadline.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 8)
                                .background(
                                    newAnnouncementTitle.isEmpty || newAnnouncementMessage.isEmpty
                                    ? Color.gray : Color.blue
                                )
                                .clipShape(Capsule())
                        }
                        .disabled(newAnnouncementTitle.isEmpty || newAnnouncementMessage.isEmpty)
                    }
                }
                .padding(14)
                .glassCard(cornerRadius: 14)
                .padding(.horizontal)
            }

            // Existing announcements
            ForEach(announcements) { ann in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(ann.title)
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.jfTextPrimary)
                        Spacer()
                        Text(targetLabel(ann.target_role))
                            .font(.caption2.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(targetColor(ann.target_role).opacity(0.15))
                            .foregroundStyle(targetColor(ann.target_role))
                            .clipShape(Capsule())
                    }

                    Text(ann.message)
                        .font(.caption)
                        .foregroundStyle(Color.jfTextSecondary)

                    Text(ann.created_at)
                        .font(.caption2)
                        .foregroundStyle(Color.jfTextTertiary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(14)
                .glassCard(cornerRadius: 14)
            }
            .padding(.horizontal)

            if announcements.isEmpty && !showNewAnnouncement {
                VStack(spacing: 8) {
                    Image(systemName: "megaphone")
                        .font(.title)
                        .foregroundStyle(Color.jfTextTertiary)
                    Text("お知らせはまだありません")
                        .font(.subheadline)
                        .foregroundStyle(Color.jfTextTertiary)
                }
                .padding(.top, 20)
            }
        }
    }

    private func targetLabel(_ role: String) -> String {
        switch role {
        case "all": return "全員"
        case "pro": return "Pro"
        case "admin": return "Admin"
        default: return role
        }
    }

    private func targetColor(_ role: String) -> Color {
        switch role {
        case "all": return .blue
        case "pro": return .yellow
        case "admin": return .red
        default: return .gray
        }
    }

    // MARK: - Settings

    @State private var apiHealthOk: Bool?
    @State private var isCheckingHealth = false

    private var settingsSection: some View {
        VStack(spacing: 12) {
            // API status check
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "server.rack")
                        .font(.caption)
                        .foregroundStyle(.blue)
                    Text("サーバー状態")
                        .font(.caption.bold())
                        .foregroundStyle(Color.jfTextTertiary)
                }

                HStack {
                    if isCheckingHealth {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("チェック中...")
                            .font(.subheadline)
                            .foregroundStyle(Color.jfTextTertiary)
                    } else if let ok = apiHealthOk {
                        Image(systemName: ok ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(ok ? .green : .red)
                        Text(ok ? "正常" : "エラー")
                            .font(.subheadline)
                            .foregroundStyle(ok ? .green : .red)
                    } else {
                        Text("未確認")
                            .font(.subheadline)
                            .foregroundStyle(Color.jfTextTertiary)
                    }
                    Spacer()
                    Button {
                        Task { await checkHealth() }
                    } label: {
                        Text("チェック")
                            .font(.caption.bold())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.15))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(14)
            .glassCard(cornerRadius: 14)

            // App info
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.purple)
                    Text("アプリ情報")
                        .font(.caption.bold())
                        .foregroundStyle(Color.jfTextTertiary)
                }

                HStack {
                    Text("バージョン")
                        .font(.subheadline)
                        .foregroundStyle(Color.jfTextSecondary)
                    Spacer()
                    Text(appVersion)
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(Color.jfTextPrimary)
                }

                HStack {
                    Text("ビルド")
                        .font(.subheadline)
                        .foregroundStyle(Color.jfTextSecondary)
                    Spacer()
                    Text(appBuild)
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(Color.jfTextPrimary)
                }

                HStack {
                    Text("API")
                        .font(.subheadline)
                        .foregroundStyle(Color.jfTextSecondary)
                    Spacer()
                    Text(api.baseURL)
                        .font(.caption2)
                        .foregroundStyle(Color.jfTextTertiary)
                        .lineLimit(1)
                }
            }
            .padding(14)
            .glassCard(cornerRadius: 14)

            // Cache clear
            Button {
                URLCache.shared.removeAllCachedResponses()
                apiHealthOk = nil
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("キャッシュクリア")
                }
                .font(.subheadline.bold())
                .foregroundStyle(.orange)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange.opacity(0.3), lineWidth: 1))
            }
        }
        .padding(.horizontal)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    }

    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
    }

    // MARK: - Network

    private func loadAll() async {
        isLoading = true
        errorMessage = nil

        do {
            async let statsTask = fetchAdminStats()
            async let usersTask = fetchAdminUsers()
            async let feedbackTask = fetchAdminFeedback()
            async let reservationsTask = fetchAdminReservations()
            async let announcementsTask = fetchAdminAnnouncements()

            let (s, u, f, r, a) = try await (statsTask, usersTask, feedbackTask, reservationsTask, announcementsTask)
            stats = s
            users = u
            feedback = f
            reservations = r
            announcements = a
        } catch {
            errorMessage = "データの取得に失敗しました"
        }

        isLoading = false
    }

    private func adminRequest(path: String, method: String = "GET", body: [String: Any]? = nil) async throws -> (Data, HTTPURLResponse) {
        guard let url = URL(string: "\(api.baseURL)\(path)") else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = api.authToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body = body {
            req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return (data, response as! HTTPURLResponse)
    }

    private func fetchAdminStats() async throws -> AdminStats {
        let (data, _) = try await adminRequest(path: "/api/v1/admin/stats")
        return try JSONDecoder().decode(AdminStats.self, from: data)
    }

    private func fetchAdminUsers() async throws -> [AdminUser] {
        let (data, _) = try await adminRequest(path: "/api/v1/admin/users")
        let res = try JSONDecoder().decode(AdminUsersResponse.self, from: data)
        return res.users
    }

    private func fetchAdminFeedback() async throws -> [AdminFeedback] {
        let (data, _) = try await adminRequest(path: "/api/v1/admin/feedback")
        let res = try JSONDecoder().decode(AdminFeedbackResponse.self, from: data)
        return res.feedback
    }

    private func fetchAdminReservations() async throws -> [AdminReservation] {
        let (data, _) = try await adminRequest(path: "/api/v1/admin/reservations")
        let res = try JSONDecoder().decode(AdminReservationsResponse.self, from: data)
        return res.reservations
    }

    private func fetchAdminAnnouncements() async throws -> [AdminAnnouncement] {
        let (data, _) = try await adminRequest(path: "/api/v1/admin/announcements")
        let res = try JSONDecoder().decode(AdminAnnouncementsResponse.self, from: data)
        return res.announcements
    }

    private func changeRole(userId: String, newRole: String) async {
        _ = try? await adminRequest(path: "/api/v1/admin/users/\(userId)/role", method: "POST", body: ["role": newRole])
        if let updated = try? await fetchAdminUsers() {
            users = updated
        }
    }

    private func deleteUser(userId: String) async {
        _ = try? await adminRequest(path: "/api/v1/admin/users/\(userId)", method: "DELETE")
        if let updated = try? await fetchAdminUsers() {
            users = updated
        }
        if let s = try? await fetchAdminStats() {
            stats = s
        }
    }

    private func updateReservationStatus(id: String, status: String) async {
        _ = try? await adminRequest(path: "/api/v1/admin/reservations/\(id)/status", method: "POST", body: ["status": status])
        if let updated = try? await fetchAdminReservations() {
            reservations = updated
        }
    }

    private func postAnnouncement() async {
        let body: [String: Any] = [
            "title": newAnnouncementTitle,
            "message": newAnnouncementMessage,
            "target_role": newAnnouncementTarget,
        ]
        _ = try? await adminRequest(path: "/api/v1/admin/announce", method: "POST", body: body)

        newAnnouncementTitle = ""
        newAnnouncementMessage = ""
        newAnnouncementTarget = "all"
        showNewAnnouncement = false

        if let updated = try? await fetchAdminAnnouncements() {
            announcements = updated
        }
    }

    private func checkHealth() async {
        isCheckingHealth = true
        defer { isCheckingHealth = false }
        do {
            let _ = try await adminRequest(path: "/health")
            apiHealthOk = true
        } catch {
            apiHealthOk = false
        }
    }
}

// MARK: - Admin Models

struct AdminStats: Codable {
    let users: Int
    let videos: Int
    let feedback: Int
    let dojos: Int
    let threads: Int
}

struct AdminUser: Codable, Identifiable {
    let id: String
    let email: String?
    let display_name: String?
    let role: String
    let created_at: String
}

struct AdminUsersResponse: Codable {
    let users: [AdminUser]
}

struct AdminFeedback: Codable, Identifiable {
    let id: String
    let page: String
    let rating: Int
    let message: String?
    let device_info: String?
    let created_at: String
}

struct AdminFeedbackResponse: Codable {
    let feedback: [AdminFeedback]
}

struct AdminReservation: Codable, Identifiable {
    let id: String
    let user_id: String
    let class_id: String
    let reserved_date: String
    let status: String
    let amount_jpy: Int
    let notes: String
    let created_at: String
    let checked_in: Int
    let user_email: String?
    let user_name: String?
    let class_title: String?
    let dojo_id: String?
    let dojo_name: String?
}

struct AdminReservationsResponse: Codable {
    let reservations: [AdminReservation]
}

struct AdminAnnouncement: Codable, Identifiable {
    let id: String
    let title: String
    let message: String
    let target_role: String
    let created_at: String
}

struct AdminAnnouncementsResponse: Codable {
    let announcements: [AdminAnnouncement]
}

// MARK: - Stat Card

private struct AdminStatCard: View {
    let icon: String
    let value: String
    let label: String
    var color: Color = .blue

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold().monospacedDigit())
                .foregroundStyle(Color.jfTextPrimary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.jfTextTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .glassCard()
    }
}

// MARK: - User Row

private struct AdminUserRow: View {
    let user: AdminUser
    let onRoleChange: (String) async -> Void
    let onDelete: () async -> Void
    @State private var showRolePicker = false
    @State private var showDeleteConfirm = false
    @State private var selectedRole: String = ""

    private let roles = ["user", "pro", "instructor", "admin"]
    private let roleLabels: [String: String] = [
        "user": "User",
        "pro": "Pro",
        "instructor": "Instructor",
        "admin": "Admin"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(user.display_name ?? "名前なし")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.jfTextPrimary)
                    Text(user.email ?? "")
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                }

                Spacer()

                Button {
                    selectedRole = user.role
                    showRolePicker = true
                } label: {
                    Text(roleLabels[user.role] ?? user.role)
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(roleColor(user.role).opacity(0.15))
                        .foregroundStyle(roleColor(user.role))
                        .clipShape(Capsule())
                }
            }

            HStack {
                Text("ID: \(user.id)")
                    .font(.caption2)
                    .foregroundStyle(Color.jfTextTertiary)
                Spacer()

                if user.role != "admin" {
                    Button {
                        showDeleteConfirm = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption2)
                            .foregroundStyle(.red.opacity(0.6))
                    }
                }

                Text(String(user.created_at.prefix(10)))
                    .font(.caption2)
                    .foregroundStyle(Color.jfTextTertiary)
            }
        }
        .padding(14)
        .glassCard(cornerRadius: 14)
        .confirmationDialog("ロールを変更", isPresented: $showRolePicker, titleVisibility: .visible) {
            ForEach(roles, id: \.self) { role in
                Button(roleLabels[role] ?? role) {
                    Task { await onRoleChange(role) }
                }
            }
            Button("キャンセル", role: .cancel) {}
        }
        .confirmationDialog("このユーザーを削除しますか？", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("削除", role: .destructive) {
                Task { await onDelete() }
            }
            Button("キャンセル", role: .cancel) {}
        }
    }

    private func roleColor(_ role: String) -> Color {
        switch role {
        case "admin": return .red
        case "instructor": return .purple
        case "pro": return .yellow
        default: return .gray
        }
    }
}

// MARK: - Reservation Row

private struct AdminReservationRow: View {
    let reservation: AdminReservation
    let onStatusChange: (String) async -> Void
    @State private var showStatusPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(reservation.class_title ?? "クラス不明")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.jfTextPrimary)
                    Text(reservation.dojo_name ?? "道場不明")
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                }

                Spacer()

                Button {
                    showStatusPicker = true
                } label: {
                    Text(statusLabel(reservation.status))
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(statusColor(reservation.status).opacity(0.15))
                        .foregroundStyle(statusColor(reservation.status))
                        .clipShape(Capsule())
                }
            }

            HStack {
                Image(systemName: "person.fill")
                    .font(.caption2)
                    .foregroundStyle(Color.jfTextTertiary)
                Text(reservation.user_name ?? reservation.user_email ?? "不明")
                    .font(.caption)
                    .foregroundStyle(Color.jfTextSecondary)

                Spacer()

                Image(systemName: "calendar")
                    .font(.caption2)
                    .foregroundStyle(Color.jfTextTertiary)
                Text(reservation.reserved_date)
                    .font(.caption)
                    .foregroundStyle(Color.jfTextSecondary)
            }

            if reservation.amount_jpy > 0 {
                HStack {
                    Text("¥\(reservation.amount_jpy)")
                        .font(.caption.bold())
                        .foregroundStyle(Color.jfTextPrimary)
                    Spacer()
                    if reservation.checked_in == 1 {
                        HStack(spacing: 3) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                            Text("チェックイン済")
                                .font(.caption2)
                        }
                        .foregroundStyle(.green)
                    }
                    Text(String(reservation.created_at.prefix(10)))
                        .font(.caption2)
                        .foregroundStyle(Color.jfTextTertiary)
                }
            }
        }
        .padding(14)
        .glassCard(cornerRadius: 14)
        .confirmationDialog("ステータスを変更", isPresented: $showStatusPicker, titleVisibility: .visible) {
            Button("確定") { Task { await onStatusChange("confirmed") } }
            Button("キャンセル扱い", role: .destructive) { Task { await onStatusChange("cancelled") } }
            Button("保留に戻す") { Task { await onStatusChange("pending") } }
            Button("閉じる", role: .cancel) {}
        }
    }

    private func statusLabel(_ status: String) -> String {
        switch status {
        case "pending": return "確認待ち"
        case "confirmed": return "確定"
        case "cancelled": return "キャンセル"
        default: return status
        }
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "pending": return .yellow
        case "confirmed": return .green
        case "cancelled": return .red
        default: return .gray
        }
    }
}
