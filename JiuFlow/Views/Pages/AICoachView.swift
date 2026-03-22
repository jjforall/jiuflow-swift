import SwiftUI

/// AI分析: ロール記録から弱点を分析し、今週のドリルを提案
struct AICoachView: View {
    @StateObject private var rollStore = RollStore()
    @StateObject private var journalStore = JournalStore()
    @AppStorage("roadmap_progress") private var progressData: Data = Data()

    private var progress: [String: String] {
        (try? JSONDecoder().decode([String: String].self, from: progressData)) ?? [:]
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                // Header
                VStack(spacing: 8) {
                    Text("🥋")
                        .font(.system(size: 48))
                    Text("AI コーチ分析")
                        .font(.title2.bold())
                        .foregroundStyle(Color.jfTextPrimary)
                    Text("あなたの練習データから改善ポイントを提案")
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                }
                .padding(.top, 12)

                if rollStore.entries.isEmpty && journalStore.entries.isEmpty {
                    emptyState
                } else {
                    // Weakness analysis
                    weaknessCard
                    // Weekly drill plan
                    drillPlanCard
                    // Training consistency
                    consistencyCard
                    // Technique coverage
                    coverageCard
                }
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .background(Color.jfDarkBg)
        .navigationTitle("AIコーチ")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 48))
                .foregroundStyle(Color.jfTextTertiary.opacity(0.3))
            Text("データがまだありません")
                .font(.headline)
                .foregroundStyle(Color.jfTextPrimary)
            Text("練習日記やロール記録を付けると\nAIがあなたの弱点を分析し\nドリルメニューを提案します")
                .font(.subheadline)
                .foregroundStyle(Color.jfTextTertiary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Weakness Card

    private var weaknessCard: some View {
        let allCaught = rollStore.entries.flatMap(\.submissionsCaught)
        let counts = Dictionary(allCaught.map { ($0, 1) }, uniquingKeysWith: +)
        let sorted = counts.sorted { $0.value > $1.value }
        let allEscapes = rollStore.entries.flatMap(\.escapesSuccessful)
        let escapeCounts = Dictionary(allEscapes.map { ($0, 1) }, uniquingKeysWith: +)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("弱点分析")
                    .font(.headline)
                    .foregroundStyle(Color.jfTextPrimary)
            }

            if sorted.isEmpty {
                Text("ロール記録に「やられた技」を記録すると弱点が表示されます")
                    .font(.caption)
                    .foregroundStyle(Color.jfTextTertiary)
            } else {
                ForEach(sorted.prefix(5), id: \.key) { sub, count in
                    let escapeCount = escapeCounts[sub] ?? 0
                    let escapeRate = count > 0 ? Int(Double(escapeCount) / Double(count + escapeCount) * 100) : 0
                    HStack(spacing: 10) {
                        Text(sub)
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.jfTextPrimary)
                            .frame(width: 80, alignment: .leading)
                        // Bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.red.opacity(0.15))
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.red)
                                    .frame(width: geo.size.width * CGFloat(count) / CGFloat((sorted.first?.value ?? 1) + 1))
                            }
                        }
                        .frame(height: 8)
                        Text("\(count)回")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.red)
                            .frame(width: 35, alignment: .trailing)
                        Text("防御\(escapeRate)%")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(escapeRate > 50 ? .green : .orange)
                            .frame(width: 50, alignment: .trailing)
                    }
                }
            }
        }
        .padding(14)
        .glassCard()
    }

    // MARK: - Drill Plan

    private var drillPlanCard: some View {
        let allCaught = rollStore.entries.flatMap(\.submissionsCaught)
        let counts = Dictionary(allCaught.map { ($0, 1) }, uniquingKeysWith: +)
        let topWeakness = counts.max(by: { $0.value < $1.value })?.key

        let drills: [(name: String, desc: String, reps: String)] = {
            switch topWeakness {
            case "RNC":
                return [
                    ("バックエスケープドリル", "手を下に引いて体をずらす→ヒップエスケープ", "5分×3セット"),
                    ("2on1グリップブレイク", "両手で片手をコントロール→顎を引く", "10回×3セット"),
                    ("タートルからの逃げ", "ドッグファイト→ハーフガードリカバリー", "5分×2セット"),
                ]
            case "三角":
                return [
                    ("ポスチャー練習", "クローズドガードで姿勢を立てる練習", "5分×3セット"),
                    ("腕を抜くドリル", "三角の形に入られたら即座に腕を引き抜く", "10回×3セット"),
                    ("スタックパス", "三角をセットされたらスタックして圧をかける", "10回×2セット"),
                ]
            case "腕十字":
                return [
                    ("エルボーディフェンス", "肘を体に密着させるポジション維持", "5分×3セット"),
                    ("ヒッチハイカーエスケープ", "腕十字からの脱出ドリル", "10回×3セット"),
                    ("グリップファイト", "相手に腕を伸ばされない握り方", "5分×2セット"),
                ]
            default:
                return [
                    ("ヒップエスケープドリル", "基本のエビを高速で", "5分×3セット"),
                    ("ブリッジ練習", "マウント下からのブリッジ→エビ", "10回×3セット"),
                    ("ガードリテンション", "パスされそうになったらガードを戻す", "5分×3セット"),
                ]
            }
        }()

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "list.bullet.clipboard.fill")
                    .foregroundStyle(.blue)
                Text("今週のドリルメニュー")
                    .font(.headline)
                    .foregroundStyle(Color.jfTextPrimary)
            }

            if let weakness = topWeakness {
                Text("「\(weakness)」対策を重点的に")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            ForEach(Array(drills.enumerated()), id: \.offset) { i, drill in
                HStack(spacing: 10) {
                    Text("\(i + 1)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(Color.blue)
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text(drill.name)
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.jfTextPrimary)
                        Text(drill.desc)
                            .font(.caption)
                            .foregroundStyle(Color.jfTextTertiary)
                    }
                    Spacer()
                    Text(drill.reps)
                        .font(.caption2.bold())
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding(14)
        .glassCard()
    }

    // MARK: - Consistency

    private var consistencyCard: some View {
        let last30 = journalStore.entries.filter {
            $0.date > Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        }
        let uniqueDays = Set(last30.map { Calendar.current.startOfDay(for: $0.date) }).count
        let streak = calculateStreak()

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text("継続性")
                    .font(.headline)
                    .foregroundStyle(Color.jfTextPrimary)
            }

            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text("\(streak)")
                        .font(.title.bold().monospacedDigit())
                        .foregroundStyle(streak > 0 ? .orange : Color.jfTextTertiary)
                    Text("連続日")
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                }
                .frame(maxWidth: .infinity)

                Rectangle().fill(Color.jfBorder).frame(width: 1, height: 36)

                VStack(spacing: 4) {
                    Text("\(uniqueDays)")
                        .font(.title.bold().monospacedDigit())
                        .foregroundStyle(Color.jfTextPrimary)
                    Text("日/30日")
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                }
                .frame(maxWidth: .infinity)

                Rectangle().fill(Color.jfBorder).frame(width: 1, height: 36)

                VStack(spacing: 4) {
                    let totalMin = last30.reduce(0) { $0 + $1.duration }
                    Text("\(totalMin / 60)h")
                        .font(.title.bold().monospacedDigit())
                        .foregroundStyle(Color.jfTextPrimary)
                    Text("合計")
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                }
                .frame(maxWidth: .infinity)
            }

            // Weekly heatmap (last 4 weeks)
            weeklyHeatmap
        }
        .padding(14)
        .glassCard()
    }

    private var weeklyHeatmap: some View {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let practiceDays = Set(journalStore.entries.map { cal.startOfDay(for: $0.date) })

        return VStack(alignment: .leading, spacing: 4) {
            Text("直近28日")
                .font(.caption2)
                .foregroundStyle(Color.jfTextTertiary)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 7), spacing: 3) {
                ForEach(0..<28, id: \.self) { i in
                    let day = cal.date(byAdding: .day, value: -(27 - i), to: today)!
                    let practiced = practiceDays.contains(day)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(practiced ? Color.green : Color.jfCardBg)
                        .frame(height: 12)
                }
            }
        }
    }

    // MARK: - Coverage

    private var coverageCard: some View {
        let total = 48 // roadmap total
        let done = progress.values.filter { $0 == "done" }.count
        let practicing = progress.values.filter { $0 == "practicing" }.count
        let pct = total > 0 ? Int(Double(done) / Double(total) * 100) : 0

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                Text("テクニック習得率")
                    .font(.headline)
                    .foregroundStyle(Color.jfTextPrimary)
            }

            HStack(spacing: 16) {
                // Progress ring
                ZStack {
                    Circle().stroke(Color.jfBorder, lineWidth: 6).frame(width: 60, height: 60)
                    Circle().trim(from: 0, to: Double(pct) / 100)
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 60, height: 60).rotationEffect(.degrees(-90))
                    Text("\(pct)%")
                        .font(.subheadline.bold().monospacedDigit())
                        .foregroundStyle(Color.jfTextPrimary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Circle().fill(.green).frame(width: 8, height: 8)
                        Text("習得: \(done)")
                            .font(.caption)
                            .foregroundStyle(Color.jfTextSecondary)
                    }
                    HStack(spacing: 4) {
                        Circle().fill(.orange).frame(width: 8, height: 8)
                        Text("練習中: \(practicing)")
                            .font(.caption)
                            .foregroundStyle(Color.jfTextSecondary)
                    }
                    HStack(spacing: 4) {
                        Circle().fill(Color.jfTextTertiary.opacity(0.3)).frame(width: 8, height: 8)
                        Text("未着手: \(total - done - practicing)")
                            .font(.caption)
                            .foregroundStyle(Color.jfTextSecondary)
                    }
                }
            }
        }
        .padding(14)
        .glassCard()
    }

    // MARK: - Helpers

    private func calculateStreak() -> Int {
        let cal = Calendar.current
        let practiceDays = Set(journalStore.entries.map { cal.startOfDay(for: $0.date) })
        var streak = 0
        var day = cal.startOfDay(for: Date())
        while practiceDays.contains(day) {
            streak += 1
            day = cal.date(byAdding: .day, value: -1, to: day)!
        }
        return streak
    }
}
