import SwiftUI

struct RoadmapView: View {
    @State private var expandedBelt: String?
    @AppStorage("roadmap_progress") private var progressData: Data = Data()

    private var progress: [String: String] {
        (try? JSONDecoder().decode([String: String].self, from: progressData)) ?? [:]
    }

    private func setProgress(_ id: String, _ status: String) {
        var p = progress
        p[id] = status
        if let data = try? JSONEncoder().encode(p) { progressData = data }
    }

    private let belts: [(id: String, name: String, color: Color, emoji: String, items: [(id: String, category: String, name: String)])] = [
        ("white", "白帯", .white, "🤍", [
            ("w1", "エスケープ", "マウントエスケープ（橋と腰抜き）"),
            ("w2", "エスケープ", "サイドコントロールエスケープ"),
            ("w3", "エスケープ", "バックエスケープ"),
            ("w4", "ガード", "クローズドガードの基本"),
            ("w5", "パス", "クローズドガードブレイク"),
            ("w6", "サブミッション", "トライアングル（ガードから）"),
            ("w7", "サブミッション", "腕十字（ガードから）"),
            ("w8", "サブミッション", "オモプラッタ"),
            ("w9", "サブミッション", "リアネイキッドチョーク"),
            ("w10", "コントロール", "マウントポジション維持"),
            ("w11", "コントロール", "サイドコントロール基本"),
            ("w12", "テイクダウン", "シングルレッグ"),
            ("w13", "基礎", "受け身・ブレイクフォール"),
        ]),
        ("blue", "青帯", .blue, "💙", [
            ("b1", "ガード", "バタフライガード"),
            ("b2", "ガード", "ハーフガード（アンダーフック）"),
            ("b3", "ガード", "デラヒーバガード"),
            ("b4", "ガード", "スパイダーガード"),
            ("b5", "スイープ", "バタフライスイープ"),
            ("b6", "スイープ", "シザースイープ"),
            ("b7", "パス", "ニースライドパス"),
            ("b8", "パス", "トレアンドウパス"),
            ("b9", "サブミッション", "ギロチンチョーク"),
            ("b10", "サブミッション", "直足関節"),
            ("b11", "サブミッション", "ボーアンドアローチョーク"),
            ("b12", "テイクダウン", "ダブルレッグ"),
        ]),
        ("purple", "紫帯", .purple, "💜", [
            ("p1", "ガード", "ベリンボロ基本"),
            ("p2", "ガード", "50/50ガード"),
            ("p3", "ガード", "Xガード"),
            ("p4", "ガード", "ラッソーガード"),
            ("p5", "ガード", "ニーシールドハーフ"),
            ("p6", "ガード", "シングルレッグX（SLX）"),
            ("p7", "パス", "レッグドラッグパス"),
            ("p8", "パス", "クロスニーパス"),
            ("p9", "サブミッション", "インサイドヒールフック"),
            ("p10", "サブミッション", "ダースチョーク"),
            ("p11", "サブミッション", "アナコンダチョーク"),
            ("p12", "バックテイク", "タートルからバックテイク"),
            ("p13", "戦略", "コンペティションゲームプラン"),
        ]),
        ("brown", "茶帯", .brown, "🤎", [
            ("br1", "サブミッション", "アウトサイドヒールフック"),
            ("br2", "サブミッション", "膝十字"),
            ("br3", "サブミッション", "ふくらはぎ関節"),
            ("br4", "サブミッション", "足関節チェーン（連携）"),
            ("br5", "ガード", "ベリンボロ発展（バックテイク）"),
            ("br6", "戦略", "マイクロアジャストメント"),
        ]),
        ("black", "黒帯", .red, "🖤", [
            ("bk1", "戦略", "独自システム構築"),
            ("bk2", "戦略", "カウンターフロー"),
            ("bk3", "基礎", "シームレストランジション"),
            ("bk4", "成長", "教えることで技を深める"),
        ]),
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                ForEach(belts, id: \.id) { belt in
                    beltSection(belt)
                }
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .background(Color.jfDarkBg)
        .navigationTitle("ロードマップ")
        .navigationBarTitleDisplayMode(.large)
    }

    private func beltSection(_ belt: (id: String, name: String, color: Color, emoji: String, items: [(id: String, category: String, name: String)])) -> some View {
        let completed = belt.items.filter { progress[$0.id] == "done" }.count
        let pct = belt.items.isEmpty ? 0 : Int(Double(completed) / Double(belt.items.count) * 100)
        let isExpanded = expandedBelt == belt.id

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.35)) {
                    expandedBelt = isExpanded ? nil : belt.id
                }
            } label: {
                HStack(spacing: 12) {
                    Text(belt.emoji).font(.title2)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(belt.name)
                            .font(.headline)
                            .foregroundStyle(Color.jfTextPrimary)
                        Text("\(completed)/\(belt.items.count) 習得 (\(pct)%)")
                            .font(.caption)
                            .foregroundStyle(Color.jfTextTertiary)
                    }
                    Spacer()
                    // Progress ring
                    ZStack {
                        Circle().stroke(Color.jfBorder, lineWidth: 3).frame(width: 36, height: 36)
                        Circle().trim(from: 0, to: Double(pct) / 100)
                            .stroke(belt.color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 36, height: 36).rotationEffect(.degrees(-90))
                        Text("\(pct)%").font(.system(size: 9, weight: .bold).monospacedDigit()).foregroundStyle(Color.jfTextTertiary)
                    }
                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(Color.jfTextTertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(14)
            }

            if isExpanded {
                Divider().background(Color.jfBorder).padding(.horizontal, 14)
                VStack(spacing: 0) {
                    ForEach(belt.items, id: \.id) { item in
                        let status = progress[item.id] ?? "not_started"
                        HStack(spacing: 12) {
                            Button {
                                let next = status == "not_started" ? "practicing" : status == "practicing" ? "done" : "not_started"
                                setProgress(item.id, next)
                            } label: {
                                Image(systemName: status == "done" ? "checkmark.circle.fill" : status == "practicing" ? "arrow.triangle.2.circlepath.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(status == "done" ? .green : status == "practicing" ? .orange : Color.jfTextTertiary.opacity(0.3))
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name).font(.subheadline).foregroundStyle(Color.jfTextPrimary)
                                Text(item.category).font(.caption2).foregroundStyle(belt.color)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 14).padding(.vertical, 8)
                    }
                }
            }
        }
        .glassCard()
    }
}
