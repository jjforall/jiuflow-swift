import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                // Logo
                VStack(spacing: 12) {
                    Text("JiuFlow")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(Color.jfTextPrimary)
                    Text("柔術をもっと身近に")
                        .font(.subheadline)
                        .foregroundStyle(Color.jfTextTertiary)
                }
                .padding(.top, 20)

                // Mission
                infoCard(title: "ミッション", icon: "target", color: .jfRed,
                    text: "柔術の知識と技術を、誰もがアクセスできる形で提供し、世界中の柔術コミュニティをつなぐ。")

                // Vision
                infoCard(title: "ビジョン", icon: "eye.fill", color: .blue,
                    text: "柔術を通じた人生の豊かさの実現。テクノロジーの活用（4K俯瞰撮影、AI解析、データドリブン）による学習革新。")

                // Features
                infoCard(title: "特徴", icon: "star.fill", color: .yellow,
                    text: "・世界チャンピオン村田良蔵監修の教則動画\n・テクニック同士の「流れ」を可視化する技術マップ\n・AI文字起こし（多言語対応）\n・道場・選手・大会データベース")

                // Team
                infoCard(title: "運営", icon: "person.3.fill", color: .green,
                    text: "設立: 2024年\nURL: jiuflow.art\n連絡先: support@jiuflow.art\n対応言語: 日本語・英語・ポルトガル語（計12言語対応予定）")
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
