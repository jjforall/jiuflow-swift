import SwiftUI

// MARK: - Admin Panel View

struct AdminPanelView: View {
    @EnvironmentObject var api: APIService
    @State private var stats: AdminStats?
    @State private var users: [AdminUser] = []
    @State private var feedback: [AdminFeedback] = []
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

                    // Tab picker
                    Picker("", selection: $selectedTab) {
                        Text("ユーザー").tag(0)
                        Text("フィードバック").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    if selectedTab == 0 {
                        usersSection
                    } else {
                        feedbackSection
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

    // MARK: - Network

    private func loadAll() async {
        isLoading = true
        errorMessage = nil

        do {
            async let statsTask = fetchAdminStats()
            async let usersTask = fetchAdminUsers()
            async let feedbackTask = fetchAdminFeedback()

            let (s, u, f) = try await (statsTask, usersTask, feedbackTask)
            stats = s
            users = u
            feedback = f
        } catch {
            errorMessage = "データの取得に失敗しました"
        }

        isLoading = false
    }

    private func fetchAdminStats() async throws -> AdminStats {
        guard let url = URL(string: "\(api.baseURL)/api/v1/admin/stats") else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = api.authToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(AdminStats.self, from: data)
    }

    private func fetchAdminUsers() async throws -> [AdminUser] {
        guard let url = URL(string: "\(api.baseURL)/api/v1/admin/users") else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = api.authToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let res = try JSONDecoder().decode(AdminUsersResponse.self, from: data)
        return res.users
    }

    private func fetchAdminFeedback() async throws -> [AdminFeedback] {
        guard let url = URL(string: "\(api.baseURL)/api/v1/admin/feedback") else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = api.authToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let res = try JSONDecoder().decode(AdminFeedbackResponse.self, from: data)
        return res.feedback
    }

    private func changeRole(userId: String, newRole: String) async {
        guard let url = URL(string: "\(api.baseURL)/api/v1/admin/users/\(userId)/role") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = api.authToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["role": newRole])
        _ = try? await URLSession.shared.data(for: req)
        // Refresh user list
        if let updated = try? await fetchAdminUsers() {
            users = updated
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
    @State private var showRolePicker = false
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
