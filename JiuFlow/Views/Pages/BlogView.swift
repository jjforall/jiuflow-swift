import SwiftUI

struct BlogView: View {
    var body: some View {
        NavigationStack {
            WebContentView(
                title: "ブログ",
                icon: "text.book.closed.fill",
                description: "柔術に関する記事やコラムを掲載しています",
                webURL: "https://jiuflow-ssr.fly.dev/blog",
                color: .blue
            )
            .navigationTitle("ブログ")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Reusable Web Content View (for pages better viewed on web)

struct WebContentView: View {
    let title: String
    let icon: String
    let description: String
    let webURL: String
    var color: Color = .jfRed

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ZStack {
                    RadialGradient(
                        colors: [color.opacity(0.15), .clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 120
                    )

                    VStack(spacing: 14) {
                        Image(systemName: icon)
                            .font(.system(size: 48))
                            .foregroundStyle(color)

                        Text(title)
                            .font(.title2.bold())
                            .foregroundStyle(Color.jfTextPrimary)

                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(Color.jfTextTertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                }
                .padding(.vertical, 40)

                Link(destination: URL(string: webURL)!) {
                    Label("Webで開く", systemImage: "safari")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(LinearGradient.jfRedGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 16)
            }
        }
        .background(Color.jfDarkBg)
    }
}
