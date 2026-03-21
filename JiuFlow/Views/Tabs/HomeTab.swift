import SwiftUI

struct HomeTab: View {
    @EnvironmentObject var api: APIService
    @State private var heroPhase: CGFloat = 0

    private var featuredNews: [NewsItem] {
        api.news.filter { $0.is_featured == true }
    }

    private var tournamentNews: [NewsItem] {
        api.news.filter { $0.category == "bjj" }
    }

    private var featuredAthletes: [Athlete] {
        api.athletes.filter { $0.featured == true }
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    heroSection
                    quickActions
                        .padding(.top, -20)

                    VStack(spacing: 28) {
                        if !featuredNews.isEmpty {
                            featuredNewsSection
                        }

                        if !api.videos.isEmpty {
                            latestVideosSection
                        }

                        if !featuredAthletes.isEmpty {
                            featuredAthletesSection
                        }

                        if !tournamentNews.isEmpty {
                            tournamentSection
                        }

                        if !api.news.isEmpty {
                            latestNewsSection
                        }

                        discoverSection
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .background(Color.jfDarkBg)
            .navigationTitle("ホーム")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                async let newsTask: () = api.loadNews()
                async let videosTask: () = api.loadVideos()
                async let athletesTask: () = api.loadAthletes()
                _ = await (newsTask, videosTask, athletesTask)
            }
            .refreshable {
                async let newsTask: () = api.loadNews()
                async let videosTask: () = api.loadVideos()
                async let athletesTask: () = api.loadAthletes()
                _ = await (newsTask, videosTask, athletesTask)
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        ZStack {
            // Background image with overlay
            AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1555597673-b21d5c935865?w=800&q=80")) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                        .overlay(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.85),
                                    Color.black.opacity(0.5),
                                    Color.black.opacity(0.85)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                default:
                    // Animated gradient background fallback
                    LinearGradient(
                        colors: [
                            Color.black,
                            Color.jfRed.opacity(0.15),
                            Color(red: 0.08, green: 0.0, blue: 0.0),
                            Color.black
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }

            // Subtle radial glow
            RadialGradient(
                colors: [Color.jfRed.opacity(0.18), .clear],
                center: .center,
                startRadius: 20,
                endRadius: 280
            )
            .offset(y: -30)

            VStack(spacing: 18) {
                Text("JiuFlow")
                    .font(.system(size: 56, weight: .black, design: .rounded))
                    .tracking(-2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.85)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .jfRed.opacity(0.3), radius: 20)

                Text("怪我なく、長く、強く。")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.jfTextPrimary.opacity(0.9))

                Text("身体に無理なく続けられ、\n試合でも通用する本質的な柔術")
                    .font(.subheadline)
                    .foregroundStyle(Color.jfTextTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 2)
            }
            .padding(.vertical, 72)
        }
        .frame(minHeight: 300)
        .clipped()
    }

    // MARK: - Quick Actions

    @State private var quickActionTap = false

    private var quickActions: some View {
        HStack(spacing: 0) {
            QuickAction(icon: "figure.martial.arts", title: "テクニック", color: .jfRed)
                .frame(maxWidth: .infinity)
                .onTapGesture { quickActionTap.toggle() }
            QuickAction(icon: "play.rectangle.fill", title: "動画", color: .blue)
                .frame(maxWidth: .infinity)
                .onTapGesture { quickActionTap.toggle() }
            QuickAction(icon: "person.3.fill", title: "選手", color: .orange)
                .frame(maxWidth: .infinity)
                .onTapGesture { quickActionTap.toggle() }
            QuickAction(icon: "mappin.circle.fill", title: "道場", color: .green)
                .frame(maxWidth: .infinity)
                .onTapGesture { quickActionTap.toggle() }
        }
        .sensoryFeedback(.impact(flexibility: .soft), trigger: quickActionTap)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .glassCard(cornerRadius: 20)
        .padding(.horizontal, 16)
    }

    // MARK: - Featured News

