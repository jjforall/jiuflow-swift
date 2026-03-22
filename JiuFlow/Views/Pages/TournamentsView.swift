import SwiftUI

struct TournamentsView: View {
    @EnvironmentObject var api: APIService
    @EnvironmentObject var lang: LanguageManager
    @State private var searchText = ""
    @State private var selectedOrg = ""

    private var organizations: [String] {
        let orgs = Set(api.tournaments.compactMap { $0.organization }.filter { !$0.isEmpty })
        return Array(orgs).sorted()
    }

    private var filteredTournaments: [Tournament] {
        var list = api.tournaments
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            list = list.filter {
                $0.displayName(lang: lang.current).lowercased().contains(q) ||
                ($0.location ?? "").lowercased().contains(q) ||
                ($0.organization ?? "").lowercased().contains(q)
            }
        }
        if !selectedOrg.isEmpty {
            list = list.filter { ($0.organization ?? "") == selectedOrg }
        }
        return list
    }

    private var upcomingTournaments: [Tournament] {
        let today = ISO8601DateFormatter().string(from: Date()).prefix(10)
        return filteredTournaments.filter {
            guard let ds = $0.date_start else { return false }
            return ds >= String(today)
        }.sorted { ($0.date_start ?? "") < ($1.date_start ?? "") }
    }

    private var pastTournaments: [Tournament] {
        let today = ISO8601DateFormatter().string(from: Date()).prefix(10)
        return filteredTournaments.filter {
            guard let ds = $0.date_start else { return true }
            return ds < String(today)
        }.sorted { ($0.date_start ?? "") > ($1.date_start ?? "") }
    }

    var body: some View {
        NavigationStack {
            Group {
                if api.isLoading && api.tournaments.isEmpty {
                    VStack(spacing: 14) {
                        ForEach(0..<4, id: \.self) { _ in SkeletonCard(height: 100) }
                    }
                    .padding()
                } else if api.tournaments.isEmpty {
                    emptyView
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 20) {
                            orgFilterBar

                            if filteredTournaments.isEmpty {
                                noResultsView
                            } else {
                                if !upcomingTournaments.isEmpty {
                                    sectionView(
                                        title: lang.t("今後の大会", en: "Upcoming"),
                                        count: upcomingTournaments.count,
                                        color: .red,
                                        tournaments: upcomingTournaments
                                    )
                                }
                                if !pastTournaments.isEmpty {
                                    sectionView(
                                        title: lang.t("大会データベース", en: "Database"),
                                        count: pastTournaments.count,
                                        color: .gray,
                                        tournaments: pastTournaments
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 40)
                    }
                    .refreshable {
                        await api.loadTournaments()
                    }
                }
            }
            .background(Color.jfDarkBg)
            .navigationTitle(lang.t("大会情報", en: "Tournaments"))
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: lang.t("大会を検索", en: "Search tournaments"))
            .task {
                await api.loadTournaments()
            }
        }
    }

    // MARK: - Org Filter

    private var orgFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                orgButton("", label: lang.t("すべて", en: "All"))
                ForEach(organizations, id: \.self) { org in
                    orgButton(org, label: org)
                }
            }
        }
    }

    private func orgButton(_ org: String, label: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedOrg = selectedOrg == org ? "" : org
            }
        } label: {
            Text(label)
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedOrg == org ? Color.jfRed.opacity(0.2) : Color.jfCardBg)
                .foregroundStyle(selectedOrg == org ? Color.jfRed : Color.jfTextSecondary)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(selectedOrg == org ? Color.jfRed.opacity(0.5) : Color.jfBorder, lineWidth: 1)
                )
        }
    }

    // MARK: - Section

    private func sectionView(title: String, count: Int, color: Color, tournaments: [Tournament]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 4, height: 18)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.jfTextPrimary)
                Text("\(count)")
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.15))
                    .foregroundStyle(color)
                    .clipShape(Capsule())
            }

            LazyVStack(spacing: 10) {
                ForEach(tournaments) { tournament in
                    NavigationLink {
                        TournamentDetailNativeView(tournament: tournament)
                            .environmentObject(api)
                            .environmentObject(lang)
                    } label: {
                        TournamentCard(tournament: tournament, lang: lang.current)
                    }
                }
            }
        }
    }

    // MARK: - No Results (filter active)

    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(Color.jfTextTertiary)
            Text(lang.t("該当する大会がありません", en: "No tournaments found"))
                .font(.subheadline.bold())
                .foregroundStyle(Color.jfTextSecondary)
            Text(lang.t("検索条件やフィルターを変更してください", en: "Try changing your search or filter"))
                .font(.caption)
                .foregroundStyle(Color.jfTextTertiary)

            if !selectedOrg.isEmpty {
                Button {
                    withAnimation { selectedOrg = "" }
                } label: {
                    Text(lang.t("フィルターをリセット", en: "Reset filter"))
                        .font(.caption.bold())
                        .foregroundStyle(Color.jfRed)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Empty (initial load failed)

    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 56))
                .foregroundStyle(.yellow)
            Text(lang.t("大会情報", en: "Tournaments"))
                .font(.title2.bold())
                .foregroundStyle(Color.jfTextPrimary)
            Text(lang.t("大会データを読み込み中...", en: "Loading tournament data..."))
                .font(.subheadline)
                .foregroundStyle(Color.jfTextTertiary)
            Button {
                Task { await api.loadTournaments() }
            } label: {
                Label(lang.t("再読み込み", en: "Retry"), systemImage: "arrow.clockwise")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(LinearGradient.jfRedGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Tournament Card

struct TournamentCard: View {
    let tournament: Tournament
    var lang: String = "ja"

    private var levelColor: Color {
        switch tournament.level?.lowercased() {
        case "world": return .yellow
        case "continental": return .orange
        case "national": return .blue
        case "regional": return .green
        default: return .gray
        }
    }

    private var countryFlag: String {
        switch tournament.country?.uppercased() {
        case "JP", "JAPAN": return "🇯🇵"
        case "US", "USA": return "🇺🇸"
        case "BR", "BRAZIL": return "🇧🇷"
        case "AU": return "🇦🇺"
        case "GB", "UK": return "🇬🇧"
        case "AE", "UAE": return "🇦🇪"
        case "KR": return "🇰🇷"
        case "TH": return "🇹🇭"
        default: return ""
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                if let org = tournament.organization, !org.isEmpty {
                    CategoryBadge(text: org, color: .blue)
                }
                if tournament.gi == true {
                    CategoryBadge(text: "Gi", color: .purple)
                }
                if tournament.nogi == true {
                    CategoryBadge(text: "No-Gi", color: .orange)
                }
                if !countryFlag.isEmpty {
                    Text(countryFlag)
                        .font(.caption)
                }
                if tournament.has_results == true {
                    Image(systemName: "medal.fill")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                }
                Spacer()
            }

            Text(tournament.displayName(lang: lang))
                .font(.subheadline.bold())
                .foregroundStyle(Color.jfTextPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            HStack(spacing: 12) {
                if !tournament.displayDate.isEmpty {
                    Label(tournament.displayDate, systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                }
                if let loc = tournament.location, !loc.isEmpty {
                    Label(loc, systemImage: "mappin")
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                        .lineLimit(1)
                }
                Spacer()
                Link(destination: URL(string: "https://jiuflow-ssr.fly.dev/sjjjf/tournament/\(tournament.id)/enter")!) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil.and.list.clipboard")
                        Text("SJJJF Entry")
                    }
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.jfRed)
                    .cornerRadius(6)
                }
            }
        }
        .padding(14)
        .glassCard()
    }
}

