import SwiftUI

// MARK: - Weight Class

struct WeightClass: Identifiable {
    let id = UUID()
    let name: String
    let nameJa: String
    let maxKg: Double

    static let all: [WeightClass] = [
        WeightClass(name: "Rooster", nameJa: "ルースター", maxKg: 57.5),
        WeightClass(name: "Light Feather", nameJa: "ライトフェザー", maxKg: 64.0),
        WeightClass(name: "Feather", nameJa: "フェザー", maxKg: 70.0),
        WeightClass(name: "Light", nameJa: "ライト", maxKg: 76.0),
        WeightClass(name: "Middle", nameJa: "ミドル", maxKg: 82.3),
        WeightClass(name: "Medium Heavy", nameJa: "ミディアムヘビー", maxKg: 88.3),
        WeightClass(name: "Heavy", nameJa: "ヘビー", maxKg: 94.3),
        WeightClass(name: "Super Heavy", nameJa: "スーパーヘビー", maxKg: 100.5),
        WeightClass(name: "Ultra Heavy", nameJa: "ウルトラヘビー", maxKg: 999.0),
    ]
}

// MARK: - Weight Entry

struct WeightEntry: Codable, Identifiable {
    let id: String
    let date: Date
    let weight: Double
}

// MARK: - Weight Store

@MainActor
class WeightStore: ObservableObject {
    @Published var entries: [WeightEntry] = []
    @Published var targetWeight: Double = 70.0 {
        didSet { UserDefaults.standard.set(targetWeight, forKey: "weight_target") }
    }
    @Published var selectedClassIndex: Int = 0 {
        didSet { UserDefaults.standard.set(selectedClassIndex, forKey: "weight_class_index") }
    }
    @Published var competitionDate: Date = Date().addingTimeInterval(30 * 86400) {
        didSet { UserDefaults.standard.set(competitionDate.timeIntervalSince1970, forKey: "weight_comp_date") }
    }

    private let entriesKey = "weight_entries"

    init() {
        let tw = UserDefaults.standard.double(forKey: "weight_target")
        if tw > 0 { targetWeight = tw }
        selectedClassIndex = UserDefaults.standard.integer(forKey: "weight_class_index")
        let ts = UserDefaults.standard.double(forKey: "weight_comp_date")
        if ts > 0 { competitionDate = Date(timeIntervalSince1970: ts) }
        loadEntries()
    }

    func loadEntries() {
        guard let data = UserDefaults.standard.data(forKey: entriesKey),
              let decoded = try? JSONDecoder().decode([WeightEntry].self, from: data) else { return }
        entries = decoded.sorted { $0.date > $1.date }
    }

    func addEntry(weight: Double) {
        let entry = WeightEntry(id: UUID().uuidString, date: Date(), weight: weight)
        entries.insert(entry, at: 0)
        if entries.count > 30 { entries = Array(entries.prefix(30)) }
        persistEntries()
    }

    func updateEntry(_ id: String, weight: Double) {
        if let i = entries.firstIndex(where: { $0.id == id }) {
            entries[i] = WeightEntry(id: id, date: entries[i].date, weight: weight)
            persistEntries()
        }
    }

    func deleteEntry(_ entry: WeightEntry) {
        entries.removeAll { $0.id == entry.id }
        persistEntries()
    }

    private func persistEntries() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: entriesKey)
        }
    }
}

// MARK: - Weight Tracker View

struct WeightTrackerView: View {
    @StateObject private var store = WeightStore()
    @State private var inputWeight: Double = 70.0
    @State private var showClassPicker = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                // Current status card
                statusCard

                // Weight input
                weightInputCard

                // Competition info
                competitionCard

                // Chart
                if store.entries.count >= 2 {
                    chartCard
                }

