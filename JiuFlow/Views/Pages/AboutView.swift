import SwiftUI

struct AboutView: View {
    @EnvironmentObject var api: APIService
    @EnvironmentObject var langMgr: LanguageManager
    @EnvironmentObject var premium: PremiumManager

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                // Logo + tagline
                VStack(spacing: 12) {
                    Text("JiuFlow")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(Color.jfTextPrimary)
                    Text("最短で勝てる柔術")
                        .font(.headline)
                        .foregroundStyle(Color.jfRed)
                    Text("グレイシー直系 × モダン競技特化")
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                }
                .padding(.top, 20)

                // All Features link
                NavigationLink {
                    FeaturesView()
                        .environmentObject(api)
                        .environmentObject(langMgr)
                        .environmentObject(premium)
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.jfRed.opacity(0.12))
                                .frame(width: 40, height: 40)
                            Image(systemName: "square.grid.2x2.fill")
                                .font(.body)
                                .foregroundStyle(Color.jfRed)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("全機能一覧")
                                .font(.subheadline.bold())
                                .foregroundStyle(Color.jfTextPrimary)
                            Text("JiuFlowの全機能をチェック")
                                .font(.caption)
                                .foregroundStyle(Color.jfTextTertiary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Color.jfTextTertiary)
                    }
                    .padding(14)
                    .glassCard()
                }

                // Vision
                infoCard(title: "ビジョン", icon: "bolt.shield.fill", color: .jfRed,
                    text: "運動音痴でも勝てる柔術を広めたい。\n\n安全で、長く続けられて、最短で競技で勝てるテクニックを体系化。グレイシー直系の基本を現代競技に最適化した「良蔵メソッド」で、年齢・体格・運動経験に関係なく強くなれる。")

                // Ryozo
                infoCard(title: "技術監修: 村田良蔵", icon: "trophy.fill", color: .yellow,
                    text: "世界チャンピオン。グレイシー直系のクローズドガードをベースに、現代競技で通用するシステムを構築。\n\n教え子から黒帯を含む世界チャンピオンを多数輩出。団体優勝の実績も多い。\n\n哲学: 「やられない → コントロール → アタック」\n\nこの順番を守れば、怪我せず、体力に頼らず、確実に強くなれる。")

                // Founder story
                infoCard(title: "開発者ストーリー", icon: "person.fill", color: .blue,
                    text: "元メルカリCPO。運動経験ゼロから柔術を始め、1年半でワールドマスター青帯3位。\n\n「運動音痴の自分でも勝てた。この方法を体系化すれば、もっと多くの人が柔術を楽しめるはず。」\n\nプロダクト設計の経験を活かし、テクノロジーで柔術学習を革新する。")

                // Method
                infoCard(title: "JiuFlowメソッド", icon: "arrow.triangle.branch", color: .purple,
                    text: "①テクニックマップで「流れ」を可視化\n②ゲームプランで試合を事前設計\n③練習記録＋AIコーチで弱点分析\n④データに基づいた上達サイクル\n\nバラバラの技ではなく「システム」で学ぶ。だから最短で強くなる。")

                // Team
                infoCard(title: "運営", icon: "person.3.fill", color: .green,
                    text: "設立: 2024年\nURL: jiuflow.art\n連絡先: support@jiuflow.art\n対応言語: 日本語・英語・ポルトガル語")
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .background(Color.jfDarkBg)
        .navigationTitle("JiuFlowについて")
        .navigationBarTitleDisplayMode(.large)
    }

    private func infoCard(title: String, icon: String, color: Color, text: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(color)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.jfTextPrimary)
            }
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.jfTextSecondary)
                .lineSpacing(5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassCard()
    }
}

// MARK: - Venues View

struct VenuesView: View {
    var body: some View {
        WebContentView(
            title: "会場情報",
            icon: "mappin.and.ellipse",
            description: "大会や柔術イベントの会場情報",
            webURL: "https://jiuflow-ssr.fly.dev/venues",
            color: .orange
        )
        .navigationTitle("会場情報")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Pricing View

struct PricingView: View {
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("料金プラン")
                        .font(.title2.bold())
                        .foregroundStyle(Color.jfTextPrimary)
                    Text("初月無料トライアル付き")
                        .font(.subheadline)
                        .foregroundStyle(Color.jfTextTertiary)
                }
                .padding(.top, 12)

                pricingCard(name: "Founder", price: "¥980", period: "/月", features: [
                    "全テクニック動画", "テクニックマップ", "ゲームプランビルダー", "ロードマップ進捗管理"
                ], color: .jfRed, featured: true)

                pricingCard(name: "Regular", price: "¥2,900", period: "/月", features: [
                    "Founder全機能", "AI解析", "優先サポート", "オフライン再生（予定）"
                ], color: .blue, featured: false)

                pricingCard(name: "年間", price: "¥29,000", period: "/年", features: [
                    "Regular全機能", "2ヶ月分お得", "限定コンテンツ"
                ], color: .green, featured: false)

                Text("道場検索・大会情報・ニュースは無料")
                    .font(.caption)
                    .foregroundStyle(Color.jfTextTertiary)
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .background(Color.jfDarkBg)
        .navigationTitle("料金")
        .navigationBarTitleDisplayMode(.large)
    }

    private func pricingCard(name: String, price: String, period: String, features: [String], color: Color, featured: Bool) -> some View {
        VStack(spacing: 14) {
            Text(name)
                .font(.headline)
                .foregroundStyle(color)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(price)
                    .font(.system(size: 32, weight: .black))
                    .foregroundStyle(Color.jfTextPrimary)
                Text(period)
                    .font(.caption)
                    .foregroundStyle(Color.jfTextTertiary)
            }
            VStack(alignment: .leading, spacing: 6) {
                ForEach(features, id: \.self) { f in
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                        Text(f)
                            .font(.subheadline)
                            .foregroundStyle(Color.jfTextSecondary)
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(featured ? color : Color.jfBorder, lineWidth: featured ? 2 : 1)
        )
        .glassCard()
    }
}
