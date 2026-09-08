import SwiftUI

struct GuidesView: View {
    private let guides: [(id: String, title: String, icon: String, color: Color, sections: [(title: String, content: String)])] = [
        ("beginners", tr("初心者ガイド"), "person.badge.plus", .green, [
            (tr("ブラジリアン柔術（BJJ）とは？"), tr("テクニックとレバレッジを使って相手をコントロールする寝技中心の格闘技。「人間チェス」と呼ばれ、4歳から70代まで世界中で1,500万人以上が練習しています。")),
            (tr("他の格闘技との違い"), tr("最大の特徴は打撃がないこと。パンチやキックがなく初心者でも安心。「タップ」文化により怪我リスクを自分でコントロールできます。")),
            (tr("道場の選び方"), tr("①自宅から30分以内 ②体験で雰囲気確認 ③スケジュール充実 ④インストラクターは茶帯以上 ⑤月謝8,000〜15,000円 ⑥同年代の会員構成")),
            (tr("必要な道具"), tr("道衣（ギ）10,000〜25,000円、マウスピース1,000〜5,000円、ラッシュガード3,000〜8,000円。初期費用は約25,000〜40,000円。")),
            (tr("初日の流れ"), tr("①受付・着替え（15分前到着）→ ②ウォームアップ（10〜15分）→ ③テクニック練習（30〜40分）→ ④スパーリング（見学OK）→ ⑤クールダウン")),
            (tr("初心者のミス"), tr("力に頼りすぎ・タップためらい・技の詰め込み・毎日通い燃え尽き・上級者と比較。週2〜3回、2〜3個の技の反復が最適。")),
            (tr("最初の1ヶ月"), tr("1週目:雰囲気に慣れる → 2週目:クローズドガード基本 → 3週目:スパーリングで試す → 4週目:整理・習慣化")),
        ]),
        ("glossary", tr("用語集"), "character.book.closed.fill", .blue, [
            (tr("ガード"), tr("下のポジションから相手をコントロールする体勢。クローズド、ハーフ、バタフライ、DLR、スパイダー等がある。")),
            (tr("マウント"), tr("相手の上に座った状態。柔術で最も支配的なポジションの一つ。")),
            (tr("サイドコントロール"), tr("相手の横から体重をかけて押さえつけるポジション。パスガード後の基本ポジション。")),
            (tr("パスガード"), tr("相手のガード（足の防御）を越えてコントロールポジションに移行すること。")),
            (tr("スイープ"), tr("下のポジションから相手を倒して上を取ること。ポイント獲得。")),
            (tr("サブミッション"), tr("関節技や絞め技で相手をタップ（降参）させる技術。一本勝ち。")),
            (tr("タップ"), tr("相手に降参を示すサイン。手で叩くか口頭で申告。安全の基本。")),
            (tr("エビ（シュリンプ）"), tr("横向きに腰を切って移動する基本動作。エスケープの基礎。")),
            (tr("ブリッジ"), tr("腰を持ち上げて相手を跳ね上げる動作。マウントエスケープの基本。")),
            (tr("テイクダウン"), tr("立ち技から相手を倒してグラウンドに持ち込むこと。")),
        ]),
        ("belts", tr("帯システム"), "circle.hexagongrid.fill", .purple, [
            (tr("白帯"), tr("全ての始まり。基本ポジション、エスケープ、2〜3個のサブミッションを覚える。平均1〜2年。")),
            (tr("青帯"), tr("中級者の入口。全ポジションの理解、攻防のバリエーション。平均2〜3年（IBJJF最低2年在籍）。")),
            (tr("紫帯"), tr("上級者。自分のゲームプランを持ち、多様な状況に対応できる。平均1.5〜3年（IBJJF最低1.5年）。")),
            (tr("茶帯"), tr("エキスパート。技術の洗練と指導能力の確立。平均1〜2年（IBJJF最低1年）。")),
            (tr("黒帯"), tr("マスター。独自のシステムと深い理解。白帯から平均10〜15年。ここから先も成長は続く。")),
        ]),
        ("history", tr("柔術の歴史"), "clock.arrow.circlepath", .orange, [
            (tr("起源"), tr("日本の柔道家・前田光世が1914年にブラジルに渡り、グレイシー家に技術を伝えたのが始まり。")),
            (tr("グレイシー家の発展"), tr("エリオ・グレイシーが体格差を克服する技術を体系化。寝技に特化した「グレイシー柔術」を確立。")),
            (tr("UFC黎明期"), tr("1993年のUFC1でホイス・グレイシーが打撃系格闘家を次々と破り、BJJの有効性を世界に証明。")),
            (tr("競技化"), tr("IBJJFが設立され、世界選手権（ムンジアル）が開催。ADCC等のノーギ大会も発展。")),
            (tr("現代柔術"), tr("レッグロック革命（ダナハー/ゴードン・ライアン）、ベリンボロ（メンデス兄弟）等でさらに進化中。")),
        ]),
        ("rules", tr("ルール解説"), "checkmark.shield.fill", .red, [
            (tr("IBJJF基本ルール"), tr("道着（ギ）あり。5〜10分の試合時間。ポイント＋サブミッションで勝敗を決定。")),
            (tr("ポイント"), tr("テイクダウン:2点、スイープ:2点、パスガード:3点、マウント:4点、バック:4点。")),
            (tr("アドバンテージ"), tr("技が「ほぼ」決まった場合に付与。ポイント同点時の判定に使用。")),
            (tr("禁止技（帯別）"), tr("白帯:足関節禁止。青帯:ストレートフットロック可。茶帯以上:ヒールフック可（IBJJF）。")),
            (tr("ADCCルール"), tr("ノーギ。前半ポイントなし、後半ポイントあり。ヒールフック・膝十字全帯で可。")),
        ]),
        ("training-tips", tr("トレーニングのコツ"), "lightbulb.fill", .yellow, [
            (tr("週の練習量"), tr("白帯は週2〜3回が最適。多すぎると燃え尽き、少なすぎると上達が遅い。")),
            (tr("復習の重要性"), tr("練習後にノートやアプリで学んだ技を記録。翌日に頭の中で反復するだけでも効果大。")),
            (tr("スパーリングの心構え"), tr("勝ち負けより「技を試す場」と考える。新しい技を試す勇気が上達の鍵。")),
            (tr("コンディショニング"), tr("柔術の体力は柔術で作る。補助的にランニングやヨガも効果的。")),
            (tr("怪我の予防"), tr("ウォームアップ必須。タップは早めに。痛みを感じたら無理しない。")),
        ]),
        ("etiquette", tr("道場マナー"), "hand.raised.fill", .indigo, [
            (tr("基本マナー"), tr("挨拶（お願いします/ありがとうございました）。マットに上がる前に一礼。サンダル着用で清潔維持。")),
            (tr("衛生"), tr("爪は短く。道衣は毎回洗濯。皮膚トラブルがあれば練習を休む。")),
            (tr("スパーリング"), tr("力加減60〜70%。テクニック重視。周囲に注意。上級者には敬意を。")),
            (tr("指導者への敬意"), tr("質問は積極的に。ただし指導中は静かに聞く。帯を結び直す時は壁に向かって。")),
        ]),
        ("benefits", tr("柔術のメリット"), "heart.fill", .pink, [
            (tr("フィットネス"), tr("全身運動。1時間で500〜700kcal消費。筋力・柔軟性・持久力が向上。")),
            (tr("メンタル"), tr("問題解決能力の向上。ストレス解消。自信と冷静さを養う。")),
            (tr("社会性"), tr("年齢・職業・国籍を超えた仲間。大人になってからの友情が生まれる場所。")),
            (tr("護身術"), tr("実戦的な護身技術。距離の取り方、グラウンドでのコントロール。")),
        ]),
    ]

