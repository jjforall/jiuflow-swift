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

    static func new() -> JournalEntry {
        JournalEntry(
            id: UUID().uuidString,
            date: Date(),
            duration: 60,
            type: "gi",
            notes: "",
            techniques: [],
            rating: 3
        )
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
    @State private var selectedMonth = Date()

    private var entriesThisMonth: [JournalEntry] {
        let cal = Calendar.current
        return store.entries.filter {
            cal.isDate($0.date, equalTo: selectedMonth, toGranularity: .month)
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

                // Quick log buttons
                HStack(spacing: 8) {
                    quickLogButton("道着", "tshirt.fill", .blue, "gi")
                    quickLogButton("ノーギ", "figure.run", .orange, "nogi")
                    quickLogButton("ドリル", "arrow.triangle.2.circlepath", .green, "drill")
                    quickLogButton("試合", "trophy.fill", .yellow, "competition")
                }
                .padding(.horizontal, 16)

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
    }

    // MARK: - Month Summary

    private var monthSummary: some View {
        VStack(spacing: 16) {
            // Month selector
            HStack {
                Button {
                    selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(Color.jfTextSecondary)
                }

                Spacer()

                Text(monthString(selectedMonth))
                    .font(.headline)
                    .foregroundStyle(Color.jfTextPrimary)

                Spacer()

                Button {
                    selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
                } label: {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Color.jfTextSecondary)
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

// MARK: - Journal Entry Edit View

struct JournalEntryEditView: View {
    @ObservedObject var store: JournalStore
    @State var entry: JournalEntry
    var isNew: Bool = false
    @Environment(\.dismiss) private var dismiss

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

                // Notes
                VStack(alignment: .leading, spacing: 12) {
                    Text("メモ")
                        .font(.headline)
                        .foregroundStyle(Color.jfTextPrimary)

                    TextEditor(text: $entry.notes)
                        .frame(minHeight: 120)
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
