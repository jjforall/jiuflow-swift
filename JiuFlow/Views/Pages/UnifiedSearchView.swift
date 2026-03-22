import SwiftUI

struct UnifiedSearchView: View {
    @EnvironmentObject var api: APIService
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    private var filteredVideos: [Video] {
        guard !searchText.isEmpty else { return [] }
        return api.videos.filter {
            $0.displayTitle.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredAthletes: [Athlete] {
        guard !searchText.isEmpty else { return [] }
        return api.athletes.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredDojos: [Dojo] {
        guard !searchText.isEmpty else { return [] }
        return api.dojos.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var hasResults: Bool {
        !filteredVideos.isEmpty || !filteredAthletes.isEmpty || !filteredDojos.isEmpty
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            if searchText.isEmpty {
                emptyPrompt
            } else if !hasResults {
                noResults
            } else {
                VStack(spacing: 20) {
                    // Videos
                    if !filteredVideos.isEmpty {
                        searchSection(title: "動画", icon: "play.rectangle.fill", count: filteredVideos.count) {
                            ForEach(filteredVideos.prefix(5)) { video in
                                VideoSearchRow(video: video)
                            }
                            if filteredVideos.count > 5 {
                                moreButton(count: filteredVideos.count - 5)
                            }
                        }
                    }

                    // Athletes
                    if !filteredAthletes.isEmpty {
                        searchSection(title: "選手", icon: "person.fill", count: filteredAthletes.count) {
                            ForEach(filteredAthletes.prefix(5)) { athlete in
                                NavigationLink {
                                    AthleteDetailView(athlete: athlete)
                                } label: {
                                    AthleteSearchRow(athlete: athlete)
                                }
                            }
                            if filteredAthletes.count > 5 {
                                moreButton(count: filteredAthletes.count - 5)
                            }
                        }
                    }

                    // Dojos
                    if !filteredDojos.isEmpty {
                        searchSection(title: "道場", icon: "building.2.fill", count: filteredDojos.count) {
                            ForEach(filteredDojos.prefix(5)) { dojo in
                                DojoSearchRow(dojo: dojo)
                            }
                            if filteredDojos.count > 5 {
                                moreButton(count: filteredDojos.count - 5)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
        }
        .background(Color.jfDarkBg)
        .scrollContentBackground(.hidden)
        .navigationTitle("検索")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "動画・選手・道場を検索")
        .task {
            if api.videos.isEmpty { await api.loadVideos() }
            if api.athletes.isEmpty { await api.loadAthletes() }
            if api.dojos.isEmpty { await api.loadDojos() }
        }
    }

    // MARK: - Empty / No Results

    private var emptyPrompt: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 80)
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(Color.jfTextTertiary.opacity(0.4))
            Text("検索キーワードを入力してください")
                .font(.subheadline)
                .foregroundStyle(Color.jfTextTertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var noResults: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 80)
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(Color.jfTextTertiary.opacity(0.4))
            Text("「\(searchText)」に一致する結果がありません")
                .font(.subheadline)
                .foregroundStyle(Color.jfTextTertiary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }

    // MARK: - Section

    private func searchSection<Content: View>(title: String, icon: String, count: Int, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.jfRed)
                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(Color.jfTextPrimary)
                Text("\(count)")
                    .font(.caption.bold())
                    .foregroundStyle(Color.jfTextTertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.jfCardBg)
                    .clipShape(Capsule())
                Spacer()
            }

            content()
        }
    }

    private func moreButton(count: Int) -> some View {
        HStack {
            Spacer()
            Text("他 \(count) 件")
                .font(.caption.bold())
                .foregroundStyle(Color.jfRed)
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Video Search Row

private struct VideoSearchRow: View {
    let video: Video
    private let baseURL = "https://jiuflow-ssr.fly.dev"

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: video.fullThumbnailURL(baseURL: baseURL)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.jfCardBg)
                    .overlay(
                        Image(systemName: "play.rectangle.fill")
                            .foregroundStyle(Color.jfTextTertiary)
                    )
            }
            .frame(width: 72, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(video.displayTitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.jfTextPrimary)
                    .lineLimit(2)

                if let author = video.author_name {
                    Text(author)
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(10)
        .glassCard(cornerRadius: 12)
    }
}

// MARK: - Athlete Search Row

private struct AthleteSearchRow: View {
    let athlete: Athlete

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: athleteAvatarURL(athlete.avatar_url)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle().fill(Color.jfCardBg)
                    .overlay(
                        Text(String(athlete.displayName.prefix(1)))
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.jfTextTertiary)
                    )
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(athlete.displayName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.jfTextPrimary)
                    .lineLimit(1)

                if let dojo = athlete.home_dojo {
                    Text(dojo)
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if athlete.featured == true {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundStyle(.yellow)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.jfTextTertiary)
        }
        .padding(10)
        .glassCard(cornerRadius: 12)
    }
}

// MARK: - Dojo Search Row

private struct DojoSearchRow: View {
    let dojo: Dojo

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.green.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: "building.2.fill")
                    .font(.body)
                    .foregroundStyle(.green)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(dojo.displayName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.jfTextPrimary)
                    .lineLimit(1)

                if !dojo.displayLocation.isEmpty {
                    Text(dojo.displayLocation)
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if dojo.is_verified == true {
                Image(systemName: "checkmark.seal.fill")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
        }
        .padding(10)
        .glassCard(cornerRadius: 12)
    }
}
