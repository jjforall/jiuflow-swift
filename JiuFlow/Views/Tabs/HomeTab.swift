import SwiftUI

struct HomeTab: View {
    @EnvironmentObject var api: APIService
    @EnvironmentObject var lang: LanguageManager

    private var upcomingTournaments: [Tournament] {
        let today = ISO8601DateFormatter().string(from: Date()).prefix(10)
        return api.tournaments
            .filter { guard let ds = $0.date_start else { return false }; return ds >= String(today) }
            .sorted { ($0.date_start ?? "") < ($1.date_start ?? "") }
            .prefix(3).map { $0 }
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Greeting
                    greetingSection

                    VStack(spacing: 20) {
                        // Quick nav cards
                        quickNavSection

                        // Upcoming tournaments
                        if !upcomingTournaments.isEmpty {
                            upcomingSection
                        }

                        // Latest news (compact)
                        if !api.news.isEmpty {
                            newsSection
                        }

                        // Latest videos
                        if !api.videos.isEmpty {
                            videosSection
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .background(Color.jfDarkBg)
            .navigationTitle(lang.t("ホーム", en: "Home"))
            .navigationBarTitleDisplayMode(.large)
            .task {
                async let n: () = api.loadNews()
                async let v: () = api.loadVideos()
                async let t: () = api.loadTournaments()
                _ = await (n, v, t)
            }
            .refreshable {
                async let n: () = api.loadNews()
                async let v: () = api.loadVideos()
                async let t: () = api.loadTournaments()
                _ = await (n, v, t)
            }
        }
    }

    // MARK: - Greeting

    private var greetingSection: some View {
        ZStack {
            LinearGradient(
                colors: [Color.jfRed.opacity(0.12), Color.jfDarkBg],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 8) {
                if api.isLoggedIn, let name = api.currentUser?.display_name {
                    Text(lang.t("おかえり、\(name)さん", en: "Welcome back, \(name)"))
                        .font(.title2.bold())
                        .foregroundStyle(Color.jfTextPrimary)
                } else {
                    Text(lang.t("柔術が、もっとうまくなる", en: "Level up your Jiu-Jitsu"))
                        .font(.title2.bold())
                        .foregroundStyle(Color.jfTextPrimary)
                }
                Text(lang.t("今日もマットの上で成長しよう", en: "Get better on the mats today"))
                    .font(.subheadline)
                    .foregroundStyle(Color.jfTextTertiary)
            }
            .padding(.vertical, 36)
        }
    }

    // MARK: - Quick Nav

    private var quickNavSection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                NavigationLink {
                    DojosTab().environmentObject(api)
                } label: {
                    quickCard(
                        icon: "mappin.circle.fill",
                        title: lang.t("道場を探す", en: "Find Dojo"),
                        color: .green
                    )
                }

                NavigationLink {
                    FlowTab()
                } label: {
                    quickCard(
                        icon: "arrow.triangle.branch",
                        title: lang.t("テクニック", en: "Techniques"),
                        color: .blue
                    )
                }
            }

            HStack(spacing: 10) {
                NavigationLink {
                    GamePlansView()
                } label: {
                    quickCard(
                        icon: "checklist",
                        title: lang.t("ゲームプラン", en: "Game Plans"),
                        color: .purple
                    )
                }

                NavigationLink {
                    TournamentsView()
                } label: {
                    quickCard(
                        icon: "trophy.fill",
                        title: lang.t("大会情報", en: "Tournaments"),
                        color: .orange
                    )
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private func quickCard(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 36)
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(Color.jfTextPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(Color.jfTextTertiary)
        }
        .padding(14)
        .glassCard(cornerRadius: 14)
    }

    // MARK: - Upcoming Tournaments

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionHeader(title: lang.t("直近の大会", en: "Upcoming Tournaments"), icon: "calendar")
                Spacer()
                NavigationLink {
                    TournamentsView()
                } label: {
                    Text(lang.t("すべて", en: "All"))
                        .font(.caption.bold())
                        .foregroundStyle(Color.jfTextTertiary)
                }
            }
            .padding(.horizontal, 16)

            VStack(spacing: 8) {
                ForEach(upcomingTournaments) { t in
                    NavigationLink {
                        TournamentDetailNativeView(tournament: t)
                            .environmentObject(api)
                            .environmentObject(lang)
                    } label: {
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.jfRed.opacity(0.15))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: "trophy.fill")
                                        .font(.caption)
                                        .foregroundStyle(Color.jfRed)
                                )
                            VStack(alignment: .leading, spacing: 2) {
                                Text(t.displayName(lang: lang.current))
                                    .font(.caption.bold())
                                    .foregroundStyle(Color.jfTextPrimary)
                                    .lineLimit(1)
                                Text("\(t.displayDate) · \(t.location ?? "")")
                                    .font(.caption2)
                                    .foregroundStyle(Color.jfTextTertiary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            if let org = t.organization, !org.isEmpty {
                                CategoryBadge(text: org, color: .blue)
                            }
                        }
                        .padding(12)
                        .glassCard(cornerRadius: 12)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - News (compact)

    private var newsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: lang.t("最新ニュース", en: "Latest News"), icon: "newspaper.fill")
                .padding(.horizontal, 16)

            VStack(spacing: 8) {
                ForEach(api.news.prefix(3)) { item in
                    NavigationLink {
                        NewsDetailView(item: item)
                    } label: {
                        CompactNewsRow(item: item)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Videos (horizontal)

    private var videosSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: lang.t("新着動画", en: "Latest Videos"), icon: "play.rectangle.fill")
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 14) {
                    ForEach(api.videos.prefix(8)) { video in
                        NavigationLink {
                            VideoDetailView(video: video, baseURL: api.baseURL)
                        } label: {
                            VideoCard(video: video, baseURL: api.baseURL)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - Compact News Row

struct CompactNewsRow: View {
    let item: NewsItem

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(item.displayTitle)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.jfTextPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                HStack(spacing: 8) {
                    CategoryBadge(text: item.categoryLabel, color: categoryColor(item.category))
                    Text(item.relativeDate)
                        .font(.caption2)
                        .foregroundStyle(Color.jfTextTertiary)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.jfTextTertiary)
        }
        .padding(14)
        .glassCard()
    }

    private func categoryColor(_ category: String?) -> Color {
        switch category {
        case "bjj": return .orange
        case "technique": return .blue
        case "site": return .green
        default: return .jfRed
        }
    }
}

// MARK: - News Detail View

struct NewsDetailView: View {
    let item: NewsItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    CategoryBadge(text: item.categoryLabel)
                    if item.is_featured == true {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                    }
                    Spacer()
                    Text(item.relativeDate)
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                }
                Text(item.displayTitle)
                    .font(.title2.bold())
                    .foregroundStyle(Color.jfTextPrimary)
                if let author = item.author {
                    Label(author, systemImage: "person.circle")
                        .font(.caption)
                        .foregroundStyle(Color.jfTextSecondary)
                }
                Divider().background(Color.jfBorder)
                Text(item.displaySummary)
                    .font(.body)
                    .foregroundStyle(Color.jfTextSecondary)
                    .lineSpacing(6)
            }
            .padding()
        }
        .background(Color.jfDarkBg)
        .navigationBarTitleDisplayMode(.inline)
    }
}
