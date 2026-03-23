import SwiftUI

/// Image view with in-memory + disk caching (faster than AsyncImage)
struct CachedAsyncImage: View {
    let url: URL?
    var aspectRatio: CGFloat? = nil

    @State private var image: UIImage?
    @State private var isLoading = true

    private static let cache = NSCache<NSURL, UIImage>()
    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(memoryCapacity: 50_000_000, diskCapacity: 200_000_000)
        config.requestCachePolicy = .returnCacheDataElseLoad
        return URLSession(configuration: config)
    }()

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(aspectRatio, contentMode: .fill)
            } else if isLoading {
                ShimmerView()
            } else {
                Rectangle().fill(Color.jfCardBg)
                    .overlay(
                        Image(systemName: "play.fill")
                            .font(.title3)
                            .foregroundStyle(Color.jfTextTertiary)
                    )
            }
        }
        .task(id: url) { await loadImage() }
    }

    private func loadImage() async {
        guard let url = url else { isLoading = false; return }

        // Check memory cache
        if let cached = Self.cache.object(forKey: url as NSURL) {
            self.image = cached
            isLoading = false
            return
        }

        // Download
        isLoading = true
        do {
            let (data, _) = try await Self.session.data(from: url)
            if let uiImage = UIImage(data: data) {
                Self.cache.setObject(uiImage, forKey: url as NSURL)
                self.image = uiImage
            }
        } catch { }
        isLoading = false
    }
}
