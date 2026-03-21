import SwiftUI

struct DiscoverTab: View {
    @EnvironmentObject var api: APIService

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    discoverItem(icon: "trophy.fill", title: "大会情報", desc: "最新の大会", color: .yellow) {
                        AnyView(TournamentsView().environmentObject(api))
                    }
                    discoverItem(icon: "gamecontroller.fill", title: "ゲームプラン", desc: "戦略テンプレ", color: .purple) {
                        AnyView(GamePlansView())
                    }
                    discoverItem(icon: "bubble.left.and.bubble.right.fill", title: "コミュニティ", desc: "フォーラム", color: .blue) {
                        AnyView(ForumView().environmentObject(api))
                    }
                    discoverItem(icon: "person.badge.shield.checkmark.fill", title: "コース", desc: "インストラクター", color: .orange) {
                        AnyView(InstructorsView().environmentObject(api))
                    }
                    discoverItem(icon: "graduationcap.fill", title: "指導者システム", desc: "5人の流派", color: .red) {
                        AnyView(InstructorSystemsView())
                    }
                    discoverItem(icon: "calendar.badge.clock", title: "クラス予約", desc: "道場予約", color: .green) {
                        AnyView(ReservationsView().environmentObject(api))
                    }
                    discoverItem(icon: "person.3.fill", title: "選手", desc: "アスリート", color: .pink) {
                        AnyView(AthletesTab().environmentObject(api))
                    }
                    discoverItem(icon: "newspaper.fill", title: "ニュース", desc: "最新情報", color: .cyan) {
                        AnyView(HomeTab().environmentObject(api))
                    }
                    discoverItem(icon: "text.book.closed.fill", title: "ブログ", desc: "記事", color: .indigo) {
                        AnyView(BlogView())
                    }
                    discoverItem(icon: "book.fill", title: "ガイド", desc: "初心者〜上級", color: .teal) {
                        AnyView(GuidesView())
                    }
                    discoverItem(icon: "chart.bar.fill", title: "ロードマップ", desc: "帯別カリキュラム", color: .purple) {
                        AnyView(RoadmapView())
                    }
                    discoverItem(icon: "mappin.and.ellipse", title: "会場情報", desc: "大会会場", color: .mint) {
                        AnyView(VenuesView())
                    }
                    discoverItem(icon: "yensign.circle.fill", title: "料金プラン", desc: "Founder/Regular", color: .yellow) {
                        AnyView(PricingView())
                    }
                    discoverItem(icon: "questionmark.circle.fill", title: "よくある質問", desc: "FAQ", color: .gray) {
                        AnyView(FAQView())
                    }
                    discoverItem(icon: "info.circle.fill", title: "JiuFlowについて", desc: "ミッション", color: .white) {
                        AnyView(AboutView())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .padding(.bottom, 40)
            }
            .background(Color.jfDarkBg)
            .navigationTitle("探す")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func discoverItem(icon: String, title: String, desc: String, color: Color, destination: () -> AnyView) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.body)
                        .foregroundStyle(color)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.caption.bold())
                        .foregroundStyle(Color.jfTextPrimary)
                        .lineLimit(1)
                    Text(desc)
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
