import SwiftUI

/// Home dashboard — "今日何する？"
struct HomeDashboardTab: View {
    @EnvironmentObject var api: APIService
    @EnvironmentObject var premium: PremiumManager
    @EnvironmentObject var langMgr: LanguageManager
    @StateObject private var journalStore = JournalStore()
    @StateObject private var rollStore = RollStore()
    @AppStorage("roadmap_progress") private var progressData: Data = Data()
    @AppStorage("weekly_goal") private var weeklyGoal: Int = 3

    private var streak: Int {
        let cal = Calendar.current
        let days = Set(journalStore.entries.map { cal.startOfDay(for: $0.date) })
        var s = 0
        var d = cal.startOfDay(for: Date())
        while days.contains(d) { s += 1; d = cal.date(byAdding: .day, value: -1, to: d)! }
        return s
    }

    private var thisWeekCount: Int {
        let cal = Calendar.current
        let start = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        return journalStore.entries.filter { $0.date >= start }.count
    }

    private var doneCount: Int {
        let progress = (try? JSONDecoder().decode([String: String].self, from: progressData)) ?? [:]
        return progress.values.filter { $0 == "done" }.count
    }

    private var todayPracticed: Bool {
        let cal = Calendar.current
        return journalStore.entries.contains { cal.isDateInToday($0.date) }
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    greetingCard
                    todayCard
                    quickActions

                    // AI Game Plan Recommendation
                    GamePlanRecommendView()
                        .environmentObject(langMgr)
                        .padding(.horizontal, 16)

                    // Recommended tutorial video
                    if let video = api.videos.first(where: { $0.video_type == "tutorial" }) {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "おすすめ動画", icon: "play.rectangle.fill")
                            NavigationLink {
                                VideoDetailView(video: video, baseURL: api.baseURL)
                            } label: {
                                VideoFeedCard(video: video, baseURL: api.baseURL)
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // Recent practice
                    if !journalStore.entries.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "最近の練習", icon: "clock")
                                .padding(.horizontal, 16)
                            ForEach(journalStore.entries.prefix(3)) { entry in
                                NavigationLink {
                                    JournalEntryEditView(store: journalStore, entry: entry)
                                } label: {
                                    JournalEntryRow(entry: entry)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
            .background(Color.jfDarkBg)
            .navigationTitle("JiuFlow")
            .navigationBarTitleDisplayMode(.large)
            .task {
                if api.videos.isEmpty { await api.loadVideos() }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            FeedbackButton(page: "ホーム")
        }
    }

    // MARK: - Greeting
    private var greetingCard: some View {
        let hour = Calendar.current.component(.hour, from: Date())
        let greeting = hour < 12 ? "おはようございます" : hour < 18 ? "こんにちは" : "こんばんは"
        return HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting).font(.title3.bold()).foregroundStyle(Color.jfTextPrimary)
                Text(todayPracticed ? "今日も練習お疲れ様！" : "最短で強くなろう")
                    .font(.caption).foregroundStyle(Color.jfTextTertiary)
            }
            Spacer()
            VStack(spacing: 2) {
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill").font(.body)
                        .foregroundStyle(streak > 0 ? .orange : Color.jfTextTertiary.opacity(0.3))
                    Text("\(streak)").font(.title3.bold().monospacedDigit())
                        .foregroundStyle(streak > 0 ? .orange : Color.jfTextTertiary)
                }
                Text("連続日").font(.system(size: 9)).foregroundStyle(Color.jfTextTertiary)
            }
        }
        .padding(14).glassCard().padding(.horizontal, 16)
    }

    // MARK: - Today
    private var todayCard: some View {
        HStack(spacing: 0) {
            VStack(spacing: 6) {
                HStack(spacing: 3) {
                    ForEach(0..<weeklyGoal, id: \.self) { i in
                        Circle().fill(i < thisWeekCount ? Color.green : Color.jfBorder)
                            .frame(width: 12, height: 12)
                    }
                }
                Text("今週 \(thisWeekCount)/\(weeklyGoal)").font(.caption2).foregroundStyle(Color.jfTextTertiary)
            }.frame(maxWidth: .infinity)
            Rectangle().fill(Color.jfBorder).frame(width: 1, height: 36)
            VStack(spacing: 4) {
                Text("\(doneCount)").font(.title3.bold().monospacedDigit()).foregroundStyle(Color.jfRed)
                Text("習得テクニック").font(.caption2).foregroundStyle(Color.jfTextTertiary)
            }.frame(maxWidth: .infinity)
            Rectangle().fill(Color.jfBorder).frame(width: 1, height: 36)
            VStack(spacing: 4) {
                Text("\(rollStore.entries.count)").font(.title3.bold().monospacedDigit()).foregroundStyle(.blue)
                Text("ロール数").font(.caption2).foregroundStyle(Color.jfTextTertiary)
            }.frame(maxWidth: .infinity)
        }
        .padding(12).glassCard().padding(.horizontal, 16)
    }

    // MARK: - Quick Actions
    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("クイックアクセス").font(.caption.bold()).foregroundStyle(Color.jfTextTertiary)
                .padding(.horizontal, 4)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                NavigationLink { FlowTab() } label: { actionBtn("フロー", "arrow.triangle.branch", .blue) }
                NavigationLink { GamePlansView() } label: { actionBtn("プラン", "checklist", .purple) }
                NavigationLink { AIRyozoView() } label: { actionBtn("AI良蔵", "brain.head.profile", .jfRed) }
                NavigationLink { RollTimerView() } label: { actionBtn("タイマー", "timer", .orange) }
            }
        }.padding(.horizontal, 16)
    }

    private func actionBtn(_ label: String, _ icon: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.body).foregroundStyle(color)
            Text(label).font(.caption2.bold()).foregroundStyle(Color.jfTextSecondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 12)
        .background(color.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
