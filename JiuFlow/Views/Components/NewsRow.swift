import SwiftUI

struct NewsRow: View {
    let item: NewsItem

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(item.displayTitle)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.jfTextPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 8) {
                    CategoryBadge(
                        text: item.categoryLabel,
                        color: categoryColor(item.category)
                    )

                    Text(item.relativeDate)
                        .font(.caption2)
                        .foregroundStyle(Color.jfTextTertiary)

                    if item.is_featured == true {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                    }
                }

                if !item.displaySummary.isEmpty {
                    Text(item.displaySummary)
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
    }

    private func categoryColor(_ category: String?) -> Color {
        switch category {
        case "bjj": return .orange
        case "technique": return .blue
        case "site": return .green
        default: return .jfRed
        }
    }
}
