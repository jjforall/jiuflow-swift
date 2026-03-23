import SwiftUI

// MARK: - Feature Item Model

private struct FeatureItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let color: Color
    let destination: AnyView?
}

private struct FeatureCategory: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let items: [FeatureItem]
}

// MARK: - Features View

struct FeaturesView: View {
    @EnvironmentObject var api: APIService
    @EnvironmentObject var langMgr: LanguageManager
    @EnvironmentObject var premium: PremiumManager

    private var categories: [FeatureCategory] {
        [
            FeatureCategory(
                title: langMgr.t("学ぶ", en: "Learn"),
                icon: "book.fill",
                color: .blue,
                items: [
                    FeatureItem(
                        icon: "arrow.triangle.branch",
                        title: langMgr.t("テクニックマップ", en: "Technique Map"),
                        description: langMgr.t("237テクニックの流れを可視化", en: "Visualize 237 technique connections"),
                        color: .blue,
                        destination: AnyView(FlowTab())
                    ),
                    FeatureItem(
                        icon: "checklist",
                        title: langMgr.t("ゲームプラン", en: "Game Plans"),
                        description: langMgr.t("テンプレートから自分の戦略を設計", en: "Design your strategy from templates"),
                        color: .purple,
                        destination: AnyView(GamePlansView())
                    ),
                    FeatureItem(
                        icon: "play.rectangle.fill",
                        title: langMgr.t("教則動画", en: "Tutorial Videos"),
                        description: langMgr.t("世界チャンピオン良蔵監修", en: "Supervised by world champion Ryozo"),
                        color: .red,
                        destination: AnyView(VideosTab().environmentObject(api))
                    ),
                    FeatureItem(
                        icon: "brain.head.profile",
                        title: langMgr.t("AI良蔵", en: "AI Ryozo"),
                        description: langMgr.t("テクニックの質問にAIが回答", en: "AI answers your technique questions"),
                        color: .jfRed,
                        destination: AnyView(AIRyozoView())
                    ),
                ]
            ),
            FeatureCategory(
                title: langMgr.t("記録する", en: "Record"),
                icon: "pencil.and.list.clipboard",
                color: .green,
                items: [
                    FeatureItem(
                        icon: "book.closed.fill",
                        title: langMgr.t("練習日記", en: "Practice Journal"),
                        description: langMgr.t("タイプ・気分・強度・技を記録", en: "Log type, mood, intensity & techniques"),
                        color: .green,
                        destination: AnyView(PracticeJournalView())
                    ),
                    FeatureItem(
                        icon: "person.2.fill",
                        title: langMgr.t("ロール記録", en: "Roll Journal"),
                        description: langMgr.t("パートナー・勝敗・防御を分析", en: "Analyze partners, results & defense"),
                        color: .blue,
                        destination: AnyView(RollJournalView())
                    ),
                    FeatureItem(
                        icon: "trophy.fill",
                        title: langMgr.t("大会結果", en: "Tournament Results"),
                        description: langMgr.t("試合結果と反省を残す", en: "Record match results and reflections"),
                        color: .yellow,
                        destination: AnyView(TournamentsView().environmentObject(api))
                    ),
                    FeatureItem(
                        icon: "video.fill",
                        title: langMgr.t("動画メモ", en: "Video Notes"),
                        description: langMgr.t("観た動画の気づきを保存", en: "Save notes from videos you watched"),
                        color: .orange,
                        destination: AnyView(FavoritesView())
                    ),
                ]
            ),
            FeatureCategory(
                title: langMgr.t("分析", en: "Analysis"),
                icon: "chart.bar.fill",
                color: .purple,
                items: [
                    FeatureItem(
                        icon: "brain.head.profile",
                        title: langMgr.t("AIコーチ", en: "AI Coach"),
                        description: langMgr.t("弱点分析→今週のドリル提案", en: "Weakness analysis & drill suggestions"),
                        color: .purple,
                        destination: AnyView(AICoachView())
                    ),
                    FeatureItem(
                        icon: "chart.pie.fill",
                        title: langMgr.t("勝率メーター", en: "Win Rate Meter"),
                        description: langMgr.t("ロールの勝率を可視化", en: "Visualize your roll win rate"),
                        color: .blue,
                        destination: AnyView(PracticeProgressView())
                    ),
                    FeatureItem(
                        icon: "flame.fill",
                        title: langMgr.t("ストリーク", en: "Streak"),
                        description: langMgr.t("練習継続日数トラッキング", en: "Track your practice streak"),
                        color: .orange,
                        destination: AnyView(DailyDrillView().environmentObject(api))
                    ),
                    FeatureItem(
                        icon: "scalemass.fill",
                        title: langMgr.t("体重管理", en: "Weight Tracker"),
                        description: langMgr.t("階級管理とカウントダウン", en: "Weight class management & countdown"),
                        color: .cyan,
                        destination: AnyView(WeightTrackerView())
                    ),
                ]
            ),
            FeatureCategory(
                title: langMgr.t("道場", en: "Dojos"),
                icon: "building.2.fill",
                color: .teal,
                items: [
                    FeatureItem(
                        icon: "mappin.and.ellipse",
                        title: langMgr.t("道場検索", en: "Find Dojos"),
                        description: langMgr.t("全国28道場", en: "28 dojos nationwide"),
                        color: .teal,
                        destination: AnyView(DojosTab().environmentObject(api))
                    ),
                    FeatureItem(
                        icon: "calendar.badge.clock",
                        title: langMgr.t("クラス予約", en: "Book Class"),
                        description: langMgr.t("3道場でアプリ内予約", en: "In-app booking at 3 dojos"),
                        color: .green,
                        destination: AnyView(ReservationsView().environmentObject(api))
                    ),
                    FeatureItem(
                        icon: "trophy.fill",
                        title: langMgr.t("大会情報", en: "Tournaments"),
                        description: langMgr.t("国内外162大会", en: "162 tournaments worldwide"),
                        color: .yellow,
                        destination: AnyView(TournamentsView().environmentObject(api))
                    ),
                ]
            ),
            FeatureCategory(
                title: langMgr.t("コミュニティ", en: "Community"),
                icon: "person.3.fill",
                color: .indigo,
                items: [
                    FeatureItem(
                        icon: "bubble.left.and.bubble.right.fill",
                        title: langMgr.t("フォーラム", en: "Forum"),
                        description: langMgr.t("柔術仲間と交流", en: "Connect with fellow grapplers"),
                        color: .blue,
                        destination: AnyView(ForumView().environmentObject(api))
                    ),
                    FeatureItem(
                        icon: "person.3.fill",
                        title: langMgr.t("選手図鑑", en: "Athletes"),
                        description: langMgr.t("58名の系統図付き", en: "58 athletes with lineage"),
                        color: .pink,
                        destination: AnyView(AthletesTab().environmentObject(api))
                    ),
                    FeatureItem(
                        icon: "brain.head.profile",
                        title: langMgr.t("AI良蔵に聞く", en: "Ask AI Ryozo"),
                        description: langMgr.t("なんでも相談", en: "Ask anything about BJJ"),
                        color: .jfRed,
                        destination: AnyView(AIRyozoView())
                    ),
                ]
            ),
        ]
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("JiuFlow")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(Color.jfTextPrimary)
                    Text(langMgr.t("全機能一覧", en: "All Features"))
                        .font(.headline)
                        .foregroundStyle(Color.jfRed)
                    Text(langMgr.t("最短で勝てる柔術のすべてがここに", en: "Everything you need to win at BJJ"))
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                }
                .padding(.top, 12)

