import SwiftUI

struct RoadmapView: View {
    @State private var expandedBelt: String?
    @State private var searchText = ""
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
        ("white", tr("白帯"), .white, "🤍", [
            ("w1", tr("エスケープ"), tr("マウントエスケープ（橋と腰抜き）")),
            ("w2", tr("エスケープ"), tr("サイドコントロールエスケープ")),
            ("w3", tr("エスケープ"), tr("バックエスケープ")),
            ("w4", tr("ガード"), tr("クローズドガードの基本")),
            ("w5", tr("パス"), tr("クローズドガードブレイク")),
            ("w6", tr("サブミッション"), tr("トライアングル（ガードから）")),
            ("w7", tr("サブミッション"), tr("腕十字（ガードから）")),
            ("w8", tr("サブミッション"), tr("オモプラッタ")),
            ("w9", tr("サブミッション"), tr("リアネイキッドチョーク")),
            ("w10", tr("コントロール"), tr("マウントポジション維持")),
            ("w11", tr("コントロール"), tr("サイドコントロール基本")),
            ("w12", tr("テイクダウン"), tr("シングルレッグ")),
            ("w13", tr("基礎"), tr("受け身・ブレイクフォール")),
        ]),
        ("blue", tr("青帯"), .blue, "💙", [
            ("b1", tr("ガード"), tr("バタフライガード")),
            ("b2", tr("ガード"), tr("ハーフガード（アンダーフック）")),
            ("b3", tr("ガード"), tr("デラヒーバガード")),
            ("b4", tr("ガード"), tr("スパイダーガード")),
            ("b5", tr("スイープ"), tr("バタフライスイープ")),
            ("b6", tr("スイープ"), tr("シザースイープ")),
            ("b7", tr("パス"), tr("ニースライドパス")),
            ("b8", tr("パス"), tr("トレアンドウパス")),
            ("b9", tr("サブミッション"), tr("ギロチンチョーク")),
            ("b10", tr("サブミッション"), tr("直足関節")),
            ("b11", tr("サブミッション"), tr("ボーアンドアローチョーク")),
            ("b12", tr("テイクダウン"), tr("ダブルレッグ")),
        ]),
        ("purple", tr("紫帯"), .purple, "💜", [
            ("p1", tr("ガード"), tr("ベリンボロ基本")),
            ("p2", tr("ガード"), tr("50/50ガード")),
            ("p3", tr("ガード"), tr("Xガード")),
            ("p4", tr("ガード"), tr("ラッソーガード")),
            ("p5", tr("ガード"), tr("ニーシールドハーフ")),
            ("p6", tr("ガード"), tr("シングルレッグX（SLX）")),
            ("p7", tr("パス"), tr("レッグドラッグパス")),
            ("p8", tr("パス"), tr("クロスニーパス")),
            ("p9", tr("サブミッション"), tr("インサイドヒールフック")),
            ("p10", tr("サブミッション"), tr("ダースチョーク")),
            ("p11", tr("サブミッション"), tr("アナコンダチョーク")),
            ("p12", tr("バックテイク"), tr("タートルからバックテイク")),
            ("p13", tr("戦略"), tr("コンペティションゲームプラン")),
        ]),
        ("brown", tr("茶帯"), .brown, "🤎", [
            ("br1", tr("サブミッション"), tr("アウトサイドヒールフック")),
            ("br2", tr("サブミッション"), tr("膝十字")),
            ("br3", tr("サブミッション"), tr("ふくらはぎ関節")),
            ("br4", tr("サブミッション"), tr("足関節チェーン（連携）")),
            ("br5", tr("ガード"), tr("ベリンボロ発展（バックテイク）")),
            ("br6", tr("戦略"), tr("マイクロアジャストメント")),
        ]),
        ("black", tr("黒帯"), .red, "🖤", [
            ("bk1", tr("戦略"), tr("独自システム構築")),
            ("bk2", tr("戦略"), tr("カウンターフロー")),
            ("bk3", tr("基礎"), tr("シームレストランジション")),
            ("bk4", tr("成長"), tr("教えることで技を深める")),
        ]),
    ]

    private var allFilteredItems: [(item: (id: String, category: String, name: String), beltName: String, beltColor: Color)] {
        let query = searchText.lowercased()
        return belts.flatMap { belt in
            belt.items
                .filter { $0.name.lowercased().contains(query) || $0.category.lowercased().contains(query) }
                .map { (item: $0, beltName: belt.name, beltColor: belt.color) }
        }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                if searchText.isEmpty {
                    ForEach(belts, id: \.id) { belt in
                        beltSection(belt)
                    }
                } else {
                    // Flattened search results
                    if allFilteredItems.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 36))
                                .foregroundStyle(Color.jfTextTertiary.opacity(0.3))
                            Text(trf("「%@」に一致する技が見つかりません", searchText))
                                .font(.subheadline)
                                .foregroundStyle(Color.jfTextTertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    } else {
                        ForEach(allFilteredItems, id: \.item.id) { result in
                            let status = progress[result.item.id] ?? "not_started"
                            HStack(spacing: 12) {
                                Button {
                                    let next = status == "not_started" ? "practicing" : status == "practicing" ? "done" : "not_started"
                                    setProgress(result.item.id, next)
                                } label: {
                                    Image(systemName: status == "done" ? "checkmark.circle.fill" : status == "practicing" ? "arrow.triangle.2.circlepath.circle.fill" : "circle")
                                        .font(.title3)
                                        .foregroundStyle(status == "done" ? .green : status == "practicing" ? .orange : Color.jfTextTertiary.opacity(0.3))
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(result.item.name).font(.subheadline).foregroundStyle(Color.jfTextPrimary)
                                    HStack(spacing: 6) {
                                        Text(result.item.category).font(.caption2).foregroundStyle(result.beltColor)
                                        Text(result.beltName).font(.caption2).foregroundStyle(Color.jfTextTertiary)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .glassCard()
                        }
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .background(Color.jfDarkBg)
        .navigationTitle(tr("ロードマップ"))
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: tr("テクニックを検索"))
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
                        Text(trf("%ld/%ld 習得 (%ld%%)", completed, belt.items.count, pct))
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
