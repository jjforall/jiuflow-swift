import SwiftUI

struct VideoCard: View {
    let video: Video
    let baseURL: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Thumbnail with overlay
            ZStack(alignment: .center) {
                AsyncImage(url: video.fullThumbnailURL(baseURL: baseURL)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    ShimmerView()
                }
                .frame(width: 220, height: 124)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Play button
                Image(systemName: "play.circle.fill")
                    .font(.title)
                    .foregroundStyle(.white.opacity(0.9))
                    .shadow(radius: 4)

                // Type badge
                VStack {
                    HStack {
                        Spacer()
                        if let type = video.video_type {
                            Text(type)
                                .font(.caption2.bold())
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(.ultraThinMaterial)
                                .environment(\.colorScheme, .dark)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                                .foregroundStyle(.white)
                                .padding(8)
                        }
                    }
                    Spacer()
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(video.displayTitle)
                    .font(.caption.bold())
                    .foregroundStyle(Color.jfTextPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 6) {
                    if let views = video.view_count, views > 0 {
                        Label("\(views)", systemImage: "eye")
                            .font(.caption2)
                            .foregroundStyle(Color.jfTextTertiary)
                    }
                    if let author = video.author_name {
                        Text(author)
                            .font(.caption2)
                            .foregroundStyle(Color.jfTextTertiary)
                    }
                }
            }
            .frame(width: 220, alignment: .leading)
        }
    }
}
