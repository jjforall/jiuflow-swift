import SwiftUI

struct VideosTab: View {
    @EnvironmentObject var api: APIService
    @State private var searchText = ""
    @State private var selectedType: String?
    @State private var isGridMode = false

    private var filteredVideos: [Video] {
        var result = api.videos
        if !searchText.isEmpty {
            result = result.filter {
                $0.displayTitle.localizedCaseInsensitiveContains(searchText)
            }
        }
        if let type = selectedType {
            result = result.filter { $0.video_type == type }
        }
        return result
    }

    private var videoTypes: [String] {
        Array(Set(api.videos.compactMap(\.video_type))).sorted()
    }

    private var tutorialVideos: [Video] {
        api.videos.filter { $0.video_type == "tutorial" }
    }

    private var matchVideos: [Video] {
        api.videos.filter { $0.video_type == "match" }
    }

    var body: some View {
        NavigationStack {
            Group {
                if api.isLoading && api.videos.isEmpty {
                    VStack(spacing: 14) {
                        ForEach(0..<4, id: \.self) { _ in
                            SkeletonCard(height: isGridMode ? 160 : 100)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                } else if filteredVideos.isEmpty {
                    EmptyStateView(
                        icon: "play.slash",
                        title: "動画が見つかりません",
                        message: searchText.isEmpty ? "引っ張って再読み込みしてください" : "検索条件を変更してください"
                    )
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        // Tutorial section (when no filter active)
                        if selectedType == nil && searchText.isEmpty && !tutorialVideos.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "教則動画", icon: "graduationcap.fill", showMore: true) {
                                    selectedType = "tutorial"
                                }
                                .padding(.horizontal, 16)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: 14) {
                                        ForEach(tutorialVideos.prefix(8)) { video in
                                            NavigationLink {
                                                VideoDetailView(video: video, baseURL: api.baseURL)
                                            } label: {
                                                VideoGridCard(video: video, baseURL: api.baseURL)
                                                    .frame(width: 200)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                            .padding(.bottom, 8)
                        }

                        // Match highlights (when no filter active)
                        if selectedType == nil && searchText.isEmpty && !matchVideos.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "試合動画", icon: "trophy.fill", showMore: true) {
                                    selectedType = "match"
                                }
                                .padding(.horizontal, 16)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: 14) {
                                        ForEach(matchVideos.prefix(8)) { video in
                                            NavigationLink {
                                                VideoDetailView(video: video, baseURL: api.baseURL)
                                            } label: {
                                                VideoGridCard(video: video, baseURL: api.baseURL)
                                                    .frame(width: 200)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                            .padding(.bottom, 8)

                            SectionHeader(title: "すべての動画", icon: "play.rectangle.fill")
                                .padding(.horizontal, 16)
                                .padding(.top, 4)
                        }

                        // Filter chips
                        if !videoTypes.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    FilterChip(title: "すべて", isSelected: selectedType == nil) {
                                        selectedType = nil
                                    }
                                    ForEach(videoTypes, id: \.self) { type in
                                        FilterChip(title: type, isSelected: selectedType == type) {
                                            selectedType = type
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                            }
                        }

                        if isGridMode {
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ], spacing: 14) {
                                ForEach(filteredVideos) { video in
                                    NavigationLink {
                                        VideoDetailView(video: video, baseURL: api.baseURL)
                                    } label: {
                                        VideoGridCard(video: video, baseURL: api.baseURL)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 20)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredVideos) { video in
                                    NavigationLink {
                                        VideoDetailView(video: video, baseURL: api.baseURL)
                                    } label: {
                                        VideoListCard(video: video, baseURL: api.baseURL)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationTitle("動画")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "動画を検索")
            .background(Color.jfDarkBg)
            .scrollContentBackground(.hidden)
            .task {
                if api.videos.isEmpty {
                    await api.loadVideos()
                }
            }
            .refreshable {
                await api.loadVideos()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
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
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.bold())
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Color.jfRed : Color.jfCardBg)
                .foregroundStyle(isSelected ? .white : .jfTextSecondary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color.jfBorder, lineWidth: 1)
                )
        }
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

// MARK: - Video List Card

struct VideoListCard: View {
    let video: Video
    let baseURL: String

    var body: some View {
        HStack(spacing: 14) {
            // Thumbnail
            ZStack(alignment: .bottomTrailing) {
                AsyncImage(url: video.fullThumbnailURL(baseURL: baseURL)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    ShimmerView()
                        .overlay(
                            Image(systemName: "play.fill")
                                .font(.title3)
                                .foregroundStyle(Color.jfTextTertiary)
                        )
                }
                .frame(width: 140, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                // Play button overlay
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.9))
                    .shadow(radius: 4)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(video.displayTitle)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.jfTextPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 8) {
                    if let type = video.video_type {
                        CategoryBadge(text: type, color: videoTypeColor(type))
                    }
                    if let views = video.view_count, views > 0 {
                        Label("\(views)", systemImage: "eye")
                            .font(.caption2)
                            .foregroundStyle(Color.jfTextTertiary)
                    }
                }

                if let author = video.author_name {
                    Text(author)
                        .font(.caption2)
                        .foregroundStyle(Color.jfTextTertiary)
                }
            }
        }
        .padding(10)
        .glassCard(cornerRadius: 14)
    }
}

// MARK: - Video Grid Card

struct VideoGridCard: View {
    let video: Video
    let baseURL: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .center) {
                AsyncImage(url: video.fullThumbnailURL(baseURL: baseURL)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    ShimmerView()
                }
                .frame(height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Image(systemName: "play.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.white.opacity(0.85))
                    .shadow(radius: 6)

                // Type badge
                if let type = video.video_type {
                    VStack {
                        HStack {
                            Spacer()
                            Text(type)
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.black.opacity(0.7))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .foregroundStyle(.white)
                                .padding(6)
                        }
                        Spacer()
                    }
                }
            }

            Text(video.displayTitle)
                .font(.caption.bold())
                .foregroundStyle(Color.jfTextPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            if let views = video.view_count, views > 0 {
                Label("\(views) 回", systemImage: "eye")
                    .font(.caption2)
                    .foregroundStyle(Color.jfTextTertiary)
            }
        }
        .padding(8)
        .glassCard(cornerRadius: 14)
    }
}

// MARK: - Video Detail View

struct VideoDetailView: View {
    let video: Video
    let baseURL: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Thumbnail
                ZStack {
                    AsyncImage(url: video.fullThumbnailURL(baseURL: baseURL)) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        ShimmerView()
                            .aspectRatio(16/9, contentMode: .fit)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.white.opacity(0.8))
                        .shadow(radius: 8)
                }

                Text(video.displayTitle)
                    .font(.title2.bold())
                    .foregroundStyle(Color.jfTextPrimary)

                HStack(spacing: 16) {
                    if let type = video.video_type {
                        CategoryBadge(text: type, color: videoTypeColor(type))
                    }
                    if let views = video.view_count {
                        Label("\(views) 回視聴", systemImage: "eye")
                            .font(.caption)
                            .foregroundStyle(Color.jfTextTertiary)
                    }
                    if let author = video.author_name {
                        Label(author, systemImage: "person")
                            .font(.caption)
                            .foregroundStyle(Color.jfTextTertiary)
                    }
                }

                if !video.displayDescription.isEmpty {
                    Divider().background(Color.jfBorder)

                    Text(video.displayDescription)
                        .font(.body)
                        .foregroundStyle(Color.jfTextSecondary)
                        .lineSpacing(4)
                }

                // Open in browser
                if let urlStr = video.video_url, let url = URL(string: urlStr) {
                    Link(destination: url) {
                        Label("動画を再生", systemImage: "play.fill")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(LinearGradient.jfRedGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
            .padding()
        }
        .background(Color.jfDarkBg)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Helpers

func videoTypeColor(_ type: String) -> Color {
    switch type.lowercased() {
    case "tutorial": return .blue
    case "match": return .red
    case "highlight": return .orange
    case "breakdown": return .purple
    case "seminar": return .green
    default: return .gray
    }
}
