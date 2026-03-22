import SwiftUI

// MARK: - Journal Entry Model

struct JournalEntry: Codable, Identifiable {
    let id: String
    var date: Date
    var duration: Int // minutes
    var type: String // "gi", "nogi", "drill", "open_mat", "competition"
    var notes: String
    var techniques: [String]
    var rating: Int // 1-5
    // New fields (optional for backward compat)
    var intensity: Int? // 1-5 (軽い→全力)
    var sparringRounds: Int? // スパーリング本数
    var injuries: String? // 怪我・痛み
    var dojoName: String? // 道場名
    var mood: String? // "great","good","normal","tired","bad"

    static func new() -> JournalEntry {
        JournalEntry(
            id: UUID().uuidString,
            date: Date(),
            duration: 60,
            type: "gi",
            notes: "",
            techniques: [],
            rating: 3,
            intensity: 3,
            sparringRounds: 0,
            injuries: nil,
            dojoName: nil,
            mood: "good"
        )
    }

    init(id: String, date: Date, duration: Int, type: String, notes: String,
         techniques: [String], rating: Int, intensity: Int? = 3,
         sparringRounds: Int? = 0, injuries: String? = nil,
         dojoName: String? = nil, mood: String? = "good") {
        self.id = id; self.date = date; self.duration = duration
        self.type = type; self.notes = notes; self.techniques = techniques
        self.rating = rating; self.intensity = intensity
        self.sparringRounds = sparringRounds; self.injuries = injuries
        self.dojoName = dojoName; self.mood = mood
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        date = try c.decode(Date.self, forKey: .date)
        duration = try c.decode(Int.self, forKey: .duration)
        type = try c.decode(String.self, forKey: .type)
        notes = try c.decode(String.self, forKey: .notes)
        techniques = try c.decode([String].self, forKey: .techniques)
        rating = try c.decode(Int.self, forKey: .rating)
        intensity = try c.decodeIfPresent(Int.self, forKey: .intensity)
        sparringRounds = try c.decodeIfPresent(Int.self, forKey: .sparringRounds)
        injuries = try c.decodeIfPresent(String.self, forKey: .injuries)
        dojoName = try c.decodeIfPresent(String.self, forKey: .dojoName)
        mood = try c.decodeIfPresent(String.self, forKey: .mood)
    }
}

// MARK: - Journal Storage

@MainActor
class JournalStore: ObservableObject {
    @Published var entries: [JournalEntry] = []

    private let key = "journal_entries"

