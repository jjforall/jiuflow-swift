import SwiftUI

struct GamePlansView: View {
    @State private var selectedTab = 0

    private let templates = [
        GamePlanTemplate(id: "back-taker", name: "バックテイカー", icon: "arrow.uturn.backward", color: .purple,
                         description: "バックコントロールを軸にした戦略", difficulty: "中級"),
        GamePlanTemplate(id: "half-guard", name: "ハーフガード", icon: "shield.lefthalf.filled", color: .blue,
                         description: "ハーフガードからの攻防プラン", difficulty: "初級"),
        GamePlanTemplate(id: "leg-locker", name: "レッグロッカー", icon: "figure.walk", color: .red,
                         description: "足関節を中心とした攻撃プラン", difficulty: "上級"),
        GamePlanTemplate(id: "top-game", name: "トップゲーム", icon: "arrow.down.circle", color: .green,
                         description: "テイクダウンからトップコントロール", difficulty: "初級"),
        GamePlanTemplate(id: "guard-player", name: "ガードプレイヤー", icon: "shield.fill", color: .orange,
                         description: "ガードからのスイープ・サブミッション", difficulty: "中級"),
        GamePlanTemplate(id: "pressure-passer", name: "プレッシャーパサー", icon: "arrow.down.to.line", color: .indigo,
                         description: "プレッシャーによるガードパス戦略", difficulty: "中級"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Segment
                    Picker("", selection: $selectedTab) {
                        Text("テンプレート").tag(0)
                        Text("AI生成").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)

                    if selectedTab == 0 {
                        templatesSection
                    } else {
                        aiSection
                    }
                }
                .padding(.bottom, 40)
            }
            .background(Color.jfDarkBg)
            .navigationTitle("ゲームプラン")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Templates

    private var templatesSection: some View {
        VStack(spacing: 14) {
            ForEach(templates) { template in
                GamePlanTemplateCard(template: template)
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - AI Section

    private var aiSection: some View {
        VStack(spacing: 20) {
            ZStack {
                RadialGradient(
                    colors: [Color.purple.opacity(0.15), .clear],
                    center: .center,
                    startRadius: 10,
                    endRadius: 120
                )

                VStack(spacing: 14) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 48))
                        .foregroundStyle(.purple)

                    Text("AIゲームプラン生成")
                        .font(.title3.bold())
                        .foregroundStyle(Color.jfTextPrimary)

                    Text("あなたの体格、帯色、得意技を入力すると\nAIが最適なゲームプランを提案します")
                        .font(.subheadline)
                        .foregroundStyle(Color.jfTextTertiary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.vertical, 24)

            Link(destination: URL(string: "https://jiuflow-ssr.fly.dev/game-plans/ai")!) {
                Label("AI生成を試す", systemImage: "sparkles")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Template Model

struct GamePlanTemplate: Identifiable {
    let id: String
    let name: String
    let icon: String
    let color: Color
    let description: String
    let difficulty: String
}

// MARK: - Template Card

struct GamePlanTemplateCard: View {
    let template: GamePlanTemplate

    private var difficultyColor: Color {
        switch template.difficulty {
        case "初級": return .green
        case "中級": return .orange
        case "上級": return .red
        default: return .gray
        }
    }

    var body: some View {
        Link(destination: URL(string: "https://jiuflow-ssr.fly.dev/game-plans/builder/template/\(template.id)")!) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(template.color.opacity(0.12))
                        .frame(width: 52, height: 52)
                    Image(systemName: template.icon)
                        .font(.title3)
                        .foregroundStyle(template.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.jfTextPrimary)

                    Text(template.description)
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    CategoryBadge(text: template.difficulty, color: difficultyColor)

                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                }
            }
            .padding(14)
            .glassCard()
        }
    }
}
