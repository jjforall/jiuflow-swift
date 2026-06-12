import SwiftUI

// MARK: - OrganizerView

struct OrganizerView: View {
    @EnvironmentObject var api: APIService
    @EnvironmentObject var lang: LanguageManager
    @State private var tournaments: [OrganizerTournament] = []
    @State private var isLoading = true
    @State private var errorMsg: String?

    var body: some View {
        ZStack {
            Color(white: 0.04).ignoresSafeArea()
            if isLoading {
                VStack(spacing: 14) {
                    ForEach(0..<3, id: \.self) { _ in SkeletonCard(height: 70) }
                }
                .padding()
            } else if let err = errorMsg {
                VStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .font(.largeTitle)
                        .foregroundStyle(Color.jfTextTertiary)
                    Text(err)
                        .font(.subheadline)
                        .foregroundStyle(Color.jfTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else if tournaments.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.badge.key")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.jfTextTertiary)
                    Text(lang.t("主催大会なし", en: "No organizer tournaments"))
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.jfTextSecondary)
                    Text(lang.t("主催者権限を取得するには管理者にお問い合わせください", en: "Contact admin to obtain organizer access"))
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        ForEach(tournaments) { t in
                            NavigationLink {
                                OrganizerDetailView(tournament: t)
                            } label: {
                                OrganizerTournamentCard(tournament: t, lang: lang)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .navigationTitle(lang.t("主催者管理", en: "Organizer"))
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadTournaments() }
    }

    private func loadTournaments() async {
        isLoading = true
        errorMsg = nil
        do {
            tournaments = try await api.fetchOrganizerTournaments()
        } catch {
            errorMsg = lang.t("主催者権限が必要です", en: "Organizer access required")
        }
        isLoading = false
    }
}

// MARK: - OrganizerTournamentCard

private struct OrganizerTournamentCard: View {
    let tournament: OrganizerTournament
    let lang: LanguageManager

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(tournament.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .lineLimit(2)
                HStack(spacing: 8) {
                    Label(tournament.date_start, systemImage: "calendar")
                    if !tournament.location.isEmpty {
                        Label(tournament.location, systemImage: "mappin")
                    }
                }
                .font(.caption)
                .foregroundStyle(Color.jfTextTertiary)
                .lineLimit(1)
            }
            Spacer()
            VStack(spacing: 4) {
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(Color.jfTextTertiary)
                Text(tournament.organizer_role)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color(red: 0.26, green: 0.83, blue: 0.5))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(red: 0.26, green: 0.83, blue: 0.5).opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .padding(14)
        .glassCard()
    }
}

// MARK: - OrganizerDetailView

struct OrganizerDetailView: View {
    let tournament: OrganizerTournament
    @EnvironmentObject var api: APIService
    @EnvironmentObject var lang: LanguageManager
    @State private var entries: [TournamentEntry] = []
    @State private var isLoading = true
    @State private var selectedTab = 0
    @State private var pendingResults: [String: Int] = [:]
    @State private var toastMsg: String?
    @State private var filterBelt = ""
    @State private var searchText = ""
    @State private var showQRScanner = false
    @State private var showNotifySheet = false

    var filteredEntries: [TournamentEntry] {
        entries.filter { e in
            (filterBelt.isEmpty || e.belt == filterBelt) &&
            (searchText.isEmpty || e.display_name.localizedCaseInsensitiveContains(searchText) ||
             (e.dojo_name ?? "").localizedCaseInsensitiveContains(searchText))
        }
    }

    var checkedInCount: Int { entries.filter { $0.checked_in == 1 }.count }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(white: 0.04).ignoresSafeArea()
            VStack(spacing: 0) {
                // Stats bar
                HStack(spacing: 0) {
                    statCell(num: "\(entries.count)", label: lang.t("エントリー", en: "Entries"))
                    Divider().frame(height: 36)
                    statCell(num: "\(checkedInCount)", label: "✓ IN", color: Color(red: 0.26, green: 0.83, blue: 0.5))
                    Divider().frame(height: 36)
                    statCell(num: "\(entries.count - checkedInCount)", label: lang.t("未確認", en: "Pending"), color: Color(red: 0.98, green: 0.75, blue: 0.26))
                }
                .padding(.vertical, 12)
                .background(Color.jfCardBg)
                .overlay(Rectangle().frame(height: 1).foregroundStyle(Color.jfBorder), alignment: .bottom)

                // Tab selector
                Picker("", selection: $selectedTab) {
                    Text(lang.t("チェックイン", en: "Check-in")).tag(0)
                    Text(lang.t("結果入力", en: "Results")).tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.jfCardBg)

                // Search & filter
                VStack(spacing: 8) {
                    TextField(lang.t("名前・道場で検索", en: "Search name / dojo"), text: $searchText)
                        .padding(10)
                        .background(Color.jfCardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.jfBorder))

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            beltFilterBtn("", label: lang.t("全帯", en: "All"))
                            beltFilterBtn("white", label: lang.t("白", en: "White"))
                            beltFilterBtn("blue", label: lang.t("青", en: "Blue"))
                            beltFilterBtn("purple", label: lang.t("紫", en: "Purple"))
                            beltFilterBtn("brown", label: lang.t("茶", en: "Brown"))
                            beltFilterBtn("black", label: lang.t("黒", en: "Black"))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
                .background(Color(white: 0.04))

                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else {
                    if selectedTab == 0 {
                        checkinList
                    } else {
                        resultsList
                    }
                }
            }

            // Toast
            if let msg = toastMsg {
                Text(msg)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.85))
                    .clipShape(Capsule())
                    .padding(.bottom, 32)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { toastMsg = nil }
                        }
                    }
            }
        }
        .navigationTitle(tournament.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if selectedTab == 0 {
                    Button { showQRScanner = true } label: {
                        Image(systemName: "qrcode.viewfinder")
                    }
                    .foregroundStyle(Color.jfRed)
                }
                Button { showNotifySheet = true } label: {
                    Image(systemName: "bell.badge.fill")
                }
                .foregroundStyle(Color.jfRed)
                if selectedTab == 1 && !pendingResults.isEmpty {
                    Button(lang.t("保存", en: "Save")) {
                        Task { await saveResults() }
                    }
                    .fontWeight(.bold)
                    .foregroundStyle(Color.jfRed)
                }
            }
        }
        .sheet(isPresented: $showQRScanner) {
            QRCheckinSheet(tournamentId: tournament.id)
                .environmentObject(api)
                .onDisappear { Task { await loadEntries() } }
        }
        .sheet(isPresented: $showNotifySheet) {
            NotifySheet(tournamentId: tournament.id)
                .environmentObject(api)
                .environmentObject(lang)
        }
        .task { await loadEntries() }
    }

    // MARK: - Check-in list

    private var checkinList: some View {
        List {
            ForEach(filteredEntries) { entry in
                CheckinRow(entry: entry, lang: lang) { newState in
                    Task { await toggleCheckin(entry: entry, checkedIn: newState) }
                }
                .listRowBackground(Color.jfCardBg)
                .listRowSeparatorTint(Color.jfBorder)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Results list

    private var resultsList: some View {
        List {
            ForEach(filteredEntries) { entry in
                ResultRow(entry: entry, pending: pendingResults[entry.id], lang: lang) { place in
                    pendingResults[entry.id] = place
                }
                .listRowBackground(Color.jfCardBg)
                .listRowSeparatorTint(Color.jfBorder)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Helpers

    private func statCell(num: String, label: String, color: Color = Color.jfRed) -> some View {
        VStack(spacing: 2) {
            Text(num).font(.title3.bold()).foregroundStyle(color)
            Text(label).font(.system(size: 10)).foregroundStyle(Color.jfTextTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private func beltFilterBtn(_ belt: String, label: String) -> some View {
        Button {
            filterBelt = belt
        } label: {
            Text(label)
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(filterBelt == belt ? Color.jfRed : Color.jfCardBg)
                .foregroundStyle(filterBelt == belt ? .white : Color.jfTextSecondary)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(filterBelt == belt ? Color.jfRed : Color.jfBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func loadEntries() async {
        isLoading = true
        do {
            entries = try await api.fetchOrganizerEntries(tournamentId: tournament.id)
        } catch {}
        isLoading = false
    }

    private func toggleCheckin(entry: TournamentEntry, checkedIn: Bool) async {
        do {
            try await api.updateCheckin(tournamentId: tournament.id, entryId: entry.id, checkedIn: checkedIn)
            await loadEntries()
            withAnimation { toastMsg = checkedIn ? "✓ チェックイン" : "解除" }
        } catch {
            withAnimation { toastMsg = "エラー" }
        }
    }

    private func saveResults() async {
        let toSave = pendingResults.filter { $0.value > 0 }.map { (entryId: $0.key, place: $0.value) }
        guard !toSave.isEmpty else { return }
        do {
            try await api.recordResults(tournamentId: tournament.id, entries: toSave)
            pendingResults.removeAll()
            await loadEntries()
            withAnimation { toastMsg = lang.t("結果を保存しました", en: "Results saved") }
        } catch {
            withAnimation { toastMsg = lang.t("保存に失敗しました", en: "Save failed") }
        }
    }
}

// MARK: - CheckinRow

private struct CheckinRow: View {
    let entry: TournamentEntry
    let lang: LanguageManager
    let onToggle: (Bool) -> Void
    @State private var isLoading = false

    private var isCheckedIn: Bool { entry.checked_in == 1 }

    var body: some View {
        HStack(spacing: 12) {
            // Check-in button
            Button {
                isLoading = true
                onToggle(!isCheckedIn)
            } label: {
                ZStack {
                    Circle()
                        .fill(isCheckedIn ? Color(red: 0.08, green: 0.33, blue: 0.17) : Color.jfCardBg)
                        .frame(width: 34, height: 34)
                        .overlay(Circle().stroke(isCheckedIn ? Color(red: 0.26, green: 0.83, blue: 0.5) : Color.jfBorder, lineWidth: 1.5))
                    if isLoading {
                        ProgressView().scaleEffect(0.6)
                    } else {
                        Image(systemName: isCheckedIn ? "checkmark" : "circle")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(isCheckedIn ? Color(red: 0.26, green: 0.83, blue: 0.5) : Color.jfTextTertiary)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(isLoading)

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.display_name)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                HStack(spacing: 6) {
                    BeltBadge(belt: entry.belt)
                    Text(entry.weight_class)
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                    Text(entry.gi_nogi.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.jfTextTertiary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.jfBorder)
                        .clipShape(Capsule())
                }
            }
            Spacer()
            if let dojo = entry.dojo_name, !dojo.isEmpty {
                Text(dojo)
                    .font(.caption2)
                    .foregroundStyle(Color.jfTextTertiary)
                    .lineLimit(1)
                    .frame(maxWidth: 80, alignment: .trailing)
            }
        }
        .padding(.vertical, 4)
        .onChange(of: entry.checked_in) { _, _ in isLoading = false }
    }
}

// MARK: - ResultRow

private struct ResultRow: View {
    let entry: TournamentEntry
    let pending: Int?
    let lang: LanguageManager
    let onSelect: (Int) -> Void

    private var displayPlace: Int { pending ?? Int(entry.place ?? 0) }

    var body: some View {
        HStack(spacing: 12) {
            // Medal display
            placeMedal(displayPlace)

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.display_name)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                HStack(spacing: 6) {
                    BeltBadge(belt: entry.belt)
                    Text(entry.weight_class)
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                }
            }
            Spacer()
            // Place picker
            Menu {
                Button("—") { onSelect(0) }
                Button("🥇 1位") { onSelect(1) }
                Button("🥈 2位") { onSelect(2) }
                Button("🥉 3位") { onSelect(3) }
                Button("4位") { onSelect(4) }
            } label: {
                HStack(spacing: 4) {
                    Text(placeLabel(displayPlace))
                        .font(.caption.bold())
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 9))
                }
                .foregroundStyle(pending != nil ? Color(red: 0.83, green: 0.66, blue: 0.33) : Color.jfTextSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(pending != nil ? Color(red: 0.83, green: 0.66, blue: 0.33).opacity(0.15) : Color.jfBorder.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 7))
                .overlay(RoundedRectangle(cornerRadius: 7).stroke(
                    pending != nil ? Color(red: 0.83, green: 0.66, blue: 0.33).opacity(0.5) : Color.clear, lineWidth: 1))
            }
        }
        .padding(.vertical, 4)
    }

    private func placeLabel(_ place: Int) -> String {
        switch place {
        case 1: return "🥇 1位"
        case 2: return "🥈 2位"
        case 3: return "🥉 3位"
        case 4: return "4位"
        default: return "—"
        }
    }

    private func placeMedal(_ place: Int) -> some View {
        ZStack {
            Circle()
                .fill(medalColor(place).opacity(0.15))
                .frame(width: 34, height: 34)
            Text(medalEmoji(place))
                .font(.system(size: 16))
        }
    }

    private func medalColor(_ place: Int) -> Color {
        switch place {
        case 1: return Color(red: 0.83, green: 0.66, blue: 0.33)
        case 2: return Color(white: 0.7)
        case 3: return Color(red: 0.72, green: 0.45, blue: 0.2)
        default: return Color.jfBorder
        }
    }

    private func medalEmoji(_ place: Int) -> String {
        switch place {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "—"
        }
    }
}

// MARK: - NotifySheet

struct NotifySheet: View {
    let tournamentId: String
    @EnvironmentObject var api: APIService
    @EnvironmentObject var lang: LanguageManager
    @Environment(\.dismiss) private var dismiss
    @State private var notifyTitle = ""
    @State private var notifyBody = ""
    @State private var isSending = false
    @State private var sent = false
    @State private var errorMsg: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(white: 0.04).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(lang.t("タイトル", en: "Title"))
                                .font(.caption.bold())
                                .foregroundStyle(Color.jfTextTertiary)
                            TextField(lang.t("例: 試合開始のお知らせ", en: "e.g. Match Starting Soon"), text: $notifyTitle)
                                .padding(12)
                                .background(Color.jfCardBg)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.jfBorder))
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text(lang.t("本文", en: "Message"))
                                .font(.caption.bold())
                                .foregroundStyle(Color.jfTextTertiary)
                            TextField(lang.t("例: マット2番に集合してください", en: "e.g. Please go to mat 2"), text: $notifyBody, axis: .vertical)
                                .lineLimit(3...6)
                                .padding(12)
                                .background(Color.jfCardBg)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.jfBorder))
                        }

                        // Quick templates
                        VStack(alignment: .leading, spacing: 8) {
                            Text(lang.t("クイックテンプレート", en: "Quick Templates"))
                                .font(.caption.bold())
                                .foregroundStyle(Color.jfTextTertiary)
                            ForEach([
                                ("⚔️ 試合開始", "マット3番に集合してください。5分後に試合開始です。"),
                                ("⏰ 準備時間", "15分後に試合が始まります。ウォームアップを始めてください。"),
                                ("🏆 表彰式", "表彰式を開始します。受賞者は受付前にお集まりください。"),
                            ], id: \.0) { tmpl in
                                Button {
                                    self.notifyTitle = tmpl.0
                                    self.notifyBody = tmpl.1
                                } label: {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(tmpl.0).font(.caption.bold()).foregroundStyle(.white)
                                        Text(tmpl.1).font(.caption2).foregroundStyle(Color.jfTextTertiary).lineLimit(1)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(10)
                                    .background(Color.jfCardBg)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.jfBorder))
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        if sent {
                            Label(lang.t("送信完了", en: "Sent"), systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                        if let err = errorMsg {
                            Text(err).font(.caption).foregroundStyle(.red)
                        }

                        Button {
                            Task { await send() }
                        } label: {
                            HStack {
                                if isSending {
                                    ProgressView().scaleEffect(0.8).tint(.white)
                                } else {
                                    Image(systemName: "bell.fill")
                                }
                                Text(lang.t("全選手に送信", en: "Send to All Athletes"))
                                    .font(.subheadline.bold())
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(notifyTitle.isEmpty || notifyBody.isEmpty || isSending ? Color.gray.opacity(0.4) : Color.jfRed)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(notifyTitle.isEmpty || notifyBody.isEmpty || isSending)
                    }
                    .padding()
                }
            }
            .navigationTitle(lang.t("プッシュ通知送信", en: "Send Notification"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }.foregroundStyle(Color.jfRed)
                }
            }
        }
    }

    private func send() async {
        isSending = true; errorMsg = nil
        do {
            try await api.sendNotification(tournamentId: tournamentId, title: notifyTitle, body: notifyBody)
            withAnimation { sent = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
        } catch {
            errorMsg = error.localizedDescription
        }
        isSending = false
    }
}
