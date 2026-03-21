import SwiftUI

struct PracticeProgressView: View {
    @EnvironmentObject var api: APIService
    @StateObject private var journal = JournalStore()
    @State private var showNewEntry = false

    // MARK: - Computed from real journal data

    private var totalSessions: Int { journal.entries.count }
    private var totalMinutes: Int { journal.entries.reduce(0) { $0 + $1.duration } }
    private var averageRating: Double {
        guard !journal.entries.isEmpty else { return 0 }
        return Double(journal.entries.reduce(0) { $0 + $1.rating }) / Double(journal.entries.count)
    }

    private var streakDays: Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var dates = Set(journal.entries.map { cal.startOfDay(for: $0.date) })
        guard dates.contains(today) || dates.contains(cal.date(byAdding: .day, value: -1, to: today)!) else { return 0 }
        var streak = 0
        var check = dates.contains(today) ? today : cal.date(byAdding: .day, value: -1, to: today)!
        while dates.contains(check) {
            streak += 1
            check = cal.date(byAdding: .day, value: -1, to: check)!
        }
        return streak
    }

    private var thisWeekEntries: [JournalEntry] {
        let cal = Calendar.current
        let startOfWeek = cal.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return journal.entries.filter { $0.date >= startOfWeek }
    }

    private var thisMonthEntries: [JournalEntry] {
        let cal = Calendar.current
        return journal.entries.filter { cal.isDate($0.date, equalTo: Date(), toGranularity: .month) }
    }

    private var lastMonthEntries: [JournalEntry] {
        let cal = Calendar.current
        guard let lastMonth = cal.date(byAdding: .month, value: -1, to: Date()) else { return [] }
        return journal.entries.filter { cal.isDate($0.date, equalTo: lastMonth, toGranularity: .month) }
    }

    private var practiceTypeBreakdown: [(type: String, label: String, count: Int, color: Color)] {
        let types: [(String, String, Color)] = [
            ("gi", "道着", .blue),
            ("nogi", "ノーギ", .orange),
            ("drill", "ドリル", .green),
            ("open_mat", "オープンマット", .purple),
            ("competition", "試合", .yellow),
        ]
        return types.map { t in
            (t.0, t.1, journal.entries.filter { $0.type == t.0 }.count, t.2)
        }.filter { $0.count > 0 }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // Quick record button
                quickRecordButton

                // Main stats
                mainStatsCard

                // Weekly heatmap
                weeklyHeatmap

                // Month comparison
                monthComparison

                // Practice type breakdown
                if !practiceTypeBreakdown.isEmpty {
                    typeBreakdownSection
                }

                // Recent entries
                recentEntriesSection

                // Technique progress
                if api.techniqueRoot != nil {
                    techniqueSection
                }
            }
            .padding(.bottom, 40)
        }
        .background(Color.jfDarkBg)
        .navigationTitle("練習の進捗")
        .navigationBarTitleDisplayMode(.large)
        .task {
            if api.techniqueRoot == nil {
                await api.loadTechniques()
            }
        }
        .sheet(isPresented: $showNewEntry) {
            NavigationStack {
                JournalEntryEditView(store: journal, entry: .new(), isNew: true)
            }
        }
    }

    // MARK: - Quick Record

    private var quickRecordButton: some View {
        Button { showNewEntry = true } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.jfRedGradient)
                        .frame(width: 44, height: 44)
                    Image(systemName: "plus")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("練習を記録する")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.jfTextPrimary)
                    Text(streakDays > 0 ? "\(streakDays)日連続で練習中!" : "今日の練習を記録しよう")
                        .font(.caption)
                        .foregroundStyle(streakDays > 0 ? Color.orange : Color.jfTextTertiary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.jfTextTertiary)
            }
            .padding(14)
            .glassCard()
        }
        .padding(.horizontal, 16)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: showNewEntry)
    }

    // MARK: - Main Stats

    private var mainStatsCard: some View {
        VStack(spacing: 16) {
            // Streak prominent display
            if streakDays > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(.title)
                        .foregroundStyle(.orange)
                    Text("\(streakDays)")
                        .font(.system(size: 48, weight: .black, design: .rounded).monospacedDigit())
                        .foregroundStyle(Color.jfTextPrimary)
                    Text("日連続")
                        .font(.headline)
                        .foregroundStyle(Color.jfTextTertiary)
                }
                .padding(.top, 8)
            }

            // Stats row
            HStack(spacing: 0) {
                statItem(value: "\(totalSessions)", label: "総練習回数", icon: "figure.martial.arts", color: .jfRed)
                divider
                statItem(value: formatHours(totalMinutes), label: "総練習時間", icon: "clock.fill", color: .blue)
                divider
                statItem(value: String(format: "%.1f", averageRating), label: "平均満足度", icon: "star.fill", color: .yellow)
            }
        }
        .padding(16)
        .glassCard()
        .padding(.horizontal, 16)
    }

    private func statItem(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)
            Text(value)
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(Color.jfTextPrimary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.jfTextTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.jfBorder)
            .frame(width: 1, height: 50)
    }

    // MARK: - Weekly Heatmap

    private var weeklyHeatmap: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                SectionHeader(title: "今週", icon: "calendar")
                Spacer()
                Text("\(thisWeekEntries.count)回 / \(formatHours(thisWeekEntries.reduce(0) { $0 + $1.duration }))")
                    .font(.caption.bold().monospacedDigit())
                    .foregroundStyle(Color.jfTextTertiary)
            }
            .padding(.horizontal, 16)

            HStack(spacing: 6) {
                ForEach(weekDayDates(), id: \.date) { dayInfo in
                    let entries = entriesForDate(dayInfo.date)
                    let minutes = entries.reduce(0) { $0 + $1.duration }
                    let isToday = Calendar.current.isDateInToday(dayInfo.date)

                    VStack(spacing: 6) {
                        // Activity bar
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.jfBorder)
                                .frame(height: 60)

                            if minutes > 0 {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(activityColor(minutes))
                                    .frame(height: max(8, CGFloat(minutes) / 120.0 * 60.0))
                            }
                        }

                        // Minutes label
                        if minutes > 0 {
                            Text("\(minutes)m")
                                .font(.system(size: 9, weight: .bold).monospacedDigit())
                                .foregroundStyle(Color.jfTextSecondary)
                        } else {
                            Text("-")
                                .font(.system(size: 9))
                                .foregroundStyle(Color.jfTextTertiary.opacity(0.3))
                        }

                        // Day label
                        Text(dayInfo.label)
                            .font(.caption2.weight(isToday ? .bold : .regular))
                            .foregroundStyle(isToday ? Color.jfRed : Color.jfTextTertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(14)
            .glassCard()
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Month Comparison

    private var monthComparison: some View {
        let thisCount = thisMonthEntries.count
        let lastCount = lastMonthEntries.count
        let thisMinutes = thisMonthEntries.reduce(0) { $0 + $1.duration }
        let lastMinutes = lastMonthEntries.reduce(0) { $0 + $1.duration }
        let countDiff = thisCount - lastCount
        let minutesDiff = thisMinutes - lastMinutes

        return VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "今月 vs 先月", icon: "chart.line.uptrend.xyaxis")
                .padding(.horizontal, 16)

            HStack(spacing: 12) {
                comparisonCard(
                    title: "練習回数",
                    thisValue: "\(thisCount)回",
                    diff: countDiff,
                    diffLabel: countDiff >= 0 ? "+\(countDiff)" : "\(countDiff)"
                )
                comparisonCard(
                    title: "練習時間",
                    thisValue: formatHours(thisMinutes),
                    diff: minutesDiff,
                    diffLabel: minutesDiff >= 0 ? "+\(formatHours(minutesDiff))" : "-\(formatHours(abs(minutesDiff)))"
                )
            }
            .padding(.horizontal, 16)
        }
    }

    private func comparisonCard(title: String, thisValue: String, diff: Int, diffLabel: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Color.jfTextTertiary)
            Text(thisValue)
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(Color.jfTextPrimary)
            HStack(spacing: 4) {
                Image(systemName: diff >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption2)
                Text(diffLabel)
                    .font(.caption2.bold().monospacedDigit())
            }
            .foregroundStyle(diff >= 0 ? .green : .orange)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .glassCard()
    }

    // MARK: - Type Breakdown

    private var typeBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "練習タイプ内訳", icon: "chart.pie.fill")
                .padding(.horizontal, 16)

            VStack(spacing: 8) {
                ForEach(practiceTypeBreakdown, id: \.type) { item in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(item.color)
                            .frame(width: 10, height: 10)
                        Text(item.label)
                            .font(.subheadline)
                            .foregroundStyle(Color.jfTextPrimary)
                        Spacer()
                        Text("\(item.count)回")
                            .font(.subheadline.bold().monospacedDigit())
                            .foregroundStyle(Color.jfTextSecondary)

                        // Bar
                        GeometryReader { geo in
                            let pct = totalSessions > 0 ? CGFloat(item.count) / CGFloat(totalSessions) : 0
                            RoundedRectangle(cornerRadius: 3)
                                .fill(item.color.opacity(0.3))
                                .frame(width: geo.size.width * pct, height: 6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(width: 60, height: 6)
                    }
                }
            }
            .padding(14)
            .glassCard()
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Recent Entries

    private var recentEntriesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                SectionHeader(title: "最近の練習", icon: "clock.arrow.circlepath")
                Spacer()
                NavigationLink {
                    PracticeJournalView()
                } label: {
                    HStack(spacing: 4) {
                        Text("すべて見る")
                            .font(.caption.bold())
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                    }
                    .foregroundStyle(Color.jfTextTertiary)
                }
            }
            .padding(.horizontal, 16)

            if journal.entries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.jfTextTertiary)
                    Text("まだ練習記録がありません")
                        .font(.subheadline)
                        .foregroundStyle(Color.jfTextTertiary)
                    Text("上の「練習を記録する」から始めましょう")
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .glassCard()
                .padding(.horizontal, 16)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(journal.entries.prefix(5)) { entry in
                        NavigationLink {
                            JournalEntryEditView(store: journal, entry: entry)
                        } label: {
                            JournalEntryRow(entry: entry)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Technique Section (compact)

    private var techniqueSection: some View {
        let categories = api.techniqueRoot?.children ?? []

        return VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "テクニック", icon: "figure.martial.arts")
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(categories) { cat in
                        VStack(spacing: 8) {
                            Text(cat.emoji ?? "")
                                .font(.title2)
                            Text(cat.label ?? "")
                                .font(.caption2.bold())
                                .foregroundStyle(Color.jfTextPrimary)
                                .lineLimit(1)
                            Text("\(cat.children?.count ?? 0)項目")
                                .font(.caption2)
                                .foregroundStyle(Color.jfTextTertiary)
                        }
                        .frame(width: 80)
                        .padding(.vertical, 12)
                        .glassCard(cornerRadius: 14)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Helpers

    private func formatHours(_ minutes: Int) -> String {
        if minutes < 60 { return "\(minutes)m" }
        let h = minutes / 60
        let m = minutes % 60
        return m > 0 ? "\(h)h\(m)m" : "\(h)h"
    }

    private struct WeekDayInfo: Hashable {
        let date: Date
        let label: String
    }

    private func weekDayDates() -> [WeekDayInfo] {
        let cal = Calendar.current
        guard let weekInterval = cal.dateInterval(of: .weekOfYear, for: Date()) else { return [] }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "E"
        return (0..<7).compactMap { offset in
            guard let date = cal.date(byAdding: .day, value: offset, to: weekInterval.start) else { return nil }
            return WeekDayInfo(date: date, label: formatter.string(from: date))
        }
    }

    private func entriesForDate(_ date: Date) -> [JournalEntry] {
        let cal = Calendar.current
        return journal.entries.filter { cal.isDate($0.date, inSameDayAs: date) }
    }

    private func activityColor(_ minutes: Int) -> Color {
        if minutes >= 90 { return .jfRed }
        if minutes >= 60 { return .jfRed.opacity(0.7) }
        return .jfRed.opacity(0.4)
    }
}

// MARK: - Stat Card (reusable)

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    var color: Color = .jfRed

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold().monospacedDigit())
                .foregroundStyle(Color.jfTextPrimary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.jfTextTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .glassCard()
    }
}
