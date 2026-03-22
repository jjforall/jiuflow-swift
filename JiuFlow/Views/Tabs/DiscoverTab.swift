import SwiftUI

struct DiscoverTab: View {
    @EnvironmentObject var api: APIService
    @EnvironmentObject var lang: LanguageManager
    @State private var showSearch = false

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // Hero banners
                    heroSection

                    // Training section
                    discoverSection(title: lang.t("トレーニング", en: "Training"), icon: "figure.martial.arts") {
                        LazyVGrid(columns: gridColumns, spacing: 12) {
                            discoverItem(icon: "gamecontroller.fill", title: lang.t("ゲームプラン", en: "Game Plans"), desc: lang.t("戦略テンプレ", en: "Strategy"), color: .purple) {
                                AnyView(GamePlansView())
                            }
                            discoverItem(icon: "chart.bar.fill", title: lang.t("ロードマップ", en: "Roadmap"), desc: lang.t("帯別カリキュラム", en: "Belt curriculum"), color: .purple) {
                                AnyView(RoadmapView())
                            }
                            discoverItem(icon: "graduationcap.fill", title: lang.t("指導者システム", en: "Instructor Systems"), desc: lang.t("5人の流派", en: "5 styles"), color: .red) {
                                AnyView(InstructorSystemsView())
                            }
                            discoverItem(icon: "person.badge.shield.checkmark.fill", title: lang.t("コース", en: "Courses"), desc: lang.t("インストラクター", en: "Instructors"), color: .orange) {
                                AnyView(InstructorsView().environmentObject(api))
                            }
                        }
                    }

                    // Community section
                    discoverSection(title: lang.t("コミュニティ", en: "Community"), icon: "person.3.fill") {
                        LazyVGrid(columns: gridColumns, spacing: 12) {
                            discoverItem(icon: "bubble.left.and.bubble.right.fill", title: lang.t("コミュニティ", en: "Forum"), desc: lang.t("フォーラム", en: "Discussions"), color: .blue) {
                                AnyView(ForumView().environmentObject(api))
                            }
                            discoverItem(icon: "person.3.fill", title: lang.t("選手", en: "Athletes"), desc: lang.t("アスリート", en: "Profiles"), color: .pink) {
                                AnyView(AthletesTab().environmentObject(api))
                            }
                            discoverItem(icon: "newspaper.fill", title: lang.t("ニュース", en: "News"), desc: lang.t("最新情報", en: "Latest"), color: .cyan) {
                                AnyView(HomeTab().environmentObject(api))
                            }
                            discoverItem(icon: "text.book.closed.fill", title: lang.t("ブログ", en: "Blog"), desc: lang.t("記事", en: "Articles"), color: .indigo) {
                                AnyView(BlogView())
                            }
                        }
                    }

                    // Info section
                    discoverSection(title: lang.t("情報", en: "Info"), icon: "info.circle.fill") {
                        LazyVGrid(columns: gridColumns, spacing: 12) {
                            discoverItem(icon: "trophy.fill", title: lang.t("大会情報", en: "Tournaments"), desc: lang.t("最新の大会", en: "Schedule"), color: .yellow) {
                                AnyView(TournamentsView().environmentObject(api))
                            }
                            discoverItem(icon: "calendar.badge.clock", title: lang.t("クラス予約", en: "Book Class"), desc: lang.t("道場予約", en: "Reserve"), color: .green) {
                                AnyView(ReservationsView().environmentObject(api))
                            }
                            discoverItem(icon: "mappin.and.ellipse", title: lang.t("会場情報", en: "Venues"), desc: lang.t("大会会場", en: "Locations"), color: .mint) {
                                AnyView(VenuesView())
                            }
                            discoverItem(icon: "book.fill", title: lang.t("ガイド", en: "Guides"), desc: lang.t("初心者〜上級", en: "All levels"), color: .teal) {
                                AnyView(GuidesView())
                            }
                        }
                    }

