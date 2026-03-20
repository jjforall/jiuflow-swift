import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var api: APIService
    @AppStorage("favoriteVideoIds") private var favoriteVideoData: Data = Data()
    @AppStorage("favoriteAthleteIds") private var favoriteAthleteData: Data = Data()
    @AppStorage("favoriteDojoIds") private var favoriteDojoData: Data = Data()
    @State private var selectedSegment = 0

    private var favoriteVideoIds: Set<String> {
        (try? JSONDecoder().decode(Set<String>.self, from: favoriteVideoData)) ?? []
    }

    private var favoriteAthleteIds: Set<String> {
        (try? JSONDecoder().decode(Set<String>.self, from: favoriteAthleteData)) ?? []
    }

    private var favoriteDojoIds: Set<String> {
        (try? JSONDecoder().decode(Set<String>.self, from: favoriteDojoData)) ?? []
    }

    private var favoriteVideos: [Video] {
        api.videos.filter { favoriteVideoIds.contains($0.id) }
    }

    private var favoriteAthletes: [Athlete] {
        api.athletes.filter { favoriteAthleteIds.contains($0.id) }
    }

    private var favoriteDojos: [Dojo] {
        api.dojos.filter { favoriteDojoIds.contains($0.id) }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("カテゴリ", selection: $selectedSegment) {
                Text("動画").tag(0)
                Text("選手").tag(1)
                Text("道場").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            Group {
                switch selectedSegment {
                case 0: videosSection
                case 1: athletesSection
                case 2: dojosSection
                default: EmptyView()
                }
            }
        }
        .background(Color.jfDarkBg)
        .navigationTitle("お気に入り")
        .navigationBarTitleDisplayMode(.large)
        .task {
            async let v: () = api.loadVideos()
            async let a: () = api.loadAthletes()
            async let d: () = api.loadDojos()
            _ = await (v, a, d)
        }
    }

    // MARK: - Videos

    @ViewBuilder
    private var videosSection: some View {
        if favoriteVideos.isEmpty {
            EmptyStateView(
                icon: "heart.slash",
                title: "お気に入り動画がありません",
                message: "動画の詳細ページからハートボタンでお気に入りに追加できます"
            )
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    ForEach(favoriteVideos) { video in
                        NavigationLink {
                            VideoDetailView(video: video, baseURL: api.baseURL)
                        } label: {
                            VideoListCard(video: video, baseURL: api.baseURL)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Athletes

    @ViewBuilder
    private var athletesSection: some View {
        if favoriteAthletes.isEmpty {
            EmptyStateView(
                icon: "heart.slash",
                title: "お気に入り選手がいません",
                message: "選手の詳細ページからお気に入りに追加できます"
            )
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 10) {
                    ForEach(favoriteAthletes) { athlete in
                        NavigationLink {
                            AthleteDetailView(athlete: athlete)
                        } label: {
                            AthleteListCard(athlete: athlete)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Dojos

    @ViewBuilder
    private var dojosSection: some View {
        if favoriteDojos.isEmpty {
            EmptyStateView(
                icon: "heart.slash",
                title: "お気に入り道場がありません",
                message: "道場の詳細ページからお気に入りに追加できます"
            )
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 10) {
                    ForEach(favoriteDojos) { dojo in
                        NavigationLink {
                            DojoDetailView(dojo: dojo)
                        } label: {
                            DojoCard(dojo: dojo)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
    }
}
