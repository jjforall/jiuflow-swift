import SwiftUI

// MARK: - Technique Stat Pill

struct TechniqueStatPill: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.jfRed)
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(Color.jfTextPrimary)
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.jfTextTertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .glassCard(cornerRadius: 20)
    }
}

// MARK: - Technique Category Card

struct TechniqueCategoryCard: View {
    let category: TechniqueNode
    let isExpanded: Bool
    var videos: [Video] = []
    let onTap: () -> Void

    private var childCount: Int {
        category.children?.count ?? 0
    }

    private var progressValue: Double {
        guard let prob = category.prob else { return 0 }
        return Double(prob) / 100.0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .stroke(Color.jfBorder, lineWidth: 3)
                            .frame(width: 48, height: 48)
                        if category.prob != nil {
                            Circle()
                                .trim(from: 0, to: progressValue)
                                .stroke(
                                    LinearGradient.jfRedGradient,
                                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                                )
                                .frame(width: 48, height: 48)
                                .rotationEffect(.degrees(-90))
                        }
                        Text(category.emoji ?? "")
                            .font(.title3)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(category.label ?? "")
                            .font(.headline)
                            .foregroundStyle(Color.jfTextPrimary)
                        HStack(spacing: 8) {
                            if let desc = category.desc {
                                Text(desc)
                                    .font(.caption)
                                    .foregroundStyle(Color.jfTextTertiary)
                                    .lineLimit(1)
                            }
                            if childCount > 0 {
                                Text("\(childCount)項目")
                                    .font(.caption2)
                                    .foregroundStyle(Color.jfTextTertiary)
                            }
                        }
                    }

                    Spacer()

                    if let prob = category.prob {
                        Text("\(prob)%")
                            .font(.caption.bold().monospacedDigit())
                            .foregroundStyle(Color.jfRed)
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(Color.jfTextTertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(14)
            }
            .sensoryFeedback(.impact(flexibility: .soft), trigger: isExpanded)

            if isExpanded, let children = category.children {
                Divider()
                    .background(Color.jfBorder)
                    .padding(.horizontal, 14)

                VStack(spacing: 0) {
                    ForEach(children) { tech in
                        TechniqueRow(technique: tech, videos: videos)
                        if tech.id != children.last?.id {
                            Divider()
                                .background(Color.jfBorder)
                                .padding(.leading, 56)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .glassCard()
    }
}

// MARK: - Technique Row

struct TechniqueRow: View {
    let technique: TechniqueNode
    var videos: [Video] = []
    @State private var showChildren = false

    private var matchingVideos: [Video] {
        guard let label = technique.label, !label.isEmpty else { return [] }
        return videos.filter { video in
            guard let title = video.title else { return false }
            return title.localizedCaseInsensitiveContains(label) ||
                   label.localizedCaseInsensitiveContains(title)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Text(technique.emoji ?? "")
                    .font(.body)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(technique.label ?? "")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.jfTextPrimary)

                        if technique.recommended == true {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundStyle(.yellow)
                        }
                        if technique.warning == true {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                        if !matchingVideos.isEmpty {
                            Image(systemName: "play.rectangle.fill")
                                .font(.caption2)
                                .foregroundStyle(Color.jfRed)
                        }
                    }

                    if let desc = technique.desc {
                        Text(desc)
                            .font(.caption)
                            .foregroundStyle(Color.jfTextTertiary)
                            .lineLimit(2)
                    }

                    if !matchingVideos.isEmpty {
                        ForEach(matchingVideos) { video in
                            if let urlStr = video.video_url, let url = URL(string: urlStr) {
                                Link(destination: url) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "play.fill")
                                            .font(.system(size: 8))
                                        Text(video.displayTitle)
                                            .font(.caption2)
                                            .lineLimit(1)
                                    }
                                    .foregroundStyle(Color.jfRed)
                                }
                            }
                        }
                    }
                }

                Spacer()

                if let prob = technique.prob {
                    Text("\(prob)%")
                        .font(.caption2.bold().monospacedDigit())
                        .foregroundStyle(Color.jfTextTertiary)
                }

                if technique.children != nil && !(technique.children?.isEmpty ?? true) {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            showChildren.toggle()
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(Color.jfTextTertiary)
                            .rotationEffect(.degrees(showChildren ? 90 : 0))
                    }
                }
            }

            if showChildren, let subChildren = technique.children, !subChildren.isEmpty {
                VStack(spacing: 4) {
                    ForEach(subChildren) { sub in
                        HStack(spacing: 8) {
                            Rectangle()
                                .fill(Color.jfBorder)
                                .frame(width: 1, height: 16)
                                .padding(.leading, 20)
                            Text(sub.emoji ?? "")
                                .font(.caption)
                            Text(sub.label ?? "")
                                .font(.caption)
                                .foregroundStyle(Color.jfTextSecondary)
                            Spacer()
                            if let prob = sub.prob {
                                Text("\(prob)%")
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(Color.jfTextTertiary)
                            }
                        }
                    }
                }
                .padding(.leading, 28)
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}
