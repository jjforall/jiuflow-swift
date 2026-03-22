import SwiftUI

struct AthletesTab: View {
    @EnvironmentObject var api: APIService
    @State private var searchText = ""
    @State private var isGridMode = true
    @State private var showFeaturedOnly = false

    private var filteredAthletes: [Athlete] {
        var result = api.athletes
        if showFeaturedOnly {
            result = result.filter { $0.featured == true }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result
    }

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if api.isLoading && api.athletes.isEmpty {
                    LazyVGrid(columns: gridColumns, spacing: 12) {
                        ForEach(0..<9, id: \.self) { _ in
                            SkeletonCard(height: 140)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                } else if filteredAthletes.isEmpty {
                    EmptyStateView(
                        icon: "person.slash",
                        title: "選手が見つかりません",
                        message: searchText.isEmpty ? "引っ張って再読み込みしてください" : "検索条件を変更してください"
                    )
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 12) {
                            // Filter bar
                            HStack(spacing: 8) {
                                FilterChip(title: "すべて", isSelected: !showFeaturedOnly) {
                                    showFeaturedOnly = false
                                }
                                FilterChip(title: "注目選手", isSelected: showFeaturedOnly) {
                                    showFeaturedOnly = true
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)

                            if isGridMode {
                                LazyVGrid(columns: gridColumns, spacing: 12) {
                                    ForEach(filteredAthletes) { athlete in
                                        NavigationLink {
                                            AthleteDetailView(athlete: athlete)
                                        } label: {
                                            AthleteGridCard(athlete: athlete)
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            } else {
                                LazyVStack(spacing: 10) {
                                    ForEach(filteredAthletes) { athlete in
                                        NavigationLink {
                                            AthleteDetailView(athlete: athlete)
                                        } label: {
                                            AthleteListCard(athlete: athlete)
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("選手")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "選手を検索")
            .background(Color.jfDarkBg)
            .scrollContentBackground(.hidden)
            .task {
                if api.athletes.isEmpty {
                    await api.loadAthletes()
                }
            }
            .refreshable {
                await api.loadAthletes()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            isGridMode.toggle()
                        }
                    } label: {
                        Image(systemName: isGridMode ? "list.bullet" : "square.grid.2x2")
                            .foregroundStyle(Color.jfTextSecondary)
                    }
                }
            }
        }
    }
}

// MARK: - Athlete Grid Card

struct AthleteGridCard: View {
    let athlete: Athlete

    var body: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: athleteAvatarURL(athlete.avatar_url)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Circle().fill(Color.jfCardBg)
                        .overlay(
                            Text(String(athlete.displayName.prefix(1)))
                                .font(.title.bold())
                                .foregroundStyle(Color.jfTextTertiary)
                        )
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(
                            athlete.featured == true
                                ? AnyShapeStyle(LinearGradient.jfRedGradient)
                                : AnyShapeStyle(Color.jfBorder),
                            lineWidth: athlete.featured == true ? 2.5 : 1
                        )
                        .padding(-2)
                )

                if athlete.featured == true {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                        .padding(4)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                        .offset(x: 4, y: -4)
                }
            }

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
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 6)
        .glassCard()
    }
}

// MARK: - Athlete List Card

struct AthleteListCard: View {
    let athlete: Athlete

    var body: some View {
        HStack(spacing: 14) {
            AsyncImage(url: athleteAvatarURL(athlete.avatar_url)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle().fill(Color.jfCardBg)
                    .overlay(
                        Text(String(athlete.displayName.prefix(1)))
                            .font(.title2.bold())
                            .foregroundStyle(Color.jfTextTertiary)
                    )
            }
            .frame(width: 56, height: 56)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(
                        athlete.featured == true
                            ? AnyShapeStyle(LinearGradient.jfRedGradient)
                            : AnyShapeStyle(Color.jfBorder),
                        lineWidth: athlete.featured == true ? 2 : 0.5
                    )
                    .padding(-1)
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(athlete.displayName)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.jfTextPrimary)

                    if athlete.featured == true {
                        CategoryBadge(text: "注目", color: .orange)
                    }
                }

                if let dojo = athlete.home_dojo {
                    Label(dojo, systemImage: "building.2")
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.jfTextTertiary)
        }
        .padding(12)
        .glassCard(cornerRadius: 14)
    }
}

// MARK: - Athlete Detail View

struct AthleteDetailView: View {
    let athlete: Athlete
    private let baseURL = "https://jiuflow-ssr.fly.dev"

    private var avatarURL: URL? {
        guard let url = athlete.avatar_url else { return nil }
        if url.hasPrefix("http") { return URL(string: url) }
        return URL(string: "\(baseURL)\(url)")
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Hero area
                ZStack {
                    // Background glow
                    RadialGradient(
                        colors: [Color.jfRed.opacity(0.1), .clear],
                        center: .center,
                        startRadius: 30,
                        endRadius: 150
                    )

                    VStack(spacing: 16) {
                        AsyncImage(url: avatarURL) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill()
                            default:
                                Circle().fill(Color.jfCardBg)
                                    .overlay(
                                        Text(String(athlete.displayName.prefix(1)))
                                            .font(.system(size: 48, weight: .bold))
                                            .foregroundStyle(Color.jfTextTertiary)
                                    )
                            }
                        }
                        .frame(width: 140, height: 140)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(LinearGradient.jfRedGradient, lineWidth: 3)
                                .padding(-3)
                        )
                        .shadow(color: .jfRed.opacity(0.2), radius: 20)

