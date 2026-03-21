import SwiftUI

struct TournamentsView: View {
    @EnvironmentObject var api: APIService
    @State private var searchText = ""

    private var filteredTournaments: [Tournament] {
        if searchText.isEmpty { return api.tournaments }
        return api.tournaments.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText) ||
            ($0.location ?? "").localizedCaseInsensitiveContains(searchText) ||
            ($0.organization ?? "").localizedCaseInsensitiveContains(searchText)
        }
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
                    webFallbackView
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredTournaments) { tournament in
                                TournamentCard(tournament: tournament)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                }
            }
            .background(Color.jfDarkBg)
            .navigationTitle("大会情報")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "大会を検索")
            .task {
                await api.loadTournaments()
            }
        }
    }

    private var webFallbackView: some View {
        VStack(spacing: 20) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 56))
                .foregroundStyle(.yellow)

            Text("大会情報")
                .font(.title2.bold())
                .foregroundStyle(Color.jfTextPrimary)

            Text("最新の大会情報をWebで確認できます")
                .font(.subheadline)
                .foregroundStyle(Color.jfTextTertiary)

            Link(destination: URL(string: "https://jiuflow-ssr.fly.dev/tournaments")!) {
                Label("大会一覧を見る", systemImage: "safari")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(LinearGradient.jfRedGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct TournamentCard: View {
    let tournament: Tournament

    private var levelColor: Color {
        switch tournament.level?.lowercased() {
        case "world": return .yellow
        case "continental": return .orange
        case "national": return .blue
        case "regional": return .green
        default: return .gray
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                if tournament.is_featured == true {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                }
                if let level = tournament.level {
                    CategoryBadge(text: level, color: levelColor)
                }
                if let org = tournament.organization {
                    Text(org)
                        .font(.caption2)
                        .foregroundStyle(Color.jfTextTertiary)
                }
                Spacer()
                if let year = tournament.year {
                    Text("\(year)")
                        .font(.caption.bold().monospacedDigit())
                        .foregroundStyle(Color.jfTextTertiary)
                }
            }

            Text(tournament.displayName)
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
            }

            if let slug = tournament.slug, let year = tournament.year {
                Link(destination: URL(string: "https://jiuflow-ssr.fly.dev/tournaments/\(year)/\(slug)")!) {
                    Label("詳細を見る", systemImage: "arrow.up.right")
                        .font(.caption.bold())
                        .foregroundStyle(Color.jfRed)
                }
            }
        }
        .padding(14)
        .glassCard()
    }
}
