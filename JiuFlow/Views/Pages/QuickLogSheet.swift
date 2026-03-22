import SwiftUI

/// Quick log sheet — choose what to record
struct QuickLogSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showPractice = false
    @State private var showRoll = false
    @State private var showWeight = false
    @State private var showVideoNote = false
    @State private var showCompResult = false
    @StateObject private var journalStore = JournalStore()
    @StateObject private var rollStore = RollStore()

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 14) {
                // Header
                VStack(spacing: 6) {
                    Text("何を記録する？")
                        .font(.title2.bold())
                        .foregroundStyle(Color.jfTextPrimary)
                    Text("タップして記録を始めよう")
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                }
                .padding(.top, 8)

                // Main cards
                logCard(icon: "figure.martial.arts", title: "練習を記録",
                        desc: "道着・ノーギ・ドリル", detail: "時間・技・気分・強度",
                        color: .green) { showPractice = true }

                logCard(icon: "person.2.fill", title: "スパーリングを記録",
                        desc: "ロールの詳細", detail: "相手・技・勝敗・防御",
                        color: .orange) { showRoll = true }

                logCard(icon: "scalemass.fill", title: "体重を記録",
                        desc: "今日の体重", detail: "階級管理・推移グラフ",
                        color: .mint) { showWeight = true }

                logCard(icon: "trophy.fill", title: "大会結果を記録",
                        desc: "試合の結果と反省", detail: "相手・結果・学び",
                        color: .yellow) { showCompResult = true }

                logCard(icon: "lightbulb.fill", title: "動画メモ",
                        desc: "観た動画の気づき", detail: "テクニック名・ポイント",
                        color: .purple) { showVideoNote = true }

                // Quick buttons
                VStack(alignment: .leading, spacing: 8) {
                    Text("ワンタップ記録")
                        .font(.caption.bold())
                        .foregroundStyle(Color.jfTextTertiary)
                    HStack(spacing: 8) {
                        quickButton("🥋 道着", .blue) {
                            var e = JournalEntry.new(); e.type = "gi"; e.duration = 60
                            journalStore.save(e); dismiss()
                        }
                        quickButton("🏃 ノーギ", .orange) {
                            var e = JournalEntry.new(); e.type = "nogi"; e.duration = 60
                            journalStore.save(e); dismiss()
                        }
                        quickButton("🔄 ドリル", .green) {
                            var e = JournalEntry.new(); e.type = "drill"; e.duration = 30
                            journalStore.save(e); dismiss()
                        }
                        quickButton("🤼 OM", .purple) {
                            var e = JournalEntry.new(); e.type = "open_mat"; e.duration = 60
                            journalStore.save(e); dismiss()
                        }
                    }
                }
            }
            .padding(20)
            .padding(.bottom, 20)
        }
        .background(Color.jfDarkBg)
        .navigationTitle("記録する")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") { dismiss() }
                    .foregroundStyle(Color.jfTextSecondary)
            }
        }
        .sheet(isPresented: $showPractice) {
            NavigationStack {
                JournalEntryEditView(store: journalStore, entry: .new(), isNew: true)
            }
        }
        .sheet(isPresented: $showRoll) {
            NavigationStack {
                RollEntryEditView(store: rollStore, entry: .new(), isNew: true)
            }
        }
        .sheet(isPresented: $showWeight) {
            NavigationStack {
                WeightTrackerView()
            }
        }
        .sheet(isPresented: $showCompResult) {
            NavigationStack {
                CompResultView(store: journalStore, onDismiss: { dismiss() })
            }
        }
        .sheet(isPresented: $showVideoNote) {
            NavigationStack {
                VideoNoteView(store: journalStore, onDismiss: { dismiss() })
            }
        }
    }

    // MARK: - Card

    private func logCard(icon: String, title: String, desc: String, detail: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(color)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.jfTextPrimary)
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(color.opacity(0.4))
            }
            .padding(12)
            .background(color.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(color.opacity(0.12), lineWidth: 1)
            )
        }
    }

    private func quickButton(_ label: String, _ color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption2.bold())
                .foregroundStyle(Color.jfTextSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(color.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

// MARK: - Competition Result View

struct CompResultView: View {
    @ObservedObject var store: JournalStore
    let onDismiss: () -> Void
    @State private var opponent = ""
    @State private var result = "win" // win, loss, draw
    @State private var method = "" // submission, points, dq, ref
    @State private var reflection = ""
    @State private var tournamentName = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("大会名")
                        .font(.caption.bold())
                        .foregroundStyle(Color.jfTextTertiary)
                    TextField("例: SJJJF東京オープン", text: $tournamentName)
                        .padding(10).background(Color.jfCardBg).foregroundStyle(Color.jfTextPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(14).glassCard()

                VStack(alignment: .leading, spacing: 8) {
                    Text("対戦相手")
                        .font(.caption.bold())
                        .foregroundStyle(Color.jfTextTertiary)
                    TextField("名前（任意）", text: $opponent)
                        .padding(10).background(Color.jfCardBg).foregroundStyle(Color.jfTextPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(14).glassCard()

                VStack(alignment: .leading, spacing: 8) {
                    Text("結果")
                        .font(.caption.bold())
                        .foregroundStyle(Color.jfTextTertiary)
                    HStack(spacing: 8) {
                        resultButton("🏆 勝ち", "win", .green)
                        resultButton("😤 負け", "loss", .red)
                        resultButton("🤝 引分", "draw", .gray)
                    }
                }
                .padding(14).glassCard()

                VStack(alignment: .leading, spacing: 8) {
                    Text("決まり手")
                        .font(.caption.bold())
                        .foregroundStyle(Color.jfTextTertiary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(["一本", "ポイント", "アドバンテージ", "レフェリー判定", "DQ", "RNC", "三角", "腕十字", "ギロチン", "足関節"], id: \.self) { m in
                                Button { method = m } label: {
                                    Text(m).font(.caption).padding(.horizontal, 10).padding(.vertical, 6)
                                        .background(method == m ? Color.jfRed : Color.jfCardBg)
                                        .foregroundStyle(method == m ? .white : Color.jfTextSecondary)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
                .padding(14).glassCard()

                VStack(alignment: .leading, spacing: 8) {
                    Text("反省・学び")
                        .font(.caption.bold())
                        .foregroundStyle(Color.jfTextTertiary)
                    TextEditor(text: $reflection)
                        .frame(minHeight: 80).scrollContentBackground(.hidden)
                        .background(Color.jfCardBg).foregroundStyle(Color.jfTextPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(14).glassCard()

                Button {
                    var e = JournalEntry.new()
                    e.type = "competition"
                    e.notes = "【\(tournamentName)】vs \(opponent)\n結果: \(result == "win" ? "勝ち" : result == "loss" ? "負け" : "引分") (\(method))\n\(reflection)"
                    store.save(e)
                    dismiss()
                    onDismiss()
                } label: {
                    Text("記録する").font(.headline).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(LinearGradient.jfRedGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(16).padding(.bottom, 20)
        }
        .background(Color.jfDarkBg)
        .navigationTitle("大会結果")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") { dismiss() }.foregroundStyle(Color.jfTextSecondary)
            }
        }
    }

    private func resultButton(_ label: String, _ value: String, _ color: Color) -> some View {
        Button { result = value } label: {
            Text(label).font(.subheadline.bold())
                .frame(maxWidth: .infinity).padding(.vertical, 10)
                .background(result == value ? color.opacity(0.2) : Color.jfCardBg)
                .foregroundStyle(result == value ? color : Color.jfTextSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(result == value ? color : Color.jfBorder, lineWidth: 1))
        }
    }
}

// MARK: - Video Note View

struct VideoNoteView: View {
    @ObservedObject var store: JournalStore
    let onDismiss: () -> Void
    @State private var videoTitle = ""
    @State private var keyPoints = ""
    @State private var techniques: [String] = []
    @State private var newTech = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("動画タイトル")
                        .font(.caption.bold())
                        .foregroundStyle(Color.jfTextTertiary)
                    TextField("例: 良蔵のクローズドガード #3", text: $videoTitle)
                        .padding(10).background(Color.jfCardBg).foregroundStyle(Color.jfTextPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(14).glassCard()

                VStack(alignment: .leading, spacing: 8) {
                    Text("学んだテクニック")
                        .font(.caption.bold())
                        .foregroundStyle(Color.jfTextTertiary)
                    HStack {
                        TextField("テクニック名", text: $newTech)
                            .padding(8).background(Color.jfCardBg).foregroundStyle(Color.jfTextPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        if !newTech.isEmpty {
                            Button { techniques.append(newTech); newTech = "" } label: {
                                Image(systemName: "plus.circle.fill").foregroundStyle(Color.jfRed)
                            }
                        }
                    }
                    if !techniques.isEmpty {
                        FlowLayout(spacing: 6) {
                            ForEach(techniques, id: \.self) { t in
                                HStack(spacing: 4) {
                                    Text(t).font(.caption)
                                    Button { techniques.removeAll { $0 == t } } label: {
                                        Image(systemName: "xmark").font(.system(size: 8))
                                    }
                                }
                                .foregroundStyle(.purple)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Color.purple.opacity(0.1)).clipShape(Capsule())
                            }
                        }
                    }
                }
                .padding(14).glassCard()

                VStack(alignment: .leading, spacing: 8) {
                    Text("気づき・ポイント")
                        .font(.caption.bold())
                        .foregroundStyle(Color.jfTextTertiary)
                    TextEditor(text: $keyPoints)
                        .frame(minHeight: 100).scrollContentBackground(.hidden)
                        .background(Color.jfCardBg).foregroundStyle(Color.jfTextPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(14).glassCard()

                Button {
                    var e = JournalEntry.new()
                    e.type = "drill"
                    e.duration = 0
                    e.techniques = techniques
                    e.notes = "📺 \(videoTitle)\n\(keyPoints)"
                    store.save(e)
                    dismiss()
                    onDismiss()
                } label: {
                    Text("メモを保存").font(.headline).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(LinearGradient.jfRedGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(16).padding(.bottom, 20)
        }
        .background(Color.jfDarkBg)
        .navigationTitle("動画メモ")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") { dismiss() }.foregroundStyle(Color.jfTextSecondary)
            }
        }
    }
}
