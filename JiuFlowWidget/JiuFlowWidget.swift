import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), data: WidgetData(streak: 5, thisWeekCount: 2, weeklyGoal: 3))
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(SimpleEntry(date: Date(), data: WidgetData.placeholder()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        Task {
            let data = await WidgetData.fetch()
            let entry = SimpleEntry(date: Date(), data: data)
            let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }
}

// MARK: - Entry

struct SimpleEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

// MARK: - Widget View

struct JiuFlowWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    private let bgColor = Color(red: 0.039, green: 0.039, blue: 0.039)
    private let accentColor = Color(red: 0.914, green: 0.271, blue: 0.376)

    var body: some View {
        switch family {
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }

    // MARK: Small: streak + weekly progress

    var smallView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Text("🔥")
                    .font(.title2)
                Text("\(entry.data.streak)")
                    .font(.system(size: 34, weight: .black))
                    .foregroundColor(.white)
            }
            Text(entry.data.streak == 1 ? "日連続" : "日連続")
                .font(.caption)
                .foregroundColor(.gray)

            ProgressView(
                value: Double(min(entry.data.thisWeekCount, entry.data.weeklyGoal)),
                total: Double(max(entry.data.weeklyGoal, 1))
            )
            .tint(accentColor)
            .scaleEffect(y: 1.5)

            Text("\(entry.data.thisWeekCount)/\(entry.data.weeklyGoal)回")
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding()
        .containerBackground(bgColor, for: .widget)
    }

    // MARK: Medium: streak + next tournament

    var mediumView: some View {
        HStack(spacing: 0) {
            // Left: streak + progress
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Text("🔥")
                        .font(.title2)
                    Text("\(entry.data.streak)")
                        .font(.system(size: 34, weight: .black))
                        .foregroundColor(.white)
                }
                Text("日連続")
                    .font(.caption)
                    .foregroundColor(.gray)

                ProgressView(
                    value: Double(min(entry.data.thisWeekCount, entry.data.weeklyGoal)),
                    total: Double(max(entry.data.weeklyGoal, 1))
                )
                .tint(accentColor)
                .scaleEffect(y: 1.5)

                Text("\(entry.data.thisWeekCount)/\(entry.data.weeklyGoal)回")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)

            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 1)
                .padding(.vertical, 12)

            // Right: next tournament
            VStack(alignment: .leading, spacing: 6) {
                Label("次回大会", systemImage: "trophy.fill")
                    .font(.caption)
                    .foregroundColor(.gray)

                Text(entry.data.nextTournamentName ?? "未定")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if let dateStr = entry.data.nextTournamentDate, !dateStr.isEmpty {
                    Text(dateStr)
                        .font(.caption2)
                        .foregroundColor(accentColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .containerBackground(bgColor, for: .widget)
    }
}

// MARK: - Widget Configuration

@main
struct JiuFlowWidget: Widget {
    let kind = "JiuFlowWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            JiuFlowWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("JiuFlow")
        .description("練習ストリークと次回大会を表示")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    JiuFlowWidget()
} timeline: {
    SimpleEntry(date: .now, data: WidgetData(streak: 7, thisWeekCount: 2, weeklyGoal: 3))
}

#Preview(as: .systemMedium) {
    JiuFlowWidget()
} timeline: {
    SimpleEntry(
        date: .now,
        data: WidgetData(
            streak: 7,
            thisWeekCount: 2,
            weeklyGoal: 3,
            nextTournamentName: "SJJJF東京オープン",
            nextTournamentDate: "2026-05-15"
        )
    )
}