    private var featuredNewsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "注目ニュース", icon: "star.fill")
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 14) {
                    ForEach(featuredNews) { item in
                        NavigationLink {
                            NewsDetailView(item: item)
                        } label: {
                            FeaturedNewsCard(item: item)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Latest Videos

    private var latestVideosSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "新着動画", icon: "play.rectangle.fill", showMore: true)
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 14) {
                    ForEach(api.videos.prefix(10)) { video in
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

    // MARK: - Featured Athletes

    private var featuredAthletesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "注目選手", icon: "person.3.fill", showMore: true)
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(featuredAthletes) { athlete in
                        NavigationLink {
                            AthleteDetailView(athlete: athlete)
                        } label: {
                            HomeAthleteCard(athlete: athlete)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Tournaments

    private var tournamentSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "大会情報", icon: "trophy.fill")
                .padding(.horizontal, 16)

            VStack(spacing: 10) {
                ForEach(tournamentNews.prefix(5)) { item in
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

    // MARK: - Discover Section

    private var discoverSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "もっと探す", icon: "sparkle.magnifyingglass")
                .padding(.horizontal, 16)

            let items: [(String, String, Color, AnyView)] = [
                ("trophy.fill", "大会情報", .yellow, AnyView(TournamentsView().environmentObject(api))),
                ("gamecontroller.fill", "ゲームプラン", .purple, AnyView(GamePlansView())),
                ("bubble.left.and.bubble.right.fill", "コミュニティ", .blue, AnyView(ForumView().environmentObject(api))),
                ("person.badge.shield.checkmark.fill", "インストラクター", .orange, AnyView(InstructorsView().environmentObject(api))),
                ("graduationcap.fill", "指導者システム", .red, AnyView(InstructorSystemsView())),
                ("calendar.badge.clock", "クラス予約", .green, AnyView(ReservationsView().environmentObject(api))),
                ("text.book.closed.fill", "ブログ", .indigo, AnyView(BlogView())),
                ("book.fill", "ガイド", .teal, AnyView(GuidesView())),
            ]

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 14) {
                ForEach(0..<items.count, id: \.self) { i in
                    NavigationLink {
                        items[i].3
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(items[i].2.opacity(0.12))
                                    .frame(width: 48, height: 48)
                                Image(systemName: items[i].0)
                                    .font(.title3)
                                    .foregroundStyle(items[i].2)
                            }
                            Text(items[i].1)
                                .font(.caption2.bold())
                                .foregroundStyle(Color.jfTextSecondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Latest News

    private var latestNewsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "最新ニュース", icon: "newspaper.fill", showMore: true)
                .padding(.horizontal, 16)

            VStack(spacing: 10) {
                ForEach(api.news.prefix(6)) { item in
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
}

// MARK: - Featured News Card

struct FeaturedNewsCard: View {
    let item: NewsItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundStyle(.yellow)
                CategoryBadge(text: item.categoryLabel, color: .jfRed)
                Spacer()
                Text(item.relativeDate)
                    .font(.caption2)
                    .foregroundStyle(Color.jfTextTertiary)
            }

            Text(item.displayTitle)
                .font(.subheadline.bold())
                .foregroundStyle(Color.jfTextPrimary)
                .multilineTextAlignment(.leading)
                .lineLimit(3)

            if !item.displaySummary.isEmpty {
                Text(item.displaySummary)
                    .font(.caption)
                    .foregroundStyle(Color.jfTextTertiary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(14)
        .frame(width: 280, alignment: .leading)
        .glassCard()
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
                    if item.is_featured == true {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                    }
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

// MARK: - Home Athlete Card

struct HomeAthleteCard: View {
    let athlete: Athlete

    var body: some View {
        VStack(spacing: 10) {
            AsyncImage(url: URL(string: athlete.avatar_url ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle().fill(Color.jfCardBg)
                    .overlay(
                        Text(String(athlete.displayName.prefix(1)))
                            .font(.title2.bold())
                            .foregroundStyle(Color.jfTextTertiary)
                    )
            }
            .frame(width: 72, height: 72)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient.jfRedGradient,
                        lineWidth: athlete.featured == true ? 2.5 : 0
                    )
                    .padding(-2)
            )

            Text(athlete.displayName)
                .font(.caption.bold())
                .foregroundStyle(Color.jfTextPrimary)
                .lineLimit(1)

            if let dojo = athlete.home_dojo {
                Text(dojo)
                    .font(.caption2)
                    .foregroundStyle(Color.jfTextTertiary)
                    .lineLimit(1)
            }
        }
        .frame(width: 96)
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

                if let slug = item.slug {
                    Link(destination: URL(string: "https://jiuflow-ssr.fly.dev/news/\(slug)")!) {
                        Label("記事全文を読む", systemImage: "safari")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(LinearGradient.jfRedGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.top, 8)
                }
            }
            .padding()
        }
        .background(Color.jfDarkBg)
        .navigationBarTitleDisplayMode(.inline)
    }
}