// MARK: - Tournament Detail Native View

struct TournamentDetailNativeView: View {
    let tournament: Tournament
    @EnvironmentObject var api: APIService
    @EnvironmentObject var lang: LanguageManager
    @State private var detail: TournamentDetail?
    @State private var isLoading = true
    @State private var expandedYear: Int?

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                if isLoading {
                    VStack(spacing: 14) {
                        ForEach(0..<3, id: \.self) { _ in SkeletonCard(height: 60) }
                    }
                } else if let d = detail {
                    detailContent(d)
                } else {
                    fallbackContent
                }
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .background(Color.jfDarkBg)
        .navigationTitle(tournament.displayName(lang: lang.current))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let year = tournament.year, let slug = tournament.slug {
                detail = await api.loadTournamentDetail(year: year, slug: slug)
            }
            isLoading = false
        }
    }

    // MARK: - Detail Content

    private func detailContent(_ d: TournamentDetail) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Badges
            badgesRow(d)

            // Info cards
            infoGrid(d)

            // Registration button
            if let url = d.registration_url, let link = URL(string: url) {
                Link(destination: link) {
                    HStack(spacing: 8) {
                        Image(systemName: "pencil.and.list.clipboard")
                        Text(lang.t("エントリーする", en: "Register"))
                            .font(.subheadline.bold())
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(LinearGradient.jfRedGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            // Weight classes
            if let wcs = d.weight_classes, !wcs.isEmpty {
                infoSection(title: lang.t("階級", en: "Weight Classes")) {
                    FlowLayout(spacing: 8) {
                        ForEach(wcs, id: \.self) { wc in
                            Text(wc)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.jfCardBg)
                                .foregroundStyle(Color.jfTextSecondary)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color.jfBorder, lineWidth: 1))
                        }
                    }
                }
            }

            // Description
            let desc = d.displayDescription(lang: lang.current)
            if !desc.isEmpty {
                infoSection(title: lang.t("概要", en: "Overview")) {
                    Text(desc)
                        .font(.subheadline)
                        .foregroundStyle(Color.jfTextSecondary)
                        .lineSpacing(4)
                }
            }

            // Results
            if let results = d.results, !results.isEmpty {
                resultsSection(results)
            }
        }
    }

    // MARK: - Badges

    private func badgesRow(_ d: TournamentDetail) -> some View {
        HStack(spacing: 8) {
            if let org = d.organization, !org.isEmpty {
                CategoryBadge(text: org, color: .blue)
            }
            if d.gi == true {
                CategoryBadge(text: "Gi", color: .purple)
            }
            if d.nogi == true {
                CategoryBadge(text: "No-Gi", color: .orange)
            }
        }
    }

    // MARK: - Info Grid

    private func infoGrid(_ d: TournamentDetail) -> some View {
        let items: [(String, String, String)] = [
            ("calendar", lang.t("日程", en: "Date"), d.displayDate),
            ("mappin", lang.t("開催地", en: "Location"), d.location ?? ""),
            ("person.2", lang.t("主催", en: "Organizer"), d.organizer ?? ""),
            ("building.2", lang.t("会場", en: "Venue"), d.venue ?? ""),
            ("creditcard", lang.t("参加費", en: "Entry Fee"), d.entry_fee ?? ""),
        ].filter { !$0.2.isEmpty }

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(items, id: \.1) { icon, label, value in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(Color.jfRed)
                        .frame(width: 20)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(label)
                            .font(.caption2)
                            .foregroundStyle(Color.jfTextTertiary)
                        Text(value)
                            .font(.caption.bold())
                            .foregroundStyle(Color.jfTextPrimary)
                            .lineLimit(2)
                    }
                    Spacer()
                }
                .padding(10)
                .glassCard(cornerRadius: 10)
            }
        }
    }

    // MARK: - Info Section

    private func infoSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(Color.jfTextTertiary)
                .textCase(.uppercase)
            content()
        }
        .padding(14)
        .glassCard()
    }

    // MARK: - Results

    private func resultsSection(_ results: [TournamentResultYear]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.jfRed)
                    .frame(width: 4, height: 18)
                Text(lang.t("大会結果", en: "Results"))
                    .font(.headline)
                    .foregroundStyle(Color.jfTextPrimary)
            }

            ForEach(results) { ry in
                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            expandedYear = expandedYear == ry.year ? nil : ry.year
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text("\(ry.year)")
                                .font(.subheadline.bold())
                                .foregroundStyle(Color.jfTextPrimary)
                            Text("\(ry.divisions.count) \(lang.t("部門", en: "divisions"))")
                                .font(.caption2.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.jfRed.opacity(0.15))
                                .foregroundStyle(Color.jfRed)
                                .clipShape(Capsule())
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                                .foregroundStyle(Color.jfTextTertiary)
                                .rotationEffect(.degrees(expandedYear == ry.year ? 180 : 0))
                        }
                    }

                    if expandedYear == ry.year || (expandedYear == nil && ry.id == results.first?.id) {
                        LazyVStack(spacing: 8) {
                            ForEach(ry.divisions) { div in
                                divisionCard(div)
                            }
                        }
                    }
                }
            }
        }
    }

    private func divisionCard(_ div: TournamentResultDivision) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(div.division)
                .font(.caption.bold())
                .foregroundStyle(Color.jfTextTertiary)

            medalRow(rank: 1, name: div.gold, color: .yellow)
            if !div.silver.isEmpty {
                medalRow(rank: 2, name: div.silver, color: .gray)
            }
            ForEach(div.bronze, id: \.self) { b in
                medalRow(rank: 3, name: b, color: .brown)
            }
        }
        .padding(12)
        .glassCard(cornerRadius: 10)
    }

    private func medalRow(rank: Int, name: String, color: Color) -> some View {
        let medalName = rank == 1 ? "Gold" : rank == 2 ? "Silver" : "Bronze"
        return HStack(spacing: 8) {
            ZStack {
                Circle().fill(
                    LinearGradient(colors: [color, color.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                Image(systemName: rank == 1 ? "medal.fill" : rank == 2 ? "medal" : "circle.fill")
                    .font(.system(size: rank <= 2 ? 11 : 5))
                    .foregroundStyle(.white)
            }
            .frame(width: 24, height: 24)
            Text(name)
                .font(.caption)
                .foregroundStyle(rank == 1 ? Color.yellow : Color.jfTextSecondary)
                .fontWeight(rank == 1 ? .bold : .regular)
        }
        .accessibilityLabel("\(medalName): \(name)")
    }

    // MARK: - Fallback (no detail data)

    private var fallbackContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            badgesFallback

            if !tournament.displayDate.isEmpty {
                Label(tournament.displayDate, systemImage: "calendar")
                    .font(.subheadline)
                    .foregroundStyle(Color.jfTextSecondary)
            }
            if let loc = tournament.location, !loc.isEmpty {
                Label(loc, systemImage: "mappin")
                    .font(.subheadline)
                    .foregroundStyle(Color.jfTextSecondary)
            }

            let desc = tournament.displayDescription(lang: lang.current)
            if !desc.isEmpty {
                Text(desc)
                    .font(.subheadline)
                    .foregroundStyle(Color.jfTextTertiary)
                    .lineSpacing(4)
            }
        }
    }

    private var badgesFallback: some View {
        HStack(spacing: 8) {
            if let org = tournament.organization, !org.isEmpty {
                CategoryBadge(text: org, color: .blue)
            }
            if tournament.gi == true {
                CategoryBadge(text: "Gi", color: .purple)
            }
            if tournament.nogi == true {
                CategoryBadge(text: "No-Gi", color: .orange)
            }
        }
    }
}