                    // SJJJF / ASJJF section
                    discoverSection(title: "SJJJF / ASJJF", icon: "person.text.rectangle") {
                        LazyVGrid(columns: gridColumns, spacing: 12) {
                            discoverItem(icon: "person.crop.rectangle", title: lang.t("会員証", en: "Member Card"), desc: "SJJJF/ASJJF", color: .blue) {
                                AnyView(SjjjfMemberCardView().environmentObject(api))
                            }
                            discoverItem(icon: "trophy.fill", title: lang.t("ランキング", en: "Rankings"), desc: lang.t("ポイント順位", en: "Points"), color: .yellow) {
                                AnyView(RankingsView().environmentObject(api))
                            }
                            discoverItem(icon: "bag.fill", title: lang.t("公式ショップ", en: "Official Shop"), desc: lang.t("道衣・グッズ", en: "Gi & Goods"), color: .orange) {
                                AnyView(ShopView().environmentObject(api))
                            }
                            discoverItem(icon: "video.fill", title: lang.t("ライブ配信", en: "Live Streams"), desc: lang.t("大会中継", en: "Tournament"), color: .red) {
                                AnyView(LiveStreamView().environmentObject(api))
                            }
                        }
                    }

                    // Other section
                    discoverSection(title: lang.t("その他", en: "More"), icon: "ellipsis.circle.fill") {
                        LazyVGrid(columns: gridColumns, spacing: 12) {
                            discoverItem(icon: "yensign.circle.fill", title: lang.t("料金プラン", en: "Pricing"), desc: "Founder/Regular", color: .yellow) {
                                AnyView(PricingView())
                            }
                            discoverItem(icon: "questionmark.circle.fill", title: lang.t("よくある質問", en: "FAQ"), desc: "FAQ", color: .gray) {
                                AnyView(FAQView())
                            }
                            discoverItem(icon: "info.circle.fill", title: lang.t("JiuFlowについて", en: "About JiuFlow"), desc: lang.t("ミッション", en: "Mission"), color: .white) {
                                AnyView(AboutView())
                            }
                            discoverItem(icon: "arrow.triangle.branch", title: lang.t("系統図", en: "Lineage Tree"), desc: lang.t("師弟関係ツリー", en: "Master-student"), color: .purple) {
                                AnyView(LineageTreeView().environmentObject(api))
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
            .background(Color.jfDarkBg)
            .navigationTitle(lang.t("探す", en: "Discover"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        UnifiedSearchView()
                            .environmentObject(api)
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Color.jfTextSecondary)
                    }
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            FeedbackButton(page: "探す")
        }
    }

    // MARK: - Section Builder

    private func discoverSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: title, icon: icon)
                .padding(.horizontal, 16)
            content()
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 12) {
            NavigationLink {
                FlowTab()
            } label: {
                heroBanner(
                    icon: "arrow.triangle.branch",
                    title: lang.t("テクニックマップ", en: "Technique Map"),
                    desc: lang.t("全237テクニックの繋がりを可視化", en: "Visualize 237+ technique connections"),
                    gradient: [Color.blue.opacity(0.3), Color.purple.opacity(0.2)],
                    accent: .blue
                )
            }

            NavigationLink {
                GamePlansView()
            } label: {
                heroBanner(
                    icon: "checklist",
                    title: lang.t("ゲームプランを作る", en: "Build Game Plan"),
                    desc: lang.t("良蔵システム等のテンプレートから自分の戦略を設計", en: "Design your strategy from templates"),
                    gradient: [Color.purple.opacity(0.3), Color.red.opacity(0.2)],
                    accent: .purple
                )
            }

            NavigationLink {
                AIRyozoView()
            } label: {
                heroBanner(
                    icon: "brain.head.profile",
                    title: lang.t("AI良蔵に聞く", en: "Ask AI Ryozo"),
                    desc: lang.t("テクニック・戦略・練習メニューなんでも相談", en: "Get advice on techniques, strategy & training"),
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