    @State private var expandedGuide: String?

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    ForEach(guides, id: \.id) { guide in
                        guideCard(guide)
                    }
                }
                .padding(16)
                .padding(.bottom, 40)
            }
            .background(Color.jfDarkBg)
            .navigationTitle(tr("ガイド"))
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func guideCard(_ guide: (id: String, title: String, icon: String, color: Color, sections: [(title: String, content: String)])) -> some View {
        let isExpanded = expandedGuide == guide.id

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.35)) {
                    expandedGuide = isExpanded ? nil : guide.id
                }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(guide.color.opacity(0.12))
                            .frame(width: 44, height: 44)
                        Image(systemName: guide.icon)
                            .font(.body)
                            .foregroundStyle(guide.color)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(guide.title)
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.jfTextPrimary)
                        Text("\(guide.sections.count)セクション")
                            .font(.caption2)
                            .foregroundStyle(Color.jfTextTertiary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(14)
            }

            if isExpanded {
                Divider().background(Color.jfBorder).padding(.horizontal, 14)

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(guide.sections.enumerated()), id: \.offset) { _, section in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(section.title)
                                .font(.subheadline.bold())
                                .foregroundStyle(guide.color)
                            Text(section.content)
                                .font(.caption)
                                .foregroundStyle(Color.jfTextSecondary)
                                .lineSpacing(4)
                        }
                    }
                }
                .padding(14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .glassCard()
    }
}
