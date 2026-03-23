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
    @State private var lastRefresh = Date()
    @State private var refreshTimer: Timer?

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
                        Button("再試行") {
                            Task { await loadAll() }
                        }
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(LinearGradient.jfRedGradient)
                        .clipShape(Capsule())
                    }
                    .padding(.top, 60)
                } else {
                    // Stats dashboard (always visible)
                    if let stats = stats {
                        statsSection(stats)
                    }

                    // Last refresh timestamp
                    lastRefreshLabel
                        .padding(.horizontal)

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
        .refreshable {
            await loadAll()
        }
        .navigationTitle("管理者パネル")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadAll()
        }
        .onAppear { startAutoRefresh() }
        .onDisappear { stopAutoRefresh() }
    }

    // MARK: - Last Refresh

    private var lastRefreshLabel: some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.clockwise")
                .font(.caption2)
            Text("最終更新: \(relativeTime(lastRefresh))")
                .font(.caption2)
            Spacer()
            Button {
                Task { await loadAll() }
            } label: {
                Text("更新")
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.jfRed.opacity(0.15))
                    .foregroundStyle(Color.jfRed)
                    .clipShape(Capsule())
            }
        }
        .foregroundStyle(Color.jfTextTertiary)
    }

    private func relativeTime(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 5 { return "たった今" }
        if seconds < 60 { return "\(seconds)秒前" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)分前" }
        return "\(minutes / 60)時間前"
    }

    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            Task { @MainActor in
                if let newStats = try? await fetchAdminStats() {
                    stats = newStats
                    lastRefresh = Date()
                }
            }
        }
    }

    private func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    // MARK: - Stats Dashboard

    private func statsSection(_ stats: AdminStats) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "chart.bar.fill")
                    .font(.caption)
                    .foregroundStyle(Color.jfRed)
                Text("ダッシュボード")
                    .font(.caption.bold())
                    .foregroundStyle(Color.jfTextTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 10) {
                AdminStatCardEnhanced(
                    icon: "person.3.fill",
                    value: stats.users,
                    label: "ユーザー数",
                    color: .blue,
                    trend: .up(12)
                ) { selectedTab = 0 }

                AdminStatCardEnhanced(
                    icon: "play.rectangle.fill",
                    value: stats.videos,
                    label: "動画数",
                    color: .purple,
                    trend: .up(3)
                ) { }

                AdminStatCardEnhanced(
                    icon: "building.2.fill",
                    value: stats.dojos,
                    label: "道場数",
                    color: .green,
                    trend: .neutral
                ) { }

                AdminStatCardEnhanced(
                    icon: "bubble.left.fill",
                    value: stats.feedback,
                    label: "フィードバック数",
                    color: .orange,
                    trend: .up(5)
                ) { selectedTab = 1 }

                AdminStatCardEnhanced(
                    icon: "calendar.badge.clock",
                    value: reservations.count,
                    label: "予約数",
                    color: .cyan,
                    trend: .down(2)
                ) { selectedTab = 2 }

                AdminStatCardEnhanced(
                    icon: "yensign.circle.fill",
                    value: reservations.reduce(0) { $0 + $1.amount_jpy },
                    label: "売上(仮)",
                    color: Color.jfGold,
                    trend: .up(8),
                    isYen: true
                ) { selectedTab = 2 }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Users Tab

    @State private var userSortMode: UserSortMode = .createdAt

    private enum UserSortMode: String, CaseIterable {
        case createdAt = "登録日"
        case role = "ロール"
        case email = "メール"
    }

    private var filteredUsers: [AdminUser] {
        var result: [AdminUser]
        if searchText.isEmpty {
            result = users
        } else {
            let q = searchText.lowercased()
            result = users.filter {
                ($0.email?.lowercased().contains(q) ?? false) ||
                ($0.display_name?.lowercased().contains(q) ?? false) ||
                $0.id.lowercased().contains(q)
            }
        }
        switch userSortMode {
        case .createdAt:
            return result.sorted { $0.created_at > $1.created_at }
        case .role:
            let order = ["admin": 0, "instructor": 1, "pro": 2, "user": 3]
            return result.sorted { (order[$0.role] ?? 4) < (order[$1.role] ?? 4) }
        case .email:
            return result.sorted { ($0.email ?? "") < ($1.email ?? "") }
        }
    }

    private var usersSection: some View {
        VStack(spacing: 12) {
            // Header with count
            HStack {
                Text("全\(users.count)件")
                    .font(.caption.bold())
                    .foregroundStyle(Color.jfTextTertiary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.jfCardBg)
                    .clipShape(Capsule())

                Spacer()

                // Sort picker
                Menu {
                    ForEach(UserSortMode.allCases, id: \.self) { mode in
                        Button {
                            userSortMode = mode
                        } label: {
                            HStack {
                                Text(mode.rawValue)
                                if userSortMode == mode {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.caption2)
                        Text(userSortMode.rawValue)
                            .font(.caption.bold())
                    }
                    .foregroundStyle(Color.jfTextTertiary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.jfCardBg)
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal)

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
                AdminUserRowEnhanced(user: user) { newRole in
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

    // MARK: - Feedback Tab

    @State private var feedbackHandled: Set<String> = []
    @State private var feedbackPageFilter: String? = nil

    private var averageRating: Double {
        guard !feedback.isEmpty else { return 0 }
        return Double(feedback.reduce(0) { $0 + $1.rating }) / Double(feedback.count)
    }

    private var ratingDistribution: [Int: Int] {
        var dist: [Int: Int] = [1: 0, 2: 0, 3: 0, 4: 0, 5: 0]
        for fb in feedback {
            dist[fb.rating, default: 0] += 1
        }
        return dist
    }

    private var feedbackPages: [String] {
        Array(Set(feedback.map { $0.page })).sorted()
    }

    private var filteredFeedback: [AdminFeedback] {
        guard let filter = feedbackPageFilter else { return feedback }
        return feedback.filter { $0.page == filter }
    }

    private var feedbackSection: some View {
        VStack(spacing: 14) {
            // Average rating card
            if !feedback.isEmpty {
                VStack(spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                        Text("平均評価")
                            .font(.caption.bold())
                            .foregroundStyle(Color.jfTextTertiary)
                        Spacer()
                        Text("全\(feedback.count)件")
                            .font(.caption)
                            .foregroundStyle(Color.jfTextTertiary)
                    }

                    HStack(spacing: 12) {
                        Text(String(format: "%.1f", averageRating))
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.jfTextPrimary)

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 2) {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: Double(star) <= averageRating + 0.25
                                          ? "star.fill"
                                          : (Double(star) <= averageRating + 0.75 ? "star.leadinghalf.filled" : "star"))
                                        .font(.title3)
                                        .foregroundStyle(.yellow)
                                }
                            }
                        }
                        Spacer()
                    }

                    // Rating distribution bars
                    VStack(spacing: 4) {
                        ForEach((1...5).reversed(), id: \.self) { star in
                            let count = ratingDistribution[star] ?? 0
                            let maxCount = ratingDistribution.values.max() ?? 1
                            HStack(spacing: 6) {
                                Text("\(star)")
                                    .font(.caption2.bold().monospacedDigit())
                                    .foregroundStyle(Color.jfTextTertiary)
                                    .frame(width: 12)
                                Image(systemName: "star.fill")
                                    .font(.system(size: 8))
                                    .foregroundStyle(ratingBarColor(star))
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(Color.jfBorder)
                                            .frame(height: 6)
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(ratingBarColor(star))
                                            .frame(width: maxCount > 0 ? geo.size.width * CGFloat(count) / CGFloat(maxCount) : 0, height: 6)
                                    }
                                }
                                .frame(height: 6)
                                Text("\(count)")
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(Color.jfTextTertiary)
                                    .frame(width: 24, alignment: .trailing)
                            }
                        }
                    }
                }
                .padding(14)
                .glassCard(cornerRadius: 14)
                .padding(.horizontal)
            }

            // Page filter pills
            if !feedbackPages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        AdminFilterPill(label: "全て", isSelected: feedbackPageFilter == nil) {
                            feedbackPageFilter = nil
                        }
                        ForEach(feedbackPages, id: \.self) { page in
                            AdminFilterPill(label: page, isSelected: feedbackPageFilter == page) {
                                feedbackPageFilter = page
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }

            // Feedback list
            ForEach(filteredFeedback) { fb in
                let isHandled = feedbackHandled.contains(fb.id)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(fb.page)
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.blue.opacity(0.15))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())

                        if isHandled {
                            Text("対応済み")
                                .font(.caption2.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.green.opacity(0.15))
                                .foregroundStyle(.green)
                                .clipShape(Capsule())
                        }

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
                            HStack(spacing: 3) {
                                Image(systemName: "iphone")
                                    .font(.caption2)
                                Text(device)
                                    .font(.caption2)
                            }
                            .foregroundStyle(Color.jfTextTertiary)
                        }
                        Spacer()

                        Button {
                            if isHandled {
                                feedbackHandled.remove(fb.id)
                            } else {
                                feedbackHandled.insert(fb.id)
                            }
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: isHandled ? "checkmark.circle.fill" : "circle")
                                    .font(.caption2)
                                Text(isHandled ? "対応済み" : "対応する")
                                    .font(.caption2.bold())
                            }
                            .foregroundStyle(isHandled ? .green : Color.jfTextTertiary)
                        }

                        Text(fb.created_at)
                            .font(.caption2)
                            .foregroundStyle(Color.jfTextTertiary)
                    }
                }
                .padding(14)
                .glassCard(cornerRadius: 14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isHandled ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1)
                )
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

    private func ratingBarColor(_ star: Int) -> Color {
        switch star {
        case 5: return .green
        case 4: return Color(red: 0.6, green: 0.8, blue: 0.2)
        case 3: return .yellow
        case 2: return .orange
        case 1: return .red
        default: return .gray
        }
    }

    // MARK: - Reservations Tab

    @State private var reservationStatusFilter: String? = nil

    private var reservationStatusCounts: [String: Int] {
        var counts: [String: Int] = ["pending": 0, "confirmed": 0, "cancelled": 0]
        for res in reservations {
            counts[res.status, default: 0] += 1
        }
        return counts
    }

    private var filteredReservations: [AdminReservation] {
        guard let filter = reservationStatusFilter else { return reservations }
        return reservations.filter { $0.status == filter }
    }

    private var reservationsSection: some View {
        VStack(spacing: 12) {
            // Status counts header
            HStack(spacing: 8) {
                let pending = reservationStatusCounts["pending"] ?? 0
                let confirmed = reservationStatusCounts["confirmed"] ?? 0
                let cancelled = reservationStatusCounts["cancelled"] ?? 0

                AdminStatusCount(label: "確認待ち", count: pending, color: .yellow)
                AdminStatusCount(label: "確定", count: confirmed, color: .green)
                AdminStatusCount(label: "キャンセル", count: cancelled, color: .red)
            }
            .padding(.horizontal)

            // Filter pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    AdminFilterPill(label: "全て (\(reservations.count))", isSelected: reservationStatusFilter == nil) {
                        reservationStatusFilter = nil
                    }
                    AdminFilterPill(label: "確認待ち", isSelected: reservationStatusFilter == "pending", color: .yellow) {
                        reservationStatusFilter = "pending"
                    }
                    AdminFilterPill(label: "確定", isSelected: reservationStatusFilter == "confirmed", color: .green) {
                        reservationStatusFilter = "confirmed"
                    }
                    AdminFilterPill(label: "キャンセル", isSelected: reservationStatusFilter == "cancelled", color: .red) {
                        reservationStatusFilter = "cancelled"
                    }
                }
                .padding(.horizontal)
            }

            // Reservation list
            ForEach(filteredReservations) { res in
                AdminReservationRowEnhanced(reservation: res) { newStatus in
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

    // MARK: - Announcements Tab

    @State private var showNewAnnouncement = false
    @State private var newAnnouncementTitle = ""
    @State private var newAnnouncementMessage = ""
    @State private var newAnnouncementTarget = "all"
    @State private var isSendingAnnouncement = false
    @State private var announcementToDelete: AdminAnnouncement?

    private var announcementsSection: some View {
        VStack(spacing: 12) {
            // New announcement button
            Button {
                withAnimation(.spring(response: 0.3)) {
                    showNewAnnouncement.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: showNewAnnouncement ? "xmark.circle.fill" : "plus.circle.fill")
                    Text(showNewAnnouncement ? "閉じる" : "新しいお知らせ")
                }
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(showNewAnnouncement ? Color.gray : Color.jfRed)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)

            // New announcement form
            if showNewAnnouncement {
                VStack(spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "megaphone.fill")
                            .font(.caption)
                            .foregroundStyle(Color.jfRed)
                        Text("お知らせを作成")
                            .font(.caption.bold())
                            .foregroundStyle(Color.jfTextTertiary)
                        Spacer()
                    }

                    TextField("タイトル", text: $newAnnouncementTitle)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color.jfCardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.jfBorder, lineWidth: 1))
                        .foregroundStyle(Color.jfTextPrimary)

                    ZStack(alignment: .topLeading) {
                        if newAnnouncementMessage.isEmpty {
                            Text("メッセージを入力...")
                                .font(.body)
                                .foregroundStyle(Color.jfTextTertiary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                        }
                        TextEditor(text: $newAnnouncementMessage)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 80, maxHeight: 160)
                            .padding(8)
                            .foregroundStyle(Color.jfTextPrimary)
                    }
                    .background(Color.jfCardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.jfBorder, lineWidth: 1))

                    VStack(alignment: .leading, spacing: 6) {
                        Text("対象")
                            .font(.caption.bold())
                            .foregroundStyle(Color.jfTextTertiary)
                        Picker("対象", selection: $newAnnouncementTarget) {
                            Text("全員").tag("all")
                            Text("Pro").tag("pro")
                            Text("Admin").tag("admin")
                        }
                        .pickerStyle(.segmented)
                    }

                    HStack(spacing: 12) {
                        Button("キャンセル") {
                            withAnimation {
                                showNewAnnouncement = false
                                newAnnouncementTitle = ""
                                newAnnouncementMessage = ""
                                newAnnouncementTarget = "all"
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(Color.jfTextTertiary)

                        Spacer()

                        Button {
                            Task { await postAnnouncement() }
                        } label: {
                            HStack(spacing: 6) {
                                if isSendingAnnouncement {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                        .tint(.white)
                                }
                                Text("送信")
                                    .font(.subheadline.bold())
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(
                                newAnnouncementTitle.isEmpty || newAnnouncementMessage.isEmpty
                                ? AnyShapeStyle(Color.gray) : AnyShapeStyle(LinearGradient.jfRedGradient)
                            )
                            .clipShape(Capsule())
                        }
                        .disabled(newAnnouncementTitle.isEmpty || newAnnouncementMessage.isEmpty || isSendingAnnouncement)
                    }
                }
                .padding(14)
                .glassCard(cornerRadius: 14)
                .padding(.horizontal)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Section header
            if !announcements.isEmpty {
                HStack {
                    Text("最近のお知らせ")
                        .font(.caption.bold())
                        .foregroundStyle(Color.jfTextTertiary)
                    Spacer()
                    Text("\(announcements.count)件")
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                }
                .padding(.horizontal)
            }

            // Existing announcements
            ForEach(announcements) { ann in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "megaphone.fill")
                            .font(.caption)
                            .foregroundStyle(targetColor(ann.target_role))
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
                        .lineLimit(3)

                    HStack {
                        Text(ann.created_at)
                            .font(.caption2)
                            .foregroundStyle(Color.jfTextTertiary)
                        Spacer()
                        Button {
                            announcementToDelete = ann
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption2)
                                .foregroundStyle(.red.opacity(0.6))
                        }
                    }
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
        .confirmationDialog("このお知らせを削除しますか？", isPresented: Binding(
            get: { announcementToDelete != nil },
            set: { if !$0 { announcementToDelete = nil } }
        ), titleVisibility: .visible) {
            Button("削除", role: .destructive) {
                if let ann = announcementToDelete {
                    Task { await deleteAnnouncement(id: ann.id) }
                }
            }
            Button("キャンセル", role: .cancel) {
                announcementToDelete = nil
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
        case "pro": return Color.jfGold
        case "admin": return .red
        default: return .gray
        }
    }

    // MARK: - Settings Tab

    @State private var apiHealthOk: Bool?
    @State private var isCheckingHealth = false
    @State private var showCacheCleared = false
    @State private var showExportPlaceholder = false
    @State private var showPushPlaceholder = false

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
                    // Animated health indicator
                    ZStack {
                        Circle()
                            .fill(healthIndicatorColor.opacity(0.2))
                            .frame(width: 32, height: 32)
                        if isCheckingHealth {
                            ProgressView()
                                .scaleEffect(0.6)
                        } else {
                            Circle()
                                .fill(healthIndicatorColor)
                                .frame(width: 10, height: 10)
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        if isCheckingHealth {
                            Text("チェック中...")
                                .font(.subheadline)
                                .foregroundStyle(Color.jfTextTertiary)
                        } else if let ok = apiHealthOk {
                            Text(ok ? "正常稼働中" : "エラー検出")
                                .font(.subheadline.bold())
                                .foregroundStyle(ok ? .green : .red)
                            Text(api.baseURL)
                                .font(.caption2)
                                .foregroundStyle(Color.jfTextTertiary)
                                .lineLimit(1)
                        } else {
                            Text("未確認")
                                .font(.subheadline)
                                .foregroundStyle(Color.jfTextTertiary)
                        }
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

                AdminSettingsRow(label: "バージョン", value: appVersion)
                AdminSettingsRow(label: "ビルド", value: appBuild)
                AdminSettingsRow(label: "プラットフォーム", value: deviceInfo)
            }
            .padding(14)
            .glassCard(cornerRadius: 14)

            // Actions section
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                    Text("アクション")
                        .font(.caption.bold())
                        .foregroundStyle(Color.jfTextTertiary)
                }

                // Push notification
                Button {
                    showPushPlaceholder = true
                } label: {
                    AdminActionRow(icon: "bell.badge.fill", label: "全ユーザーにプッシュ通知", color: Color.jfRed)
                }

                // Export data
                Button {
                    showExportPlaceholder = true
                } label: {
                    AdminActionRow(icon: "square.and.arrow.up.fill", label: "データエクスポート (CSV)", color: .blue)
                }

                // Cache clear
                Button {
                    URLCache.shared.removeAllCachedResponses()
                    apiHealthOk = nil
                    showCacheCleared = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showCacheCleared = false
                    }
                } label: {
                    HStack {
                        AdminActionRow(icon: "trash.fill", label: showCacheCleared ? "クリア完了!" : "キャッシュクリア", color: showCacheCleared ? .green : .orange)
                    }
                }
            }
            .padding(14)
            .glassCard(cornerRadius: 14)

            // Quick links
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "link")
                        .font(.caption)
                        .foregroundStyle(.cyan)
                    Text("クイックリンク")
                        .font(.caption.bold())
                        .foregroundStyle(Color.jfTextTertiary)
                }

                AdminLinkRow(icon: "apple.logo", label: "App Store Connect", url: "https://appstoreconnect.apple.com")
                AdminLinkRow(icon: "creditcard.fill", label: "Stripe Dashboard", url: "https://dashboard.stripe.com")
                AdminLinkRow(icon: "server.rack", label: "Fly.io Dashboard", url: "https://fly.io/dashboard")
            }
            .padding(14)
            .glassCard(cornerRadius: 14)
        }
        .padding(.horizontal)
        .alert("プッシュ通知", isPresented: $showPushPlaceholder) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("この機能は今後実装予定です")
        }
        .alert("データエクスポート", isPresented: $showExportPlaceholder) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("CSV エクスポート機能は今後実装予定です")
        }
    }

    private var healthIndicatorColor: Color {
        if isCheckingHealth { return .yellow }
        guard let ok = apiHealthOk else { return .gray }
        return ok ? .green : .red
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    }

    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
    }

    private var deviceInfo: String {
        #if os(iOS)
        return "iOS \(UIDevice.current.systemVersion)"
        #else
        return "Unknown"
        #endif
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
            lastRefresh = Date()
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
        isSendingAnnouncement = true
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
        isSendingAnnouncement = false

        if let updated = try? await fetchAdminAnnouncements() {
            announcements = updated
        }
    }

    private func deleteAnnouncement(id: String) async {
        _ = try? await adminRequest(path: "/api/v1/admin/announcements/\(id)", method: "DELETE")
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

// MARK: - Enhanced Stat Card

private struct AdminStatCardEnhanced: View {
    let icon: String
    let value: Int
    let label: String
    var color: Color = .blue
    var trend: TrendDirection = .neutral
    var isYen: Bool = false
    var onTap: () -> Void = {}

    enum TrendDirection {
        case up(Int)
        case down(Int)
        case neutral

        var arrow: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "minus"
            }
        }

        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .neutral: return .gray
            }
        }

        var text: String {
            switch self {
            case .up(let pct): return "+\(pct)%"
            case .down(let pct): return "-\(pct)%"
            case .neutral: return "--"
            }
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                HStack {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(color)
                    Spacer()
                    HStack(spacing: 2) {
                        Image(systemName: trend.arrow)
                            .font(.system(size: 8, weight: .bold))
                        Text(trend.text)
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(trend.color)
                }

                HStack {
                    Text(isYen ? formatYen(value) : "\(value)")
                        .font(.system(size: isYen ? 18 : 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.jfTextPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer()
                }

                HStack {
                    Text(label)
                        .font(.caption2)
                        .foregroundStyle(Color.jfTextTertiary)
                    Spacer()
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(color.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(color.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func formatYen(_ amount: Int) -> String {
        if amount >= 10000 {
            let man = Double(amount) / 10000.0
            return String(format: "¥%.1f万", man)
        }
        return "¥\(amount)"
    }
}

// MARK: - Enhanced User Row

private struct AdminUserRowEnhanced: View {
    let user: AdminUser
    let onRoleChange: (String) async -> Void
    let onDelete: () async -> Void
    @State private var showRolePicker = false
    @State private var showDeleteConfirm = false
    @State private var selectedRole: String = ""

    private let roles = ["user", "pro", "instructor", "admin"]
    private let roleLabels: [String: String] = [
        "user": "ユーザー",
        "pro": "プロ",
        "instructor": "インストラクター",
        "admin": "管理者"
    ]

    private var avatarColor: Color {
        roleColor(user.role)
    }

    private var avatarInitial: String {
        if let name = user.display_name, !name.isEmpty {
            return String(name.prefix(1)).uppercased()
        }
        if let email = user.email, !email.isEmpty {
            return String(email.prefix(1)).uppercased()
        }
        return "?"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                // Avatar circle
                ZStack {
                    Circle()
                        .fill(avatarColor.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Text(avatarInitial)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(avatarColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(user.display_name ?? "名前なし")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.jfTextPrimary)
                    Text(user.email ?? "")
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                        .lineLimit(1)
                }

                Spacer()

                // Role badge
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

            HStack(spacing: 12) {
                // Registration date
                HStack(spacing: 3) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text(String(user.created_at.prefix(10)))
                        .font(.caption2)
                }
                .foregroundStyle(Color.jfTextTertiary)

                Spacer()

                // Quick actions
                Button {
                    // Mail placeholder
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "envelope.fill")
                            .font(.caption2)
                        Text("メール")
                            .font(.caption2.bold())
                    }
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
                }

                Button {
                    selectedRole = user.role
                    showRolePicker = true
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "person.badge.key.fill")
                            .font(.caption2)
                        Text("ロール")
                            .font(.caption2.bold())
                    }
                    .foregroundStyle(.purple)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.1))
                    .clipShape(Capsule())
                }

                if user.role != "admin" {
                    Button {
                        showDeleteConfirm = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption2)
                            .foregroundStyle(.red.opacity(0.6))
                            .padding(4)
                    }
                }
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
        case "instructor": return .blue
        case "pro": return Color.jfGold
        default: return .gray
        }
    }
}