                // History
                historyCard
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .background(Color.jfDarkBg)
        .navigationTitle("体重管理")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            if let last = store.entries.first {
                inputWeight = last.weight
            }
        }
    }

    // MARK: - Status Card

    private var statusCard: some View {
        VStack(spacing: 12) {
            if let latest = store.entries.first {
                let diff = latest.weight - store.targetWeight
                let statusColor = weightStatusColor(latest.weight)

                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("現在").font(.caption).foregroundStyle(Color.jfTextTertiary)
                        Text(String(format: "%.1f", latest.weight))
                            .font(.system(size: 36, weight: .bold, design: .monospaced))
                            .foregroundStyle(statusColor)
                        Text("kg").font(.caption).foregroundStyle(Color.jfTextTertiary)
                    }

                    Rectangle().fill(Color.jfBorder).frame(width: 1, height: 60)

                    VStack(spacing: 4) {
                        Text("目標").font(.caption).foregroundStyle(Color.jfTextTertiary)
                        Text(String(format: "%.1f", store.targetWeight))
                            .font(.system(size: 36, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.jfTextPrimary)
                        Text("kg").font(.caption).foregroundStyle(Color.jfTextTertiary)
                    }

                    Rectangle().fill(Color.jfBorder).frame(width: 1, height: 60)

                    VStack(spacing: 4) {
                        Text("差").font(.caption).foregroundStyle(Color.jfTextTertiary)
                        Text(String(format: "%+.1f", diff))
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundStyle(statusColor)
                        Text("kg").font(.caption).foregroundStyle(Color.jfTextTertiary)
                    }
                }
                .frame(maxWidth: .infinity)
            } else {
                Text("体重を記録しましょう")
                    .font(.headline).foregroundStyle(Color.jfTextSecondary)
            }
        }
        .padding(16).glassCard()
    }

    // MARK: - Weight Input Card

    private var weightInputCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("体重を記録").font(.headline).foregroundStyle(Color.jfTextPrimary)

            HStack {
                Button {
                    inputWeight = max(30.0, inputWeight - 0.1)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2).foregroundStyle(Color.jfRed)
                }

                Spacer()

                Text(String(format: "%.1f kg", inputWeight))
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.jfTextPrimary)

                Spacer()

                Button {
                    inputWeight = min(200.0, inputWeight + 0.1)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2).foregroundStyle(Color.jfRed)
                }
            }

            // Quick adjust buttons
            HStack(spacing: 8) {
                ForEach([-1.0, -0.5, 0.5, 1.0], id: \.self) { delta in
                    Button {
                        inputWeight = max(30.0, min(200.0, inputWeight + delta))
                    } label: {
                        Text(String(format: "%+.1f", delta))
                            .font(.caption.bold().monospacedDigit())
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Color.jfCardBg)
                            .foregroundStyle(Color.jfTextSecondary)
                            .clipShape(Capsule())
                    }
                }
            }
            .frame(maxWidth: .infinity)

            Button {
                store.addEntry(weight: inputWeight)
            } label: {
                Text("記録する").font(.subheadline.bold()).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(LinearGradient.jfRedGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .sensoryFeedback(.impact(flexibility: .soft), trigger: store.entries.count)
        }
        .padding(12).glassCard()
    }

    // MARK: - Competition Card

    private var competitionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("大会設定").font(.headline).foregroundStyle(Color.jfTextPrimary)

            // Weight class
            Button { showClassPicker.toggle() } label: {
                HStack {
                    Text("階級").foregroundStyle(Color.jfTextSecondary)
                    Spacer()
                    let wc = WeightClass.all[store.selectedClassIndex]
                    Text("\(wc.nameJa) (\(wc.maxKg < 999 ? String(format: "%.1fkg", wc.maxKg) : "制限なし"))")
                        .foregroundStyle(Color.jfTextPrimary)
                    Image(systemName: "chevron.down")
                        .font(.caption).foregroundStyle(Color.jfTextTertiary)
                }
                .font(.subheadline)
            }

            if showClassPicker {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(Array(WeightClass.all.enumerated()), id: \.offset) { i, wc in
                            Button {
                                store.selectedClassIndex = i
                                store.targetWeight = wc.maxKg < 999 ? wc.maxKg : store.targetWeight
                                showClassPicker = false
                            } label: {
                                VStack(spacing: 2) {
                                    Text(wc.nameJa).font(.caption.bold())
                                    if wc.maxKg < 999 {
                                        Text(String(format: "%.1f", wc.maxKg)).font(.caption2.monospacedDigit())
                                    } else {
                                        Text("制限なし").font(.caption2)
                                    }
                                }
                                .padding(.horizontal, 10).padding(.vertical, 8)
                                .background(store.selectedClassIndex == i ? Color.jfRed : Color.jfCardBg)
                                .foregroundStyle(store.selectedClassIndex == i ? .white : Color.jfTextSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                }
            }

            // Target weight
            HStack {
                Text("目標体重").foregroundStyle(Color.jfTextSecondary)
                Spacer()
                HStack(spacing: 8) {
                    Button {
                        store.targetWeight = max(30, store.targetWeight - 0.1)
                    } label: {
                        Image(systemName: "minus").font(.caption).foregroundStyle(Color.jfTextTertiary)
                    }
                    Text(String(format: "%.1f kg", store.targetWeight))
                        .font(.subheadline.bold().monospacedDigit())
                        .foregroundStyle(Color.jfTextPrimary)
                    Button {
                        store.targetWeight = min(200, store.targetWeight + 0.1)
                    } label: {
                        Image(systemName: "plus").font(.caption).foregroundStyle(Color.jfTextTertiary)
                    }
                }
            }
            .font(.subheadline)

            // Competition date
            DatePicker("大会日", selection: $store.competitionDate, displayedComponents: .date)
                .datePickerStyle(.compact).tint(.jfRed)
                .font(.subheadline)
                .foregroundStyle(Color.jfTextSecondary)

            // Days remaining
            let days = Calendar.current.dateComponents([.day], from: Date(), to: store.competitionDate).day ?? 0
            if days > 0 {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundStyle(.orange)
                    Text("大会まで あと")
                        .foregroundStyle(Color.jfTextTertiary)
                    Text("\(days)日")
                        .font(.headline.bold().monospacedDigit())
                        .foregroundStyle(.orange)
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(Color.orange.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(12).glassCard()
    }

    // MARK: - Simple Line Chart

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("体重推移").font(.headline).foregroundStyle(Color.jfTextPrimary)

            let sorted = store.entries.sorted { $0.date < $1.date }
            let weights = sorted.map(\.weight)
            let minW = (weights.min() ?? 60) - 1
            let maxW = (weights.max() ?? 80) + 1
            let range = max(maxW - minW, 1)

            ZStack(alignment: .topLeading) {
                // Target line
                GeometryReader { geo in
                    let h = geo.size.height
                    let targetY = h - ((store.targetWeight - minW) / range) * h
                    if targetY > 0 && targetY < h {
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: targetY))
                            path.addLine(to: CGPoint(x: geo.size.width, y: targetY))
                        }
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        .foregroundStyle(Color.green.opacity(0.5))

                        Text("目標")
                            .font(.system(size: 9))
                            .foregroundStyle(.green)
                            .position(x: 20, y: targetY - 10)
                    }
                }

                // Line chart
                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height
                    let count = sorted.count

                    if count >= 2 {
                        Path { path in
                            for (i, entry) in sorted.enumerated() {
                                let x = count > 1 ? (w * CGFloat(i) / CGFloat(count - 1)) : w / 2
                                let y = h - ((entry.weight - minW) / range) * h
                                if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                                else { path.addLine(to: CGPoint(x: x, y: y)) }
                            }
                        }
                        .stroke(Color.jfRed, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                        // Dots
                        ForEach(Array(sorted.enumerated()), id: \.element.id) { i, entry in
                            let x = count > 1 ? (w * CGFloat(i) / CGFloat(count - 1)) : w / 2
                            let y = h - ((entry.weight - minW) / range) * h
                            Circle()
                                .fill(weightStatusColor(entry.weight))
                                .frame(width: 6, height: 6)
                                .position(x: x, y: y)
                        }
                    }
                }
            }
            .frame(height: 160)
            .padding(.vertical, 4)

            // Y-axis labels
            HStack {
                Text(String(format: "%.1f", maxW)).font(.system(size: 9).monospacedDigit())
                    .foregroundStyle(Color.jfTextTertiary)
                Spacer()
                Text(String(format: "%.1f", minW)).font(.system(size: 9).monospacedDigit())
                    .foregroundStyle(Color.jfTextTertiary)
            }
        }
        .padding(12).glassCard()
    }

    @State private var editingEntryId: String?
    @State private var editWeight: Double = 0

    // MARK: - History

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("記録履歴").font(.headline).foregroundStyle(Color.jfTextPrimary)
            Text("タップで編集 / スワイプで削除").font(.caption2).foregroundStyle(Color.jfTextTertiary)

            if store.entries.isEmpty {
                Text("まだ記録がありません")
                    .font(.subheadline).foregroundStyle(Color.jfTextTertiary)
                    .frame(maxWidth: .infinity, minHeight: 60)
            } else {
                ForEach(store.entries) { entry in
                    let df: DateFormatter = {
                        let f = DateFormatter()
                        f.locale = Locale(identifier: "ja_JP")
                        f.dateFormat = "M/d (E) HH:mm"
                        return f
                    }()

                    if editingEntryId == entry.id {
                        // Edit mode
                        HStack(spacing: 8) {
                            Text(df.string(from: entry.date))
                                .font(.caption).foregroundStyle(Color.jfTextTertiary)
                            Spacer()
                            Button { editWeight = max(30, editWeight - 0.1) } label: {
                                Image(systemName: "minus.circle.fill").foregroundStyle(.orange)
                            }
                            Text(String(format: "%.1f", editWeight))
                                .font(.subheadline.bold().monospacedDigit())
                                .foregroundStyle(Color.jfTextPrimary)
                                .frame(width: 50)
                            Button { editWeight = min(200, editWeight + 0.1) } label: {
                                Image(systemName: "plus.circle.fill").foregroundStyle(.green)
                            }
                            Button {
                                store.updateEntry(entry.id, weight: editWeight)
                                editingEntryId = nil
                            } label: {
                                Text("保存").font(.caption.bold())
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10).padding(.vertical, 4)
                                    .background(Color.jfRed).clipShape(Capsule())
                            }
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .background(Color.jfRed.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        // Display mode
                        Button {
                            editWeight = entry.weight
                            editingEntryId = entry.id
                        } label: {
                            HStack {
                                Text(df.string(from: entry.date))
                                    .font(.caption).foregroundStyle(Color.jfTextTertiary)
                                Spacer()
                                Text(String(format: "%.1f kg", entry.weight))
                                    .font(.subheadline.bold().monospacedDigit())
                                    .foregroundStyle(weightStatusColor(entry.weight))
                                Image(systemName: "pencil")
                                    .font(.caption2)
                                    .foregroundStyle(Color.jfTextTertiary.opacity(0.4))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding(12).glassCard()
    }

    // MARK: - Helpers

    private func weightStatusColor(_ weight: Double) -> Color {
        let diff = weight - store.targetWeight
        if diff <= 0 { return .green }
        if diff <= 2.0 { return .orange }
        return .red
    }
}