                // Feature categories
                ForEach(categories) { category in
                    featureCategorySection(category)
                }
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .background(Color.jfDarkBg)
        .navigationTitle(langMgr.t("機能一覧", en: "Features"))
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Category Section

    private func featureCategorySection(_ category: FeatureCategory) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section header
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(category.color.opacity(0.12))
                        .frame(width: 28, height: 28)
                    Image(systemName: category.icon)
                        .font(.caption)
                        .foregroundStyle(category.color)
                }
                Text(category.title)
                    .font(.headline)
                    .foregroundStyle(Color.jfTextPrimary)
                Spacer()
                Text("\(category.items.count)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(Color.jfTextTertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.jfCardBg)
                    .clipShape(Capsule())
            }

            // Feature items
            ForEach(category.items) { item in
                if let destination = item.destination {
                    NavigationLink {
                        destination
                    } label: {
                        featureRow(item)
                    }
                } else {
                    featureRow(item)
                }
            }
        }
        .padding(14)
        .glassCard()
    }

    // MARK: - Feature Row

    private func featureRow(_ item: FeatureItem) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(item.color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: item.icon)
                    .font(.body)
                    .foregroundStyle(item.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.jfTextPrimary)
                Text(item.description)
                    .font(.caption)
                    .foregroundStyle(Color.jfTextTertiary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(Color.jfTextTertiary)
        }
        .padding(.vertical, 4)
    }
}
