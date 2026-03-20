import SwiftUI

struct PracticeProgressView: View {
    @EnvironmentObject var api: APIService
    @AppStorage("completedTechniques") private var completedData: Data = Data()

    private var completedIds: Set<String> {
        (try? JSONDecoder().decode(Set<String>.self, from: completedData)) ?? []
    }

    private var allTechniques: [TechniqueNode] {
        guard let root = api.techniqueRoot else { return [] }
        return flattenTechniques(root)
    }

    private var progressPercent: Int {
        guard !allTechniques.isEmpty else { return 0 }
        return Int(Double(completedIds.count) / Double(allTechniques.count) * 100)
    }

    private var categories: [TechniqueNode] {
        api.techniqueRoot?.children ?? []
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                // Overall progress ring
                overallProgress

                // Category breakdown
                if !categories.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeader(title: "カテゴリ別", icon: "folder.fill")

                        ForEach(categories) { category in
                            categoryProgressRow(category)
                        }
                    }
                    .padding(.horizontal, 16)
                }

                // Stats grid
                statsGrid

                // Weekly activity (placeholder with local data)
                weeklyActivity
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
    }

    // MARK: - Overall Progress

    private var overallProgress: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.jfBorder, lineWidth: 8)
                    .frame(width: 140, height: 140)

                Circle()
                    .trim(from: 0, to: Double(progressPercent) / 100.0)
                    .stroke(
                        LinearGradient.jfRedGradient,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
                    Text("\(progressPercent)%")
                        .font(.system(size: 36, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(Color.jfTextPrimary)
                    Text("習得率")
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                }
            }
            .padding(.top, 20)

            HStack(spacing: 24) {
                VStack(spacing: 2) {
                    Text("\(completedIds.count)")
                        .font(.title2.bold().monospacedDigit())
                        .foregroundStyle(Color.jfRed)
                    Text("習得済み")
                        .font(.caption2)
                        .foregroundStyle(Color.jfTextTertiary)
                }
                VStack(spacing: 2) {
                    Text("\(allTechniques.count)")
                        .font(.title2.bold().monospacedDigit())
                        .foregroundStyle(Color.jfTextPrimary)
                    Text("全テクニック")
                        .font(.caption2)
                        .foregroundStyle(Color.jfTextTertiary)
                }
            }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .glassCard()
        .padding(.horizontal, 16)
    }

    // MARK: - Category Progress

    private func categoryProgressRow(_ category: TechniqueNode) -> some View {
        let children = flattenTechniques(category)
        let done = children.filter { completedIds.contains($0.id) }.count
        let total = max(children.count, 1)
        let pct = Double(done) / Double(total)

        return HStack(spacing: 12) {
            Text(category.emoji ?? "")
                .font(.title3)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(category.label ?? "")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.jfTextPrimary)
                    Spacer()
                    Text("\(done)/\(children.count)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Color.jfTextTertiary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.jfBorder)
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient.jfRedGradient)
                            .frame(width: geo.size.width * pct, height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(12)
        .glassCard(cornerRadius: 14)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "統計", icon: "chart.bar.fill")
                .padding(.horizontal, 16)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                StatCard(icon: "flame.fill", value: "\(streakDays)", label: "連続日数", color: .orange)
                StatCard(icon: "calendar", value: "\(totalSessions)", label: "総練習回数", color: .blue)
                StatCard(icon: "clock.fill", value: "\(totalHours)h", label: "総練習時間", color: .purple)
                StatCard(icon: "trophy.fill", value: "\(completedIds.count)", label: "習得テクニック", color: .yellow)
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Weekly Activity

    private var weeklyActivity: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "今週のアクティビティ", icon: "calendar.badge.clock")
                .padding(.horizontal, 16)

            HStack(spacing: 6) {
                ForEach(weekDays, id: \.self) { day in
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(activityForDay(day) > 0 ? Color.jfRed.opacity(Double(activityForDay(day)) / 3.0) : Color.jfBorder)
                            .frame(height: 40)
                        Text(day)
                            .font(.caption2)
                            .foregroundStyle(Color.jfTextTertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(14)
            .glassCard()
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Helpers

    private var streakDays: Int {
        UserDefaults.standard.integer(forKey: "streak_days")
    }

    private var totalSessions: Int {
        UserDefaults.standard.integer(forKey: "total_sessions")
    }

    private var totalHours: Int {
        UserDefaults.standard.integer(forKey: "total_hours")
    }

    private var weekDays: [String] {
        ["月", "火", "水", "木", "金", "土", "日"]
    }

    private func activityForDay(_ day: String) -> Int {
        // Placeholder - returns from local storage
        let key = "activity_\(day)"
        return UserDefaults.standard.integer(forKey: key)
    }

    private func flattenTechniques(_ node: TechniqueNode) -> [TechniqueNode] {
        var result = [node]
        if let children = node.children {
            for child in children {
                result.append(contentsOf: flattenTechniques(child))
            }
        }
        return result
    }
}

// MARK: - Stat Card

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
