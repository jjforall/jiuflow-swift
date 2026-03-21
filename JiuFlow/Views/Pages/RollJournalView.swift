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

    static func new() -> RollEntry {
        RollEntry(id: UUID().uuidString, date: Date(), partnerBelt: "white",
                  partnerWeight: "similar", positionsLost: [], techniquesWorked: [],
                  improvements: "", wins: 0, losses: 0, rating: 3)
    }
}

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
