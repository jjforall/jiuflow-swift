import SwiftUI

// MARK: - Roll Entry Model

struct RollEntry: Codable, Identifiable {
    let id: String
    var date: Date
    var partnerBelt: String // white, blue, purple, brown, black
    var partnerWeight: String // lighter, similar, heavier
    var positionsLost: [String]
    var techniquesWorked: [String]
    var improvements: String
    var wins: Int
    var losses: Int
    var rating: Int // 1-5
    var submissionsCaught: [String] // subs you got caught in
    var escapesSuccessful: [String] // subs you escaped from

    static func new() -> RollEntry {
        RollEntry(id: UUID().uuidString, date: Date(), partnerBelt: "white",
                  partnerWeight: "similar", positionsLost: [], techniquesWorked: [],
                  improvements: "", wins: 0, losses: 0, rating: 3,
                  submissionsCaught: [], escapesSuccessful: [])
    }

    // Migration support: old entries without these fields decode gracefully
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        date = try c.decode(Date.self, forKey: .date)
        partnerBelt = try c.decode(String.self, forKey: .partnerBelt)
        partnerWeight = try c.decode(String.self, forKey: .partnerWeight)
        positionsLost = try c.decode([String].self, forKey: .positionsLost)
        techniquesWorked = try c.decode([String].self, forKey: .techniquesWorked)
        improvements = try c.decode(String.self, forKey: .improvements)
        wins = try c.decode(Int.self, forKey: .wins)
        losses = try c.decode(Int.self, forKey: .losses)
        rating = try c.decode(Int.self, forKey: .rating)
        submissionsCaught = try c.decodeIfPresent([String].self, forKey: .submissionsCaught) ?? []
        escapesSuccessful = try c.decodeIfPresent([String].self, forKey: .escapesSuccessful) ?? []
    }

    init(id: String, date: Date, partnerBelt: String, partnerWeight: String,
         positionsLost: [String], techniquesWorked: [String], improvements: String,
         wins: Int, losses: Int, rating: Int,
         submissionsCaught: [String] = [], escapesSuccessful: [String] = []) {
        self.id = id; self.date = date; self.partnerBelt = partnerBelt
        self.partnerWeight = partnerWeight; self.positionsLost = positionsLost
        self.techniquesWorked = techniquesWorked; self.improvements = improvements
        self.wins = wins; self.losses = losses; self.rating = rating
        self.submissionsCaught = submissionsCaught; self.escapesSuccessful = escapesSuccessful
    }
}

private let submissionPresets = ["RNC", "三角", "腕十字", "ギロチン", "足関節"]
private let techniquePresets = ["三角", "腕十字", "RNC", "ギロチン", "オモプラッタ", "ニースライス", "ダブルレッグ", "バックテイク", "スイープ", "パスガード"]

// MARK: - Roll Store

@MainActor
class RollStore: ObservableObject {
    @Published var entries: [RollEntry] = []
    private let key = "roll_entries"

    init() { load() }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([RollEntry].self, from: data) else { return }
        entries = decoded.sorted { $0.date > $1.date }
    }

    func save(_ entry: RollEntry) {
        if let i = entries.firstIndex(where: { $0.id == entry.id }) { entries[i] = entry }
        else { entries.insert(entry, at: 0) }
        persist()
    }

    func delete(_ entry: RollEntry) {
        entries.removeAll { $0.id == entry.id }
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(entries) { UserDefaults.standard.set(data, forKey: key) }
    }
}

// MARK: - Roll Journal View

struct RollJournalView: View {
    @StateObject private var store = RollStore()
    @State private var showNewRoll = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                // Stats
                if !store.entries.isEmpty {
                    rollStats
                }

