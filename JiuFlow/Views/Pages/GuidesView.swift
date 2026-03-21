import SwiftUI

struct GuidesView: View {
    private let guides = [
        GuideItem(id: "beginners", title: "初心者ガイド", icon: "person.badge.plus", color: .green,
                  description: "柔術を始める方へ", path: "/beginners"),
        GuideItem(id: "glossary", title: "用語集", icon: "character.book.closed.fill", color: .blue,
                  description: "柔術の専門用語を解説", path: "/glossary"),
        GuideItem(id: "belts", title: "帯のシステム", icon: "circle.hexagongrid.fill", color: .purple,
                  description: "白帯から黒帯までの道のり", path: "/belts"),
        GuideItem(id: "history", title: "柔術の歴史", icon: "clock.arrow.circlepath", color: .orange,
                  description: "ブラジリアン柔術の起源と発展", path: "/history"),
        GuideItem(id: "rules", title: "ルール解説", icon: "checkmark.shield.fill", color: .red,
                  description: "試合のルールとスコアリング", path: "/rules"),
        GuideItem(id: "training-tips", title: "トレーニングのコツ", icon: "lightbulb.fill", color: .yellow,
                  description: "効果的な練習方法", path: "/training-tips"),
        GuideItem(id: "etiquette", title: "道場マナー", icon: "hand.raised.fill", color: .indigo,
                  description: "道場での礼儀とエチケット", path: "/etiquette"),
        GuideItem(id: "benefits", title: "柔術のメリット", icon: "heart.fill", color: .pink,
                  description: "心身の健康への効果", path: "/benefits"),
        GuideItem(id: "curriculum", title: "カリキュラム", icon: "list.number", color: .teal,
                  description: "段階的な学習プラン", path: "/curriculum"),
        GuideItem(id: "guide", title: "総合ガイド", icon: "book.fill", color: .brown,
                  description: "柔術のすべてを網羅", path: "/guide"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 10) {
                    ForEach(guides) { guide in
                        GuideCard(guide: guide)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .padding(.bottom, 40)
            }
            .background(Color.jfDarkBg)
            .navigationTitle("ガイド")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct GuideItem: Identifiable {
    let id: String
    let title: String
    let icon: String
    let color: Color
    let description: String
    let path: String
}

struct GuideCard: View {
    let guide: GuideItem

    var body: some View {
        Link(destination: URL(string: "https://jiuflow-ssr.fly.dev\(guide.path)")!) {
            HStack(spacing: 14) {
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
                    Text(guide.description)
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(Color.jfTextTertiary)
            }
            .padding(12)
            .glassCard(cornerRadius: 14)
        }
    }
}
