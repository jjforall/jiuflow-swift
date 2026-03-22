import SwiftUI

struct DiscoverTab: View {
    @EnvironmentObject var api: APIService

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    // Hero banners
                    heroSection

                    // Grid
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
                    discoverItem(icon: "arrow.triangle.branch", title: "系統図", desc: "師弟関係ツリー", color: .purple) {
                        AnyView(LineageTreeView().environmentObject(api))
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
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
            .background(Color.jfDarkBg)
            .navigationTitle("探す")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 12) {
            // Map banner
            NavigationLink {
                FlowTab()
            } label: {
                heroBanner(
                    icon: "arrow.triangle.branch",
                    title: "テクニックマップ",
                    desc: "全237テクニックの繋がりを可視化",
                    gradient: [Color.blue.opacity(0.3), Color.purple.opacity(0.2)],
                    accent: .blue
                )
            }

            // Game plan banner
            NavigationLink {
                GamePlansView()
            } label: {
                heroBanner(
                    icon: "checklist",
                    title: "ゲームプランを作る",
                    desc: "良蔵システム等のテンプレートから自分の戦略を設計",
                    gradient: [Color.purple.opacity(0.3), Color.red.opacity(0.2)],
                    accent: .purple
                )
            }

            // AI Ryozo
            NavigationLink {
                AIRyozoView()
            } label: {
                heroBanner(
                    icon: "brain.head.profile",
                    title: "AI良蔵に聞く",
                    desc: "テクニック・戦略・練習メニューなんでも相談",
                    gradient: [Color.red.opacity(0.3), Color.orange.opacity(0.2)],
                    accent: .jfRed
                )
            }
        }
        .padding(.horizontal, 16)
    }

    private func heroBanner(icon: String, title: String, desc: String, gradient: [Color], accent: Color) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.15))
                    .frame(width: 52, height: 52)
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(accent)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.jfTextPrimary)
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(Color.jfTextTertiary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(accent.opacity(0.6))
        }
        .padding(14)
        .background(
            LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accent.opacity(0.2), lineWidth: 1)
        )
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