                // Entry list
                if store.entries.isEmpty {
                    EmptyStateView(
                        icon: "sportscourt",
                        title: "まだロール記録がありません",
                        message: "スパーリング後に記録をつけましょう",
                        actionTitle: "ロールを記録"
                    ) { showNewRoll = true }
                    .frame(minHeight: 250)
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(store.entries) { entry in
                            NavigationLink {
                                RollEntryEditView(store: store, entry: entry)
                            } label: {
                                rollRow(entry)
                            }
                        }
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .background(Color.jfDarkBg)
        .navigationTitle("ロール記録")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showNewRoll = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.jfRed)
                }
            }
        }
        .sheet(isPresented: $showNewRoll) {
            NavigationStack {
                RollEntryEditView(store: store, entry: .new(), isNew: true)
            }
        }
    }

    private var rollStats: some View {
        VStack(spacing: 10) {
            HStack(spacing: 0) {
                statItem("\(store.entries.count)", "ロール", .blue)
                Rectangle().fill(Color.jfBorder).frame(width: 1, height: 40)
                let totalW = store.entries.reduce(0) { $0 + $1.wins }
                let totalL = store.entries.reduce(0) { $0 + $1.losses }
                statItem("\(totalW)-\(totalL)", "勝-負", .jfRed)
                Rectangle().fill(Color.jfBorder).frame(width: 1, height: 40)
                let avgR = store.entries.isEmpty ? 0 : store.entries.reduce(0) { $0 + $1.rating } / store.entries.count
                statItem("\(avgR)/5", "満足度", .yellow)
            }

            // Submission defense stats
            let allCaught = store.entries.flatMap(\.submissionsCaught)
            if !allCaught.isEmpty {
                Rectangle().fill(Color.jfBorder).frame(height: 1)
                HStack(spacing: 0) {
                    statItem("\(allCaught.count)", "被サブ", .orange)
                    Rectangle().fill(Color.jfBorder).frame(width: 1, height: 40)
                    let allEscapes = store.entries.flatMap(\.escapesSuccessful)
                    statItem("\(allEscapes.count)", "エスケープ", .green)
                    Rectangle().fill(Color.jfBorder).frame(width: 1, height: 40)
                    // Most common sub caught
                    let counts = Dictionary(allCaught.map { ($0, 1) }, uniquingKeysWith: +)
                    let worst = counts.max(by: { $0.value < $1.value })?.key ?? "-"
                    statItem(worst, "弱点", .red)
                }
            }
        }
        .padding(12)
        .glassCard()
    }

    private func statItem(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title3.bold().monospacedDigit()).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(Color.jfTextTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private func rollRow(_ entry: RollEntry) -> some View {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ja_JP")
        df.dateFormat = "M/d (E)"
        let beltColor: Color = {
            switch entry.partnerBelt {
            case "blue": return .blue; case "purple": return .purple
            case "brown": return .brown; case "black": return .red
            default: return .gray
            }
        }()

        return HStack(spacing: 12) {
            Circle().fill(beltColor).frame(width: 12, height: 12)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(df.string(from: entry.date))
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.jfTextPrimary)
                    Text("\(entry.wins)W-\(entry.losses)L")
                        .font(.caption.bold().monospacedDigit())
                        .foregroundStyle(entry.wins > entry.losses ? .green : entry.wins < entry.losses ? .orange : Color.jfTextTertiary)
                }
                if !entry.techniquesWorked.isEmpty {
                    Text(entry.techniquesWorked.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                        .lineLimit(1)
                }
            }
            Spacer()
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { i in
                    Image(systemName: i <= entry.rating ? "star.fill" : "star")
                        .font(.system(size: 8))
                        .foregroundStyle(i <= entry.rating ? .yellow : Color.jfTextTertiary.opacity(0.3))
                }
            }
        }
        .padding(12)
        .glassCard(cornerRadius: 14)
    }
}

// MARK: - Roll Entry Edit

struct RollEntryEditView: View {
    @ObservedObject var store: RollStore
    @State var entry: RollEntry
    var isNew: Bool = false
    @Environment(\.dismiss) private var dismiss
    @State private var newTechnique = ""
    @State private var newCaughtSub = ""
    @State private var newEscape = ""

    private let beltOptions = [("white","白帯"),("blue","青帯"),("purple","紫帯"),("brown","茶帯"),("black","黒帯")]
    private let weightOptions = [("lighter","軽い"),("similar","同じくらい"),("heavier","重い")]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Date
                DatePicker("日付", selection: $entry.date, displayedComponents: .date)
                    .datePickerStyle(.compact).tint(.jfRed)
                    .padding(12).glassCard()

