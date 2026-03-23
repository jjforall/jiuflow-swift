import SwiftUI

struct VideosTab: View {
    @EnvironmentObject var api: APIService
    @EnvironmentObject var premium: PremiumManager
    @State private var searchText = ""
    @State private var selectedType: String?
    @State private var isGridMode = false

    /// Only show tutorial videos for now
    private var tutorialVideos: [Video] {
        api.videos.filter { $0.video_type == "tutorial" }
    }

    private var filteredVideos: [Video] {
        var result = tutorialVideos
        if !searchText.isEmpty {
            result = result.filter {
                $0.displayTitle.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            Group {
                if api.isLoading && api.videos.isEmpty {
                    VStack(spacing: 14) {
                        ForEach(0..<4, id: \.self) { _ in
                            SkeletonCard(height: 200)
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
                        VStack(spacing: 0) {
                            // YouTube-style full-width cards (tutorial only)
                            LazyVStack(spacing: 16) {
                                ForEach(Array(filteredVideos.enumerated()), id: \.element.id) { index, video in
                                    if index < 10 || premium.isPremium {
                                        NavigationLink {
                                            VideoDetailView(video: video, baseURL: api.baseURL)
                                        } label: {
                                            VideoFeedCard(video: video, baseURL: api.baseURL)
                                        }
                                    } else {
                                        NavigationLink {
                                            SubscriptionView()
                                        } label: {
                                            ZStack {
                                                VideoFeedCard(video: video, baseURL: api.baseURL)
                                                    .blur(radius: 3)
                                                LockedVideoOverlay()
                                            }
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                        }
                                    }
                                }
                            }
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
        }
        .overlay(alignment: .bottomTrailing) {
            FeedbackButton(page: "動画")
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

// MARK: - Cached Thumbnail

struct CachedThumbnail: View {
    let url: URL?
    var width: CGFloat = 140
    var height: CGFloat = 80

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image.resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width, height: height)
                    .clipped()
            case .failure:
                placeholder
            default:
                ShimmerView()
                    .frame(width: width, height: height)
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var placeholder: some View {
        ZStack {
            Color.jfCardBg
            Image(systemName: "play.fill")
                .font(.body)
                .foregroundStyle(Color.jfTextTertiary)
        }
        .frame(width: width, height: height)
    }
}

// MARK: - Video Feed Card (YouTube-style full width)

struct VideoFeedCard: View {
    let video: Video
    let baseURL: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Full-width thumbnail (16:9 aspect) with caching
            ZStack(alignment: .bottomLeading) {
                CachedAsyncImage(url: video.fullThumbnailURL(baseURL: baseURL), aspectRatio: 16/9)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(16/9, contentMode: .fill)
                    .clipped()

                // Overlay badges
                HStack(spacing: 6) {
                    if let type = video.video_type {
                        Text(videoTypeLabel(type))
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(videoTypeColor(type).opacity(0.85))
                            .clipShape(Capsule())
                    }
                    Spacer()
                    // Play icon
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.5), radius: 8)
                }
                .padding(10)
            }

            // Info row
            HStack(alignment: .top, spacing: 10) {
                // Author avatar placeholder
                ZStack {
                    Circle().fill(Color.jfRed.opacity(0.12))
                    Text("🥋").font(.caption)
                }
                .frame(width: 34, height: 34)

                VStack(alignment: .leading, spacing: 3) {
                    Text(video.displayTitle)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.jfTextPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 6) {
                        if let author = video.author_name {
                            Text(author)
                                .font(.caption)
                                .foregroundStyle(Color.jfTextTertiary)
                        }
                        if let views = video.view_count, views > 0 {
                            Text("・\(views)回再生")
                                .font(.caption)
                                .foregroundStyle(Color.jfTextTertiary)
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .background(Color.jfCardBg.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Video List Card (kept for compatibility)

struct VideoListCard: View {
    let video: Video
    let baseURL: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack(alignment: .bottomTrailing) {
                CachedThumbnail(url: video.fullThumbnailURL(baseURL: baseURL), width: 140, height: 80)
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.9))
                    .shadow(radius: 4)
                    .padding(4)
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
                GeometryReader { geo in
                    CachedThumbnail(url: video.fullThumbnailURL(baseURL: baseURL),
                                   width: geo.size.width, height: 110)
                }
                .frame(height: 110)
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
                            Text(videoTypeLabel(type))
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
    @EnvironmentObject var lang: LanguageManager
    @State private var selectedLang: String = "ja"
    @State private var isPlaying = true
    @State private var masteryLevel: Int = 0
    @State private var showPracticeLog = false
    @StateObject private var journal = JournalStore()

    private var dubbed: DubbedVideoService { .shared }

    private var currentVideoURL: String {
        guard let original = video.video_url else { return "" }
        return dubbed.videoURL(for: original, language: selectedLang)
    }

    private var availableLangs: [String] {
        guard let original = video.video_url else { return ["ja"] }
        return dubbed.availableLanguages(for: original)
    }

    private let langLabels: [String: String] = [
        "ja": "日本語", "en": "English", "pt": "Portugues", "es": "Espanol",
        "ko": "한국어", "zh": "中文", "fr": "Francais", "de": "Deutsch",
        "it": "Italiano", "ru": "Русский", "ar": "العربية", "hi": "हिंदी",
        "th": "ไทย", "id": "Indonesia"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Video player (inline)
                if isPlaying {
                    InlineVideoPlayer(videoURL: currentVideoURL, autoplay: true)
                        .transition(.opacity)
                } else {
                    // Thumbnail with play button
                    Button { withAnimation { isPlaying = true } } label: {
                        ZStack {
                            AsyncImage(url: video.fullThumbnailURL(baseURL: baseURL)) { image in
                                image.resizable().scaledToFit()
                            } placeholder: {
                                ShimmerView().aspectRatio(16/9, contentMode: .fit)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                            // Play overlay
                            ZStack {
                                Circle()
                                    .fill(.black.opacity(0.5))
                                    .frame(width: 72, height: 72)
                                Image(systemName: "play.fill")
                                    .font(.title)
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                }

                // Title & info
                Text(video.displayTitle)
                    .font(.title3.bold())
                    .foregroundStyle(Color.jfTextPrimary)

                HStack(spacing: 12) {
                    if let type = video.video_type {
                        CategoryBadge(text: typeLabel(type), color: videoTypeColor(type))
                    }
                    if let views = video.view_count, views > 0 {
                        Label("\(views)", systemImage: "eye")
                            .font(.caption)
                            .foregroundStyle(Color.jfTextTertiary)
                    }
                }

                // Language switcher
                if availableLangs.count > 1 {
                    langSwitcher
                }

                // Description
                if !video.displayDescription.isEmpty {
                    Text(video.displayDescription)
                        .font(.subheadline)
                        .foregroundStyle(Color.jfTextSecondary)
                        .lineSpacing(4)
                }

                Divider().background(Color.jfBorder)

                // Mastery rating
                MasteryRatingView(
                    techniqueName: video.displayTitle,
                    level: $masteryLevel
                ) {
                    saveMastery()
                }

                // Quick practice log
                Button { showPracticeLog = true } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.body)
                            .foregroundStyle(.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("この技を練習した")
                                .font(.subheadline.bold())
                                .foregroundStyle(Color.jfTextPrimary)
                            Text("練習日記に記録する")
                                .font(.caption)
                                .foregroundStyle(Color.jfTextTertiary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Color.jfTextTertiary)
                    }
                    .padding(12)
                    .glassCard(cornerRadius: 14)
                }

                // Review
                ReviewView(targetType: "video", targetId: video.id)
            }
            .padding()
        }
        .background(Color.jfDarkBg)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            selectedLang = lang.current
            loadMastery()
        }
        .sheet(isPresented: $showPracticeLog) {
            NavigationStack {
                JournalEntryEditView(
                    store: journal,
                    entry: JournalEntry(
                        id: UUID().uuidString,
                        date: Date(),
                        duration: 60,
                        type: "drill",
                        notes: "動画で学習: \(video.displayTitle)",
                        techniques: [video.displayTitle],
                        rating: 3
                    ),
                    isNew: true
                )
            }
        }
    }

    // MARK: - Language Switcher

    private var langSwitcher: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(availableLangs, id: \.self) { code in
                    Button {
                        selectedLang = code
                        if isPlaying { isPlaying = false; DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { isPlaying = true } }
                    } label: {
                        Text(langLabels[code] ?? code)
                            .font(.caption2.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(selectedLang == code ? Color.jfRed : Color.jfCardBg)
                            .foregroundStyle(selectedLang == code ? .white : Color.jfTextSecondary)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func typeLabel(_ type: String) -> String {
        switch type {
        case "tutorial": return "教則"
        case "documentary": return "ドキュメンタリー"
        case "match": return "試合"
        case "short": return "ショート"
        default: return type
        }
    }

    private func saveMastery() {
        UserDefaults.standard.set(masteryLevel, forKey: "mastery_\(video.id)")
    }

    private func loadMastery() {
        masteryLevel = UserDefaults.standard.integer(forKey: "mastery_\(video.id)")
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
    case "documentary": return .teal
    case "short": return .pink
    default: return .gray
    }
}

func videoTypeLabel(_ type: String) -> String {
    switch type.lowercased() {
    case "tutorial": return "教則"
    case "match": return "試合"
    case "highlight": return "ハイライト"
    case "breakdown": return "分析"
    case "seminar": return "セミナー"
    case "documentary": return "ドキュメンタリー"
    case "short": return "ショート"
    default: return type
    }
}
