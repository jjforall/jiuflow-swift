import SwiftUI

/// Quick log sheet — choose what to record
struct QuickLogSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showPractice = false
    @State private var showRoll = false
    @StateObject private var journalStore = JournalStore()
    @StateObject private var rollStore = RollStore()

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 6) {
                Text("何を記録する？")
                    .font(.title2.bold())
                    .foregroundStyle(Color.jfTextPrimary)
                Text("練習やスパーリングの記録を残そう")
                    .font(.caption)
                    .foregroundStyle(Color.jfTextTertiary)
            }
            .padding(.top, 8)

            // Practice card
            Button { showPractice = true } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.green.opacity(0.12))
                            .frame(width: 56, height: 56)
                        Image(systemName: "figure.martial.arts")
                            .font(.title2)
                            .foregroundStyle(.green)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("練習を記録")
                            .font(.headline)
                            .foregroundStyle(Color.jfTextPrimary)
                        Text("道着・ノーギ・ドリル・試合")
                            .font(.caption)
                            .foregroundStyle(Color.jfTextTertiary)
                        HStack(spacing: 4) {
                            Image(systemName: "clock").font(.caption2)
                            Text("時間・タイプ・気分・強度")
                                .font(.caption2)
                        }
                        .foregroundStyle(Color.jfTextTertiary.opacity(0.7))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Color.green.opacity(0.5))
                }
                .padding(16)
                .background(Color.green.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.green.opacity(0.15), lineWidth: 1)
                )
            }

            // Roll card
            Button { showRoll = true } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.orange.opacity(0.12))
                            .frame(width: 56, height: 56)
                        Image(systemName: "sportscourt")
                            .font(.title2)
                            .foregroundStyle(.orange)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ロールを記録")
                            .font(.headline)
                            .foregroundStyle(Color.jfTextPrimary)
                        Text("スパーリングの詳細記録")
                            .font(.caption)
                            .foregroundStyle(Color.jfTextTertiary)
                        HStack(spacing: 4) {
                            Image(systemName: "person.2").font(.caption2)
                            Text("相手・技・勝敗・防御")
                                .font(.caption2)
                        }
                        .foregroundStyle(Color.jfTextTertiary.opacity(0.7))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Color.orange.opacity(0.5))
                }
                .padding(16)
                .background(Color.orange.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange.opacity(0.15), lineWidth: 1)
                )
            }

            // Quick type buttons
            VStack(alignment: .leading, spacing: 8) {
                Text("ワンタップ記録")
                    .font(.caption.bold())
                    .foregroundStyle(Color.jfTextTertiary)
                HStack(spacing: 8) {
                    quickTypeButton("道着60分", "tshirt.fill", .blue) {
                        var e = JournalEntry.new()
                        e.type = "gi"; e.duration = 60
                        journalStore.save(e); dismiss()
                    }
                    quickTypeButton("ノーギ60分", "figure.run", .orange) {
                        var e = JournalEntry.new()
                        e.type = "nogi"; e.duration = 60
                        journalStore.save(e); dismiss()
                    }
                    quickTypeButton("ドリル30分", "arrow.triangle.2.circlepath", .green) {
                        var e = JournalEntry.new()
                        e.type = "drill"; e.duration = 30
                        journalStore.save(e); dismiss()
                    }
                }
            }

            Spacer()
        }
        .padding(20)
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
    }

    private func quickTypeButton(_ label: String, _ icon: String, _ color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(color)
                Text(label)
                    .font(.caption2.bold())
                    .foregroundStyle(Color.jfTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
