import SwiftUI

struct DiscoverTab: View {
    @EnvironmentObject var api: APIService

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Grid of features
                    let items: [(String, String, String, Color, AnyView)] = [
                        ("trophy.fill", "大会情報", "最新の大会", .yellow, AnyView(TournamentsView().environmentObject(api))),
                        ("gamecontroller.fill", "ゲームプラン", "戦略テンプレート", .purple, AnyView(GamePlansView())),
                        ("bubble.left.and.bubble.right.fill", "コミュニティ", "フォーラム", .blue, AnyView(ForumView().environmentObject(api))),
                        ("person.badge.shield.checkmark.fill", "インストラクター", "コース", .orange, AnyView(InstructorsView().environmentObject(api))),
                        ("graduationcap.fill", "指導者システム", "5人の流派", .red, AnyView(InstructorSystemsView())),
                        ("calendar.badge.clock", "クラス予約", "道場予約", .green, AnyView(ReservationsView().environmentObject(api))),
                        ("text.book.closed.fill", "ブログ", "記事", .indigo, AnyView(BlogView())),
                        ("book.fill", "ガイド", "初心者〜上級", .teal, AnyView(GuidesView())),
                        ("person.3.fill", "選手", "アスリート", .pink, AnyView(AthletesTab().environmentObject(api))),
                        ("newspaper.fill", "ニュース", "最新情報", .cyan, AnyView(HomeTab().environmentObject(api))),
                    ]

                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        ForEach(0..<items.count, id: \.self) { i in
                            NavigationLink {
                                items[i].4
                            } label: {
                                HStack(spacing: 10) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(items[i].3.opacity(0.12))
                                            .frame(width: 36, height: 36)
                                        Image(systemName: items[i].0)
                                            .font(.body)
                                            .foregroundStyle(items[i].3)
                                    }
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(items[i].1)
                                            .font(.caption.bold())
                                            .foregroundStyle(Color.jfTextPrimary)
                                            .lineLimit(1)
                                        Text(items[i].2)
                                            .font(.caption2)
                                            .foregroundStyle(Color.jfTextTertiary)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                }
                                .padding(10)
                                .glassCard(cornerRadius: 12)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 8)
                .padding(.bottom, 40)
            }
            .background(Color.jfDarkBg)
            .navigationTitle("探す")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func discoverCard(icon: String, title: String, desc: String, color: Color) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(color.opacity(0.12))
                    .frame(width: 56, height: 56)
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.jfTextPrimary)
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(Color.jfTextTertiary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.jfTextTertiary)
        }
        .padding(16)
        .glassCard()
        .padding(.horizontal, 16)
    }
}
