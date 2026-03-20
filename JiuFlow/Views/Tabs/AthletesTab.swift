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
                        Image(systemName: isGridMode ? "list.bullet" : "square.grid.3x3")
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
                AsyncImage(url: URL(string: athlete.avatar_url ?? "")) { image in
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
                        AsyncImage(url: URL(string: athlete.avatar_url ?? "")) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Circle().fill(Color.jfCardBg)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 56))
                                        .foregroundStyle(Color.jfTextTertiary)
                                )
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
                }
                .padding(.horizontal)

                // Web link
                if let slug = athlete.slug {
                    Link(destination: URL(string: "https://jiuflow-ssr.fly.dev/athletes/\(slug)")!) {
                        Label("詳細をWebで見る", systemImage: "safari")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(LinearGradient.jfRedGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal)
                }
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