                        VStack(spacing: 6) {
                            Text(athlete.displayName)
                                .font(.title.bold())
                                .foregroundStyle(Color.jfTextPrimary)

                            if let nameJa = athlete.name_ja, nameJa != athlete.display_name {
                                Text(nameJa)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.jfTextTertiary)
                            }

                            if athlete.featured == true {
                                CategoryBadge(text: "注目選手", color: .orange)
                                    .padding(.top, 2)
                            }
                        }
                    }
                }
                .padding(.top, 20)

                // Info cards
                VStack(spacing: 12) {
                    if let dojo = athlete.home_dojo {
                        InfoCard(icon: "building.2.fill", label: "所属道場", value: dojo, color: .green)
                    }
                    if let style = athlete.style {
                        InfoCard(icon: "figure.martial.arts", label: "スタイル", value: style, color: .blue)
                    }
                    if let weight = athlete.weight {
                        InfoCard(icon: "scalemass.fill", label: "体重", value: weight, color: .orange)
                    }
                }
                .padding(.horizontal)

                // Bio
                if !athlete.displayBio.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "text.quote")
                                .font(.subheadline)
                                .foregroundStyle(Color.jfRed)
                            Text("プロフィール")
                                .font(.headline)
                                .foregroundStyle(Color.jfTextPrimary)
                        }
                        Text(athlete.displayBio)
                            .font(.subheadline)
                            .foregroundStyle(Color.jfTextSecondary)
                            .lineSpacing(5)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .glassCard()
                    .padding(.horizontal)
                }

                // Lineage (系統図)
                if let lineage = athlete.lineage {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.triangle.branch")
                                .font(.subheadline)
                                .foregroundStyle(.purple)
                            Text("系統図 (Lineage)")
                                .font(.headline)
                                .foregroundStyle(Color.jfTextPrimary)
                        }
                        // Parse lineage chain
                        let parts = lineage.components(separatedBy: " → ")
                        ForEach(Array(parts.enumerated()), id: \.offset) { i, name in
                            HStack(spacing: 8) {
                                if i > 0 {
                                    Image(systemName: "arrow.down")
                                        .font(.caption)
                                        .foregroundStyle(.purple.opacity(0.5))
                                        .frame(width: 20)
                                }
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(i == parts.count - 1 ? Color.jfRed : .purple.opacity(0.3))
                                        .frame(width: 10, height: 10)
                                    Text(name)
                                        .font(i == parts.count - 1 ? .subheadline.bold() : .subheadline)
                                        .foregroundStyle(i == parts.count - 1 ? Color.jfTextPrimary : Color.jfTextSecondary)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .glassCard()
                    .padding(.horizontal)
                }

                // Achievements
                if let achievements = athlete.achievements, !achievements.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "trophy.fill")
                                .font(.subheadline)
                                .foregroundStyle(.yellow)
                            Text("実績")
                                .font(.headline)
                                .foregroundStyle(Color.jfTextPrimary)
                        }
                        ForEach(achievements.components(separatedBy: ", "), id: \.self) { a in
                            HStack(spacing: 6) {
                                Image(systemName: "medal.fill")
                                    .font(.caption)
                                    .foregroundStyle(.yellow)
                                Text(a)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.jfTextSecondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .glassCard()
                    .padding(.horizontal)
                }

                // Titles
                if let titles = athlete.titles, !titles.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "crown.fill")
                                .font(.subheadline)
                                .foregroundStyle(.orange)
                            Text("タイトル")
                                .font(.headline)
                                .foregroundStyle(Color.jfTextPrimary)
                        }
                        Text(titles)
                            .font(.subheadline)
                            .foregroundStyle(Color.jfTextSecondary)
                            .lineSpacing(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .glassCard()
                    .padding(.horizontal)
                }

                // Review
                ReviewView(targetType: "athlete", targetId: athlete.id)
            }
            .padding(.bottom, 40)
        }
        .background(Color.jfDarkBg)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Info Card

struct InfoCard: View {
    let icon: String
    let label: String
    let value: String
    var color: Color = .jfRed

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(Color.jfTextTertiary)
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.jfTextPrimary)
            }

            Spacer()
        }
        .padding(14)
        .glassCard()
    }
}

// MARK: - Helper

func athleteAvatarURL(_ url: String?) -> URL? {
    guard let url = url, !url.isEmpty else { return nil }
    if url.hasPrefix("http") { return URL(string: url) }
    return URL(string: "https://jiuflow-ssr.fly.dev\(url)")
}