                // Partner info
                VStack(alignment: .leading, spacing: 10) {
                    Text("パートナー").font(.headline).foregroundStyle(Color.jfTextPrimary)
                    HStack(spacing: 6) {
                        ForEach(beltOptions, id: \.0) { b in
                            Button { entry.partnerBelt = b.0 } label: {
                                Text(b.1).font(.caption.bold())
                                    .padding(.horizontal, 10).padding(.vertical, 6)
                                    .background(entry.partnerBelt == b.0 ? Color.jfRed : Color.jfCardBg)
                                    .foregroundStyle(entry.partnerBelt == b.0 ? .white : Color.jfTextSecondary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    HStack(spacing: 6) {
                        ForEach(weightOptions, id: \.0) { w in
                            Button { entry.partnerWeight = w.0 } label: {
                                Text(w.1).font(.caption.bold())
                                    .padding(.horizontal, 10).padding(.vertical, 6)
                                    .background(entry.partnerWeight == w.0 ? Color.blue : Color.jfCardBg)
                                    .foregroundStyle(entry.partnerWeight == w.0 ? .white : Color.jfTextSecondary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }.padding(12).glassCard()

                // Win/Loss
                VStack(alignment: .leading, spacing: 10) {
                    Text("結果").font(.headline).foregroundStyle(Color.jfTextPrimary)
                    HStack {
                        Text("勝ち").foregroundStyle(Color.jfTextSecondary)
                        Stepper("\(entry.wins)", value: $entry.wins, in: 0...20).foregroundStyle(Color.jfTextPrimary)
                    }
                    HStack {
                        Text("負け").foregroundStyle(Color.jfTextSecondary)
                        Stepper("\(entry.losses)", value: $entry.losses, in: 0...20).foregroundStyle(Color.jfTextPrimary)
                    }
                }.padding(12).glassCard()

                // Techniques
                VStack(alignment: .leading, spacing: 8) {
                    Text("使った技").font(.headline).foregroundStyle(Color.jfTextPrimary)

                    // Preset technique buttons
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(techniquePresets, id: \.self) { preset in
                                let isSelected = entry.techniquesWorked.contains(preset)
                                Button {
                                    if !isSelected {
                                        entry.techniquesWorked.append(preset)
                                    }
                                } label: {
                                    Text(preset)
                                        .font(.caption.bold())
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(isSelected ? Color.jfRed.opacity(0.2) : Color.jfCardBg)
                                        .foregroundStyle(isSelected ? Color.jfRed.opacity(0.5) : Color.jfTextSecondary)
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule().stroke(isSelected ? Color.jfRed.opacity(0.3) : Color.jfBorder, lineWidth: 1)
                                        )
                                }
                                .disabled(isSelected)
                            }
                        }
                    }

                    HStack {
                        TextField("テクニック名", text: $newTechnique)
                            .padding(8).background(Color.jfCardBg).clipShape(RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(Color.jfTextPrimary)
                        Button {
                            if !newTechnique.isEmpty { entry.techniquesWorked.append(newTechnique); newTechnique = "" }
                        } label: {
                            Image(systemName: "plus.circle.fill").foregroundStyle(Color.jfRed)
                        }
                    }
                    FlowLayout(spacing: 6) {
                        ForEach(entry.techniquesWorked, id: \.self) { t in
                            HStack(spacing: 4) {
                                Text(t).font(.caption)
                                Button { entry.techniquesWorked.removeAll { $0 == t } } label: {
                                    Image(systemName: "xmark").font(.system(size: 8))
                                }
                            }
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Color.jfRed.opacity(0.12))
                            .foregroundStyle(Color.jfRed).clipShape(Capsule())
                        }
                    }
                }.padding(12).glassCard()

                // Submissions caught
                VStack(alignment: .leading, spacing: 8) {
                    Text("やられた技").font(.headline).foregroundStyle(Color.jfTextPrimary)
                    // Preset buttons
                    FlowLayout(spacing: 6) {
                        ForEach(submissionPresets, id: \.self) { preset in
                            Button {
                                if !entry.submissionsCaught.contains(preset) {
                                    entry.submissionsCaught.append(preset)
                                }
                            } label: {
                                Text(preset).font(.caption.bold())
                                    .padding(.horizontal, 10).padding(.vertical, 6)
                                    .background(entry.submissionsCaught.contains(preset) ? Color.orange : Color.jfCardBg)
                                    .foregroundStyle(entry.submissionsCaught.contains(preset) ? .white : Color.jfTextSecondary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    HStack {
                        TextField("その他の技", text: $newCaughtSub)
                            .padding(8).background(Color.jfCardBg).clipShape(RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(Color.jfTextPrimary)
                        Button {
                            if !newCaughtSub.isEmpty { entry.submissionsCaught.append(newCaughtSub); newCaughtSub = "" }
                        } label: {
                            Image(systemName: "plus.circle.fill").foregroundStyle(.orange)
                        }
                    }
                    FlowLayout(spacing: 6) {
                        ForEach(entry.submissionsCaught, id: \.self) { t in
                            HStack(spacing: 4) {
                                Text(t).font(.caption)
                                Button { entry.submissionsCaught.removeAll { $0 == t } } label: {
                                    Image(systemName: "xmark").font(.system(size: 8))
                                }
                            }
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Color.orange.opacity(0.12))
                            .foregroundStyle(.orange).clipShape(Capsule())
                        }
                    }
                }.padding(12).glassCard()

                // Escapes successful
                VStack(alignment: .leading, spacing: 8) {
                    Text("エスケープ成功").font(.headline).foregroundStyle(Color.jfTextPrimary)
                    // Preset buttons
                    FlowLayout(spacing: 6) {
                        ForEach(submissionPresets, id: \.self) { preset in
                            Button {
                                if !entry.escapesSuccessful.contains(preset) {
                                    entry.escapesSuccessful.append(preset)
                                }
                            } label: {
                                Text(preset).font(.caption.bold())
                                    .padding(.horizontal, 10).padding(.vertical, 6)
                                    .background(entry.escapesSuccessful.contains(preset) ? Color.green : Color.jfCardBg)
                                    .foregroundStyle(entry.escapesSuccessful.contains(preset) ? .white : Color.jfTextSecondary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    HStack {
                        TextField("その他の技", text: $newEscape)
                            .padding(8).background(Color.jfCardBg).clipShape(RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(Color.jfTextPrimary)
                        Button {
                            if !newEscape.isEmpty { entry.escapesSuccessful.append(newEscape); newEscape = "" }
                        } label: {
                            Image(systemName: "plus.circle.fill").foregroundStyle(.green)
                        }
                    }
                    FlowLayout(spacing: 6) {
                        ForEach(entry.escapesSuccessful, id: \.self) { t in
                            HStack(spacing: 4) {
                                Text(t).font(.caption)
                                Button { entry.escapesSuccessful.removeAll { $0 == t } } label: {
                                    Image(systemName: "xmark").font(.system(size: 8))
                                }
                            }
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Color.green.opacity(0.12))
                            .foregroundStyle(.green).clipShape(Capsule())
                        }
                    }
                }.padding(12).glassCard()

                // Rating
                VStack(alignment: .leading, spacing: 8) {
                    Text("満足度").font(.headline).foregroundStyle(Color.jfTextPrimary)
                    HStack(spacing: 10) {
                        ForEach(1...5, id: \.self) { i in
                            Button { entry.rating = i } label: {
                                Image(systemName: i <= entry.rating ? "star.fill" : "star")
                                    .font(.title2)
                                    .foregroundStyle(i <= entry.rating ? .yellow : Color.jfTextTertiary.opacity(0.3))
                            }
                        }
                    }.frame(maxWidth: .infinity)
                }.padding(12).glassCard()

                // Improvements
                VStack(alignment: .leading, spacing: 8) {
                    Text("改善点・メモ").font(.headline).foregroundStyle(Color.jfTextPrimary)
                    TextEditor(text: $entry.improvements)
                        .frame(minHeight: 80).scrollContentBackground(.hidden)
                        .background(Color.jfCardBg).foregroundStyle(Color.jfTextPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }.padding(12).glassCard()

                // Save
                Button { store.save(entry); dismiss() } label: {
                    Text(isNew ? "記録する" : "更新する").font(.headline).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(LinearGradient.jfRedGradient).clipShape(RoundedRectangle(cornerRadius: 14))
                }

                if !isNew {
                    Button { store.delete(entry); dismiss() } label: {
                        Text("削除").font(.subheadline).foregroundStyle(.red)
                    }
                }
            }
            .padding(16).padding(.bottom, 20)
        }
        .background(Color.jfDarkBg)
        .navigationTitle(isNew ? "ロール記録" : "編集")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isNew {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }.foregroundStyle(Color.jfTextSecondary)
                }
            }
        }
    }
}