// MARK: - Enhanced Reservation Row

private struct AdminReservationRowEnhanced: View {
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
                    HStack(spacing: 4) {
                        Image(systemName: "building.2.fill")
                            .font(.caption2)
                        Text(reservation.dojo_name ?? "道場不明")
                            .font(.caption)
                    }
                    .foregroundStyle(Color.jfTextTertiary)
                }

                Spacer()

                statusBadge
            }

            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.caption2)
                    Text(reservation.user_name ?? reservation.user_email ?? "不明")
                        .font(.caption)
                }
                .foregroundStyle(Color.jfTextSecondary)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text(reservation.reserved_date)
                        .font(.caption)
                }
                .foregroundStyle(Color.jfTextSecondary)
            }

            HStack {
                if reservation.amount_jpy > 0 {
                    Text("¥\(reservation.amount_jpy)")
                        .font(.caption.bold())
                        .foregroundStyle(Color.jfTextPrimary)
                }

                if reservation.checked_in == 1 {
                    HStack(spacing: 3) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                        Text("チェックイン済")
                            .font(.caption2)
                    }
                    .foregroundStyle(.green)
                }

                Spacer()

                // Swipe-like action buttons
                if reservation.status == "pending" {
                    HStack(spacing: 8) {
                        Button {
                            Task { await onStatusChange("confirmed") }
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: "checkmark")
                                    .font(.caption2)
                                Text("確定")
                                    .font(.caption2.bold())
                            }
                            .foregroundStyle(.green)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.green.opacity(0.12))
                            .clipShape(Capsule())
                        }

                        Button {
                            Task { await onStatusChange("cancelled") }
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: "xmark")
                                    .font(.caption2)
                                Text("却下")
                                    .font(.caption2.bold())
                            }
                            .foregroundStyle(.red)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.red.opacity(0.12))
                            .clipShape(Capsule())
                        }
                    }
                } else {
                    Button {
                        showStatusPicker = true
                    } label: {
                        Text("変更")
                            .font(.caption2.bold())
                            .foregroundStyle(Color.jfTextTertiary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.jfCardBg)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(14)
        .glassCard(cornerRadius: 14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(statusBorderColor.opacity(0.2), lineWidth: 1)
        )
        .confirmationDialog("ステータスを変更", isPresented: $showStatusPicker, titleVisibility: .visible) {
            Button("確定") { Task { await onStatusChange("confirmed") } }
            Button("キャンセル扱い", role: .destructive) { Task { await onStatusChange("cancelled") } }
            Button("保留に戻す") { Task { await onStatusChange("pending") } }
            Button("閉じる", role: .cancel) {}
        }
    }

    private var statusBadge: some View {
        Text(statusLabel(reservation.status))
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(statusColor(reservation.status).opacity(0.15))
            .foregroundStyle(statusColor(reservation.status))
            .clipShape(Capsule())
    }

    private var statusBorderColor: Color {
        statusColor(reservation.status)
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

// MARK: - Filter Pill

private struct AdminFilterPill: View {
    let label: String
    let isSelected: Bool
    var color: Color = Color.jfRed
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.bold())
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? color.opacity(0.2) : Color.jfCardBg)
                .foregroundStyle(isSelected ? color : Color.jfTextTertiary)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(isSelected ? color.opacity(0.4) : Color.jfBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Status Count Badge

private struct AdminStatusCount: View {
    let label: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.jfTextTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Settings Helpers

private struct AdminSettingsRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color.jfTextSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(Color.jfTextPrimary)
        }
    }
}

private struct AdminActionRow: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color.jfTextPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(Color.jfTextTertiary)
        }
        .padding(.vertical, 4)
    }
}

private struct AdminLinkRow: View {
    let icon: String
    let label: String
    let url: String

    var body: some View {
        if let linkURL = URL(string: url) {
            Link(destination: linkURL) {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(.cyan)
                        .frame(width: 24)
                    Text(label)
                        .font(.subheadline)
                        .foregroundStyle(Color.jfTextPrimary)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption2)
                        .foregroundStyle(Color.jfTextTertiary)
                }
                .padding(.vertical, 4)
            }
        }
    }
}