    init() {
        load()
    }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([JournalEntry].self, from: data) else { return }
        entries = decoded.sorted { $0.date > $1.date }
    }

    func save(_ entry: JournalEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = entry
        } else {
            entries.insert(entry, at: 0)
        }
        persist()
    }

    func delete(_ entry: JournalEntry) {
        entries.removeAll { $0.id == entry.id }
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

// MARK: - Practice Journal View

struct PracticeJournalView: View {
    @StateObject private var store = JournalStore()
    @State private var showNewEntry = false
    @State private var showCompResult = false
    @State private var showVideoNote = false
    @State private var selectedMonth = Date()
    @State private var filterType: String?

    private var entriesThisMonth: [JournalEntry] {
        let cal = Calendar.current
        return store.entries.filter {
            cal.isDate($0.date, equalTo: selectedMonth, toGranularity: .month)
            && (filterType == nil || $0.type == filterType)
        }
    }

    private var totalMinutesThisMonth: Int {
        entriesThisMonth.reduce(0) { $0 + $1.duration }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                // Big CTA - always visible
                Button { showNewEntry = true } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.jfRed.opacity(0.15))
                                .frame(width: 48, height: 48)
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Color.jfRed)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("今日の練習を記録する")
                                .font(.headline)
                                .foregroundStyle(Color.jfTextPrimary)
                            Text("タイプ・時間・メモを残そう")
                                .font(.caption)
                                .foregroundStyle(Color.jfTextTertiary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Color.jfRed.opacity(0.6))
                    }
                    .padding(14)
                    .background(
                        LinearGradient(colors: [Color.jfRed.opacity(0.12), Color.jfRed.opacity(0.04)], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.jfRed.opacity(0.2), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 16)

                // Record type grid - 2 rows
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        quickLogButton("道着", "tshirt.fill", .blue, "gi")
                        quickLogButton("ノーギ", "figure.run", .orange, "nogi")
                        quickLogButton("ドリル", "arrow.triangle.2.circlepath", .green, "drill")
                        quickLogButton("OM", "person.3.fill", .purple, "open_mat")
                    }
                    HStack(spacing: 8) {
                        Button { showCompResult = true } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "trophy.fill").font(.body).foregroundStyle(.yellow)
                                Text("大会結果").font(.caption2.bold()).foregroundStyle(Color.jfTextSecondary)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background(Color.yellow.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        Button { showVideoNote = true } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "lightbulb.fill").font(.body).foregroundStyle(.purple)
                                Text("動画メモ").font(.caption2.bold()).foregroundStyle(Color.jfTextSecondary)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background(Color.purple.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        NavigationLink {
                            RollJournalView()
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "person.2.fill").font(.body).foregroundStyle(.orange)
                                Text("スパー").font(.caption2.bold()).foregroundStyle(Color.jfTextSecondary)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background(Color.orange.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        NavigationLink {
                            WeightTrackerView()
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "scalemass.fill").font(.body).foregroundStyle(.mint)
                                Text("体重").font(.caption2.bold()).foregroundStyle(Color.jfTextSecondary)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background(Color.mint.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(.horizontal, 16)

                // Filter by type
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        filterChip("すべて", nil)
                        filterChip("道着", "gi")
                        filterChip("ノーギ", "nogi")
                        filterChip("ドリル", "drill")
                        filterChip("大会", "competition")
                        filterChip("OM", "open_mat")
                    }
                    .padding(.horizontal, 16)
                }

                // Streak & weekly goal
                streakCard

                // Month summary
                monthSummary

                // Entry list
                if entriesThisMonth.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "figure.martial.arts")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.jfTextTertiary.opacity(0.3))
                        Text("今月はまだ記録がありません")
                            .font(.subheadline)
                            .foregroundStyle(Color.jfTextTertiary)
                        Text("上のボタンから練習を記録しましょう")
                            .font(.caption)
                            .foregroundStyle(Color.jfTextTertiary.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeader(title: "練習記録", icon: "list.bullet.rectangle")
                            .padding(.horizontal, 16)

                        LazyVStack(spacing: 10) {
                            ForEach(entriesThisMonth) { entry in
                                NavigationLink {
                                    JournalEntryEditView(store: store, entry: entry)
                                } label: {
                                    JournalEntryRow(entry: entry)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.bottom, 40)
        }
        .background(Color.jfDarkBg)
        .navigationTitle("練習日記")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showNewEntry = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.jfRed)
                }
            }
        }
        .sheet(isPresented: $showNewEntry) {
            NavigationStack {
                JournalEntryEditView(store: store, entry: quickEntry ?? .new(), isNew: true)
            }
        }
        .onChange(of: showNewEntry) { _, new in
            if !new { quickEntry = nil }
        }
        .sheet(isPresented: $showCompResult) {
            NavigationStack {
                CompResultView(store: store, onDismiss: {})
            }
        }
        .sheet(isPresented: $showVideoNote) {
            NavigationStack {
                VideoNoteView(store: store, onDismiss: {})
            }
        }
    }

    // MARK: - Month Summary

    private func goToPrevMonth() {
        withAnimation(.spring(response: 0.3)) {
            selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
        }
    }

    private func goToNextMonth() {
        withAnimation(.spring(response: 0.3)) {
            selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
        }
    }

    private var monthSummary: some View {
        VStack(spacing: 16) {
            // Month selector with larger tap targets
            HStack {
                Button(action: goToPrevMonth) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundStyle(Color.jfTextSecondary)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }

                Spacer()

                Text(monthString(selectedMonth))
                    .font(.headline)
                    .foregroundStyle(Color.jfTextPrimary)

                Spacer()

                Button(action: goToNextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundStyle(Color.jfTextSecondary)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
            }

            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("\(entriesThisMonth.count)")
                        .font(.title.bold().monospacedDigit())
                        .foregroundStyle(Color.jfRed)
                    Text("回")
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                }

                Rectangle()
                    .fill(Color.jfBorder)
                    .frame(width: 1, height: 36)

                VStack(spacing: 4) {
                    Text("\(totalMinutesThisMonth / 60)h \(totalMinutesThisMonth % 60)m")
                        .font(.title.bold().monospacedDigit())
                        .foregroundStyle(Color.jfTextPrimary)
                    Text("合計時間")
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                }

                Rectangle()
                    .fill(Color.jfBorder)
                    .frame(width: 1, height: 36)

                VStack(spacing: 4) {
                    let avg = entriesThisMonth.isEmpty ? 0 : totalMinutesThisMonth / entriesThisMonth.count
                    Text("\(avg)m")
                        .font(.title.bold().monospacedDigit())
                        .foregroundStyle(Color.jfTextPrimary)
                    Text("平均")
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                }
            }
        }
        .padding(16)
        .glassCard()
        .padding(.horizontal, 16)
        .gesture(
            DragGesture(minimumDistance: 40)
                .onEnded { value in
                    if value.translation.width < -40 {
                        goToNextMonth()
                    } else if value.translation.width > 40 {
                        goToPrevMonth()
                    }
                }
        )
    }

    @AppStorage("weekly_goal") private var weeklyGoal: Int = 3

    private var streak: Int {
        let cal = Calendar.current
        let days = Set(store.entries.map { cal.startOfDay(for: $0.date) })
        var s = 0
        var d = cal.startOfDay(for: Date())
        while days.contains(d) { s += 1; d = cal.date(byAdding: .day, value: -1, to: d)! }
        return s
    }

    private var thisWeekCount: Int {
        let cal = Calendar.current
        let startOfWeek = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        return store.entries.filter { $0.date >= startOfWeek }.count
    }

    private var badges: [(icon: String, label: String, earned: Bool)] {
        let total = store.entries.count
        return [
            ("flame.fill", "初練習", total >= 1),
            ("flame.fill", "10回達成", total >= 10),
            ("flame.fill", "50回達成", total >= 50),
            ("flame.fill", "100回達成", total >= 100),
            ("calendar", "7日連続", streak >= 7),
            ("calendar", "30日連続", streak >= 30),
            ("trophy.fill", "試合デビュー", store.entries.contains { $0.type == "competition" }),
        ]
    }

    private var streakCard: some View {
        VStack(spacing: 12) {
            // Streak + weekly
            HStack(spacing: 0) {
                // Streak
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.title2)
                            .foregroundStyle(streak > 0 ? .orange : Color.jfTextTertiary.opacity(0.3))
                        Text("\(streak)")
                            .font(.system(size: 28, weight: .black).monospacedDigit())
                            .foregroundStyle(streak > 0 ? .orange : Color.jfTextTertiary)
                    }
                    Text("連続日")
                        .font(.caption2)
                        .foregroundStyle(Color.jfTextTertiary)
                }
                .frame(maxWidth: .infinity)

                Rectangle().fill(Color.jfBorder).frame(width: 1, height: 40)

                // Weekly goal
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        ForEach(0..<weeklyGoal, id: \.self) { i in
                            Circle()
                                .fill(i < thisWeekCount ? Color.green : Color.jfBorder)
                                .frame(width: 14, height: 14)
                        }
                    }
                    HStack(spacing: 4) {
                        Text("今週 \(thisWeekCount)/\(weeklyGoal)")
                            .font(.caption2)
                            .foregroundStyle(Color.jfTextTertiary)
                        Button {
                            weeklyGoal = weeklyGoal == 5 ? 2 : weeklyGoal + 1
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .font(.caption2)
                                .foregroundStyle(Color.jfTextTertiary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }

            // Badges
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(badges.enumerated()), id: \.offset) { _, badge in
                        VStack(spacing: 2) {
                            Image(systemName: badge.icon)
                                .font(.caption)
                                .foregroundStyle(badge.earned ? .yellow : Color.jfTextTertiary.opacity(0.2))
                            Text(badge.label)
                                .font(.system(size: 8))
                                .foregroundStyle(badge.earned ? Color.jfTextSecondary : Color.jfTextTertiary.opacity(0.3))
                        }
                        .frame(width: 56)
                        .padding(.vertical, 6)
                        .background(badge.earned ? Color.yellow.opacity(0.06) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }

            // Motivational message
            if streak == 0 {
                Text("今日練習したら連続記録がスタート！")
                    .font(.caption)
                    .foregroundStyle(Color.jfTextTertiary)
            } else if streak >= 7 {
                Text("すごい！\(streak)日連続！この調子で続けよう")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(14)
        .glassCard()
        .padding(.horizontal, 16)
    }

    private func filterChip(_ label: String, _ type: String?) -> some View {
        Button {
            withAnimation { filterType = type }
        } label: {
            Text(label)
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(filterType == type ? Color.jfRed : Color.jfCardBg)
                .foregroundStyle(filterType == type ? .white : Color.jfTextSecondary)
                .clipShape(Capsule())
        }
    }

    @State private var quickEntry: JournalEntry?

    private func quickLogButton(_ label: String, _ icon: String, _ color: Color, _ type: String) -> some View {
        Button {
            var e = JournalEntry.new()
            e.type = type
            quickEntry = e
            showNewEntry = true
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(color)
                Text(label)
                    .font(.caption2.bold())
                    .foregroundStyle(Color.jfTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(color.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func monthString(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy年M月"
        return f.string(from: date)
    }
}

// MARK: - Journal Entry Row

struct JournalEntryRow: View {
    let entry: JournalEntry

    private var dateString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "M/d (E)"
        return f.string(from: entry.date)
    }

    private var typeInfo: (label: String, icon: String, color: Color) {
        switch entry.type {
        case "gi": return ("道着", "tshirt.fill", .blue)
        case "nogi": return ("ノーギ", "figure.run", .orange)
        case "drill": return ("ドリル", "arrow.triangle.2.circlepath", .green)
        case "open_mat": return ("オープンマット", "person.3.fill", .purple)
        case "competition": return ("試合", "trophy.fill", .yellow)
        default: return ("その他", "circle.fill", .gray)
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            // Type icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(typeInfo.color.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: typeInfo.icon)
                    .font(.title3)
                    .foregroundStyle(typeInfo.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(dateString)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.jfTextPrimary)

                    CategoryBadge(text: typeInfo.label, color: typeInfo.color)
                }

                HStack(spacing: 12) {
                    Label("\(entry.duration)分", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)

                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { i in
                            Image(systemName: i <= entry.rating ? "star.fill" : "star")
                                .font(.system(size: 10))
                                .foregroundStyle(i <= entry.rating ? .yellow : Color.jfTextTertiary.opacity(0.3))
                        }
                    }
                }

                // Mood + intensity
                HStack(spacing: 8) {
                    if let mood = entry.mood {
                        Text(moodEmoji(mood))
                            .font(.caption)
                    }
                    if let intensity = entry.intensity, intensity > 0 {
                        HStack(spacing: 1) {
                            ForEach(1...5, id: \.self) { i in
                                Image(systemName: i <= intensity ? "bolt.fill" : "bolt")
                                    .font(.system(size: 7))
                                    .foregroundStyle(i <= intensity ? .orange : Color.jfTextTertiary.opacity(0.2))
                            }
                        }
                    }
                    if let rounds = entry.sparringRounds, rounds > 0 {
                        Text("\(rounds)本")
                            .font(.caption2)
                            .foregroundStyle(Color.jfTextTertiary)
                    }
                }

                if !entry.notes.isEmpty {
                    Text(entry.notes)
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.jfTextTertiary)
        }
        .padding(12)
        .glassCard(cornerRadius: 14)
    }
}

private func moodEmoji(_ mood: String) -> String {
    switch mood {
    case "great": return "😆"
    case "good": return "😊"
    case "normal": return "😐"
    case "tired": return "😴"
    case "bad": return "😞"
    default: return "😊"
    }
}

// MARK: - Journal Entry Edit View

struct JournalEntryEditView: View {
    @ObservedObject var store: JournalStore
    @State var entry: JournalEntry
    var isNew: Bool = false
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory = 0
    @State private var customTechnique = ""

    private let techniqueCategories: [(name: String, icon: String, color: Color, techniques: [String])] = [
        ("ガード", "shield.fill", .blue, [
            "クローズドガード", "ハーフガード", "バタフライガード", "デラヒーバ",
            "スパイダーガード", "ラッソーガード", "Xガード", "50/50",
            "ニーシールド", "ディープハーフ", "SLX", "Zガード"
        ]),
        ("パス", "arrow.right.circle.fill", .green, [
            "ニースライス", "トレアンドウ", "レッグドラッグ", "オーバーアンダー",
            "スタックパス", "ロングステップ", "プレッシャーパス", "ブルファイター"
        ]),
        ("サブミッション", "lock.fill", .red, [
            "三角絞め", "腕十字", "RNC", "ギロチン", "オモプラッタ",
            "ダースチョーク", "クロスチョーク", "キムラ", "アメリカーナ",
            "ヒールフック", "ニーバー", "トーホールド", "ストレートフットロック"
        ]),
        ("テイクダウン", "arrow.down.circle.fill", .orange, [
            "ダブルレッグ", "シングルレッグ", "アームドラッグ", "小外刈り",
            "大外刈り", "内股", "引き込み", "体落とし"
        ]),
        ("スイープ", "arrow.up.circle.fill", .purple, [
            "シザースイープ", "ヒップバンプ", "バタフライスイープ",
            "フラワースイープ", "ペンデュラム", "ウェイタースイープ", "ベリンボロ"
        ]),
        ("エスケープ", "figure.walk", .cyan, [
            "マウントエスケープ", "サイドエスケープ", "バックエスケープ",
            "エビ", "ブリッジ", "ガードリカバリー", "タートルエスケープ"
        ]),
    ]

    private var techniquePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "checklist")
                    .font(.subheadline)
                    .foregroundStyle(Color.jfRed)
                Text("練習した技")
                    .font(.headline)
                    .foregroundStyle(Color.jfTextPrimary)
            }

            // Selected techniques
            if !entry.techniques.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(entry.techniques, id: \.self) { tech in
                            HStack(spacing: 4) {
                                Text(tech)
                                    .font(.caption)
                                Button {
                                    entry.techniques.removeAll { $0 == tech }
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 8, weight: .bold))
                                }
                            }
                            .foregroundStyle(Color.jfRed)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.jfRed.opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                }
            }

            // Category tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Array(techniqueCategories.enumerated()), id: \.offset) { i, cat in
                        Button {
                            withAnimation(.spring(response: 0.25)) { selectedCategory = i }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: cat.icon)
                                    .font(.caption2)
                                Text(cat.name)
                                    .font(.caption.bold())
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(selectedCategory == i ? cat.color : Color.jfCardBg)
                            .foregroundStyle(selectedCategory == i ? .white : Color.jfTextSecondary)
                            .clipShape(Capsule())
                        }
                    }
                }
            }

            // Technique buttons for selected category
            let category = techniqueCategories[selectedCategory]
            FlowLayout(spacing: 6) {
                ForEach(category.techniques, id: \.self) { tech in
                    let isSelected = entry.techniques.contains(tech)
                    Button {
                        if isSelected {
                            entry.techniques.removeAll { $0 == tech }
                        } else {
                            entry.techniques.append(tech)
                        }
                    } label: {
                        Text(tech)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(isSelected ? category.color.opacity(0.2) : Color.jfCardBg)
                            .foregroundStyle(isSelected ? category.color : Color.jfTextSecondary)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(isSelected ? category.color.opacity(0.4) : Color.jfBorder, lineWidth: 1)
                            )
                    }
                }
            }

            // Custom technique input
            HStack(spacing: 8) {
                TextField("その他の技を追加", text: $customTechnique)
                    .font(.caption)
                    .padding(8)
                    .background(Color.jfCardBg)
                    .foregroundStyle(Color.jfTextPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                if !customTechnique.isEmpty {
                    Button {
                        entry.techniques.append(customTechnique)
                        customTechnique = ""
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.jfRed)
                    }
                }
            }
        }
        .padding(14)
        .glassCard()
    }

    private let practiceTypes = [
        ("gi", "道着"),
        ("nogi", "ノーギ"),
        ("drill", "ドリル"),
        ("open_mat", "オープンマット"),
        ("competition", "試合")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Date & Duration
                VStack(alignment: .leading, spacing: 12) {
                    Text("基本情報")
                        .font(.headline)
                        .foregroundStyle(Color.jfTextPrimary)

                    DatePicker("日付", selection: $entry.date, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .foregroundStyle(Color.jfTextPrimary)
                        .tint(.jfRed)

                    HStack {
                        Text("練習時間")
                            .foregroundStyle(Color.jfTextPrimary)
                        Spacer()
                        Stepper("\(entry.duration)分", value: $entry.duration, in: 15...300, step: 15)
                            .foregroundStyle(Color.jfTextPrimary)
                    }
                }
                .padding(16)
                .glassCard()

                // Practice Type
                VStack(alignment: .leading, spacing: 12) {
                    Text("練習タイプ")
                        .font(.headline)
                        .foregroundStyle(Color.jfTextPrimary)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 10) {
                        ForEach(practiceTypes, id: \.0) { type in
                            Button {
                                entry.type = type.0
                            } label: {
                                Text(type.1)
                                    .font(.caption.bold())
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(entry.type == type.0 ? Color.jfRed : Color.jfCardBg)
                                    .foregroundStyle(entry.type == type.0 ? .white : Color.jfTextSecondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(entry.type == type.0 ? Color.clear : Color.jfBorder, lineWidth: 1)
                                    )
                            }
                        }
                    }
                }
                .padding(16)
                .glassCard()

                // Rating
                VStack(alignment: .leading, spacing: 12) {
                    Text("満足度")
                        .font(.headline)
                        .foregroundStyle(Color.jfTextPrimary)

                    HStack(spacing: 12) {
                        ForEach(1...5, id: \.self) { i in
                            Button {
                                entry.rating = i
                            } label: {
                                Image(systemName: i <= entry.rating ? "star.fill" : "star")
                                    .font(.title2)
                                    .foregroundStyle(i <= entry.rating ? .yellow : Color.jfTextTertiary.opacity(0.3))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(16)
                .glassCard()

                // Mood
                VStack(alignment: .leading, spacing: 12) {
                    Text("今日の気分")
                        .font(.headline)
                        .foregroundStyle(Color.jfTextPrimary)
                    HStack(spacing: 12) {
                        ForEach([("great","😆"),("good","😊"),("normal","😐"),("tired","😴"),("bad","😞")], id: \.0) { id, emoji in
                            Button {
                                entry.mood = id
                            } label: {
                                VStack(spacing: 2) {
                                    Text(emoji).font(.title2)
                                    Text(id == "great" ? "最高" : id == "good" ? "良い" : id == "normal" ? "普通" : id == "tired" ? "疲れ" : "悪い")
                                        .font(.system(size: 9))
                                        .foregroundStyle(entry.mood == id ? Color.jfTextPrimary : Color.jfTextTertiary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(entry.mood == id ? Color.jfRed.opacity(0.1) : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(entry.mood == id ? Color.jfRed.opacity(0.3) : Color.clear, lineWidth: 1)
                                )
                            }
                        }
                    }
                }
                .padding(16)
                .glassCard()

                // Intensity + Sparring
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("強度")
                            .font(.caption.bold())
                            .foregroundStyle(Color.jfTextTertiary)
                        HStack(spacing: 4) {
                            ForEach(1...5, id: \.self) { i in
                                Button {
                                    entry.intensity = i
                                } label: {
                                    Image(systemName: i <= (entry.intensity ?? 0) ? "bolt.fill" : "bolt")
                                        .font(.body)
                                        .foregroundStyle(i <= (entry.intensity ?? 0) ? .orange : Color.jfTextTertiary.opacity(0.3))
                                }
                            }
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .glassCard()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("スパーリング")
                            .font(.caption.bold())
                            .foregroundStyle(Color.jfTextTertiary)
                        Stepper("\(entry.sparringRounds ?? 0)本", value: Binding(
                            get: { entry.sparringRounds ?? 0 },
                            set: { entry.sparringRounds = $0 }
                        ), in: 0...20)
                        .font(.subheadline)
                        .foregroundStyle(Color.jfTextPrimary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .glassCard()
                }

                // Injuries
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "bandage.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                        Text("怪我・痛み（あれば）")
                            .font(.caption.bold())
                            .foregroundStyle(Color.jfTextTertiary)
                    }
                    TextField("例: 右膝が少し痛い", text: Binding(
                        get: { entry.injuries ?? "" },
                        set: { entry.injuries = $0.isEmpty ? nil : $0 }
                    ))
                    .padding(10)
                    .background(Color.jfCardBg)
                    .foregroundStyle(Color.jfTextPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(16)
                .glassCard()

                // Techniques practiced
                techniquePicker

                // Notes
                VStack(alignment: .leading, spacing: 12) {
                    Text("メモ・学んだこと")
                        .font(.headline)
                        .foregroundStyle(Color.jfTextPrimary)

                    TextEditor(text: $entry.notes)
                        .frame(minHeight: 80)
                        .scrollContentBackground(.hidden)
                        .background(Color.jfCardBg)
                        .foregroundStyle(Color.jfTextPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.jfBorder, lineWidth: 1)
                        )
                }
                .padding(16)
                .glassCard()

                // Save button
                Button {
                    store.save(entry)
                    dismiss()
                } label: {
                    Text(isNew ? "記録する" : "更新する")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(LinearGradient.jfRedGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                // Delete button (edit mode only)
                if !isNew {
                    Button {
                        store.delete(entry)
                        dismiss()
                    } label: {
                        Text("この記録を削除")
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(16)
            .padding(.bottom, 20)
        }
        .background(Color.jfDarkBg)
        .navigationTitle(isNew ? "新しい記録" : "記録を編集")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isNew {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                        .foregroundStyle(Color.jfTextSecondary)
                }
            }
        }
    }
}
