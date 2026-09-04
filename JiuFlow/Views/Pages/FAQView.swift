import SwiftUI

struct FAQView: View {
    @State private var expandedId: String?

    private let faqs: [(id: String, q: String, a: String)] = [
        ("1", tr("JiuFlowとは何ですか？"), tr("ブラジリアン柔術（BJJ）のための総合プラットフォームです。道場検索、テクニック動画、大会情報、選手プロフィールを提供しています。")),
        ("2", tr("利用は無料ですか？"), tr("道場検索、大会情報、読み物コンテンツは無料です。テクニック動画のフルアクセスは有料で、初月無料トライアルがあります。")),
        ("3", tr("料金プランは？"), tr("Founderプラン月980円、Regularプラン月2,900円、年間プラン29,000円があります。")),
        ("4", tr("いつでも解約できますか？"), tr("はい、いつでも解約可能です。違約金・手数料はかかりません。")),
        ("5", tr("誰が監修していますか？"), tr("世界チャンピオンの村田良蔵をはじめ、国内外のトップインストラクターが監修しています。")),
        ("6", tr("何歳から始められますか？"), tr("キッズクラスは4〜5歳から。大人は何歳からでもOKです。60代・70代の実践者もいます。")),
        ("7", tr("帯の色の順番は？"), tr("白帯→青帯→紫帯→茶帯→黒帯の順です。黒帯到達まで平均10〜15年かかります。")),
        ("8", tr("柔術と柔道の違いは？"), tr("柔道は投げ技中心、BJJは寝技中心です。BJJはグラウンドでのコントロールとサブミッションに特化しています。")),
        ("9", tr("運動経験がなくても大丈夫？"), tr("もちろんです。体力は練習するうちに自然と付いてきます。")),
        ("10", tr("怪我のリスクは？"), tr("打撃がないため怪我リスクは比較的低いです。タップの文化が安全を確保しています。")),
        ("11", tr("女性でも始められますか？"), tr("はい。体格差を技術で補えるBJJは女性にもおすすめです。")),
        ("12", tr("道場選びのポイントは？"), tr("通いやすさ、体験での雰囲気、インストラクターの経歴、スケジュール、月謝が重要です。")),
        ("13", tr("動画は何本ですか？"), tr("現在200本以上を公開中で、毎月追加しています。")),
        ("14", tr("アカウント削除したい場合は？"), tr("設定 > アカウントを削除 から、アプリ内でいつでも削除できます（練習記録・サブスク情報などのデータも完全に削除されます）。")),
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                ForEach(faqs, id: \.id) { faq in
                    faqCard(faq)
                }
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .background(Color.jfDarkBg)
        .navigationTitle(tr("よくある質問"))
        .navigationBarTitleDisplayMode(.large)
    }

    // ForEach 内に全ビューを展開すると body 全体の型推論がタイムアウトするため、
    // 1件分をサブビュー関数に切り出して式を分割する。
    @ViewBuilder
    private func faqCard(_ faq: (id: String, q: String, a: String)) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    expandedId = expandedId == faq.id ? nil : faq.id
                }
            } label: {
                HStack(spacing: 10) {
                    Text("Q")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.jfRed)
                        .clipShape(Circle())
                    Text(faq.q)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.jfTextPrimary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                        .rotationEffect(.degrees(expandedId == faq.id ? 90 : 0))
                }
                .padding(12)
            }

            if expandedId == faq.id {
                Text(faq.a)
                    .font(.subheadline)
                    .foregroundStyle(Color.jfTextSecondary)
                    .lineSpacing(4)
                    .padding(.horizontal, 46)
                    .padding(.bottom, 12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .glassCard(cornerRadius: 14)
    }
}
