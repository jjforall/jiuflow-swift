import SwiftUI
import WebKit

/// Inline video player for Cloudflare Stream videos
/// Plays directly in the app without opening Safari
struct InlineVideoPlayer: View {
    let videoURL: String
    var autoplay: Bool = false
    @State private var isLoading = true

    var body: some View {
        ZStack {
            CloudflareStreamWebView(
                url: videoURL,
                autoplay: autoplay,
                isLoading: $isLoading
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if isLoading {
                ZStack {
                    Color.black.opacity(0.6)
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.white)
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .aspectRatio(16/9, contentMode: .fit)
    }
}

struct CloudflareStreamWebView: UIViewRepresentable {
    let url: String
    var autoplay: Bool = false
    @Binding var isLoading: Bool

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = autoplay ? [] : [.all]

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // Only load once
        guard webView.url == nil else { return }

        let embedURL: String
        if url.contains("iframe.cloudflarestream.com") {
            // Already an iframe URL - extract the video ID
            let videoId = url.components(separatedBy: "/").last ?? url
            embedURL = "https://iframe.cloudflarestream.com/\(videoId)?autoplay=\(autoplay)&muted=false&preload=auto&poster=https://customer-ni5q0m8ct8hv1tz1.cloudflarestream.com/\(videoId)/thumbnails/thumbnail.jpg"
        } else if url.contains("modal.run") || url.hasPrefix("http") {
            // Direct video URL (dubbed version)
            embedURL = url
        } else {
            embedURL = url
        }

        let html = """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
        <style>
            * { margin: 0; padding: 0; }
            body { background: #000; overflow: hidden; }
            iframe, video { width: 100%; height: 100%; border: none; }
        </style>
        </head>
        <body>
        \(embedURL.contains("cloudflarestream") ?
            "<iframe src=\"\(embedURL)\" allow=\"accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture\" allowfullscreen></iframe>" :
            "<video src=\"\(embedURL)\" controls playsinline \(autoplay ? "autoplay" : "")></video>"
        )
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: URL(string: "https://jiuflow.art"))
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: CloudflareStreamWebView
        init(parent: CloudflareStreamWebView) { self.parent = parent }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.parent.isLoading = false
            }
        }
    }
}
