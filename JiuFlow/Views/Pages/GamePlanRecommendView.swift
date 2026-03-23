import SwiftUI

// MARK: - Game Plan Recommendation

struct GamePlanRecommendView: View {
    @EnvironmentObject var langMgr: LanguageManager
    @AppStorage("profile_belt") private var belt = "white"
    @AppStorage("profile_weight") private var weight = ""

    private var weightCategory: String {
        guard let w = Double(weight) else { return "unknown" }
        if w < 64 { return "light" }
        if w < 76 { return "medium" }
        if w < 88 { return "heavy" }
        return "ultra_heavy"
    }

    private var recommendations: [Recommendation] {
        var result: [Recommendation] = []

        switch belt.lowercased() {
        case "white":
            result.append(Recommendation(
                templateId: "ryozo",
                name: langMgr.t("JiuFlowメソッド", en: "JiuFlow Method"),
                icon: "brain.head.profile",
                color: .red,
                reason: langMgr.t(
                    "白帯はまず基本を固めることが大切。クローズドガードからの三角絞め・腕十字を中心に「やられない→コントロール→アタック」の順番を身につけよう。",
                    en: "As a white belt, mastering fundamentals is key. Learn the JiuFlow Method's closed guard triangle and armbar, following the 'defend -> control -> attack' progression."
                )
            ))
            result.append(Recommendation(
                templateId: "roger",
                name: langMgr.t("クラシック王道システム", en: "Classic System"),
                icon: "trophy.fill",
                color: .brown,
                reason: langMgr.t(
                    "クローズドガードとクロスチョークは全帯で通用する基本中の基本。早い段階で身につけておくと上達が加速する。",
                    en: "Closed guard and cross choke are fundamentals that work at every level. Learning them early accelerates your progress."
                )
            ))

        case "blue":
            switch weightCategory {
            case "light":
                result.append(Recommendation(
                    templateId: "mikey",
                    name: langMgr.t("50/50フットロック", en: "50/50 Foot Lock"),
                    icon: "figure.martial.arts",
                    color: .pink,
                    reason: langMgr.t(
                        "軽量級はスピードとテクニックで勝負。50/50からのヒールフックは体格差を無効化できる強力な武器。",
                        en: "Lighter weight classes excel with speed and technique. The 50/50 heel hook nullifies size differences."
                    )
                ))
                result.append(Recommendation(
                    templateId: "marcelo",
                    name: langMgr.t("バタフライ→バックテイク", en: "Butterfly -> Back Take"),
                    icon: "person.fill",
                    color: .teal,
                    reason: langMgr.t(
                        "バタフライガードはアジリティを活かせる軽量級の最強ガード。アームドラッグからバックテイクの流れは勝率が高い。",
                        en: "Butterfly guard leverages agility -- perfect for lighter grapplers. The arm drag to back take sequence has a high success rate."
                    )
                ))

            case "heavy", "ultra_heavy":
                result.append(Recommendation(
                    templateId: "top-game",
                    name: langMgr.t("トップゲームシステム", en: "Top Game System"),
                    icon: "arrow.up.circle.fill",
                    color: .cyan,
                    reason: langMgr.t(
                        "重量級は体重を活かしたトップゲームが最も効率的。テイクダウン→パス→サイドコントロール→マウントの流れを極めよう。",
                        en: "Heavier grapplers benefit most from a pressure-based top game. Master the takedown -> pass -> side control -> mount chain."
                    )
                ))
                result.append(Recommendation(
                    templateId: "gordon",
                    name: langMgr.t("トップ制圧システム", en: "Top Domination"),
                    icon: "crown.fill",
                    color: .yellow,
                    reason: langMgr.t(
                        "体重を活かしてトップから制圧。パスガード→マウント→RNCの流れは重量級の王道。",
                        en: "Use your weight to dominate from top. The pass -> mount -> RNC sequence is the heavy weight gold standard."
                    )
                ))

            default:
                result.append(Recommendation(
                    templateId: "galvao",
                    name: langMgr.t("オールラウンドシステム", en: "All-Round System"),
                    icon: "circle.hexagongrid.fill",
                    color: .orange,
                    reason: langMgr.t(
                        "中量級は万能型が強い。トップもボトムもバランスよく学び、相手に合わせて戦略を変えられるようになろう。",
                        en: "Medium weight class excels with versatility. Learn both top and bottom game to adapt to any opponent."
                    )
                ))
            }

        case "purple", "brown", "black":
            result.append(Recommendation(
                templateId: "custom",
                name: langMgr.t("弱点分析からの推薦", en: "Weakness-Based Recommendation"),
                icon: "chart.bar.fill",
                color: .purple,
                reason: langMgr.t(
                    "紫帯以上は自分の弱点を把握して補強することが上達の鍵。ロール記録のデータから弱点を分析し、集中的にドリルしよう。AIコーチ機能で詳しい分析ができます。",
                    en: "At purple belt and above, identifying and addressing weaknesses is key. Analyze your roll journal data and drill focused scenarios. Use AI Coach for detailed analysis."
                )
            ))
            result.append(Recommendation(
                templateId: "craig",
                name: langMgr.t("サドル→ヒールフック", en: "Saddle -> Heel Hook"),
                icon: "figure.martial.arts",
                color: .red,
                reason: langMgr.t(
                    "上級者はレッグロックゲームを追加すると攻撃の幅が大きく広がる。Zガード→SLX→サドルの流れを練習しよう。",
                    en: "Advanced practitioners can expand their attack range with leg locks. Practice the Z-guard -> SLX -> saddle chain."
                )
            ))

        default:
            result.append(Recommendation(
                templateId: "ryozo",
                name: langMgr.t("JiuFlowメソッド", en: "JiuFlow Method"),
                icon: "brain.head.profile",
                color: .red,
                reason: langMgr.t(
                    "まずは基本のJiuFlowメソッドから始めよう。",
                    en: "Start with the fundamentals of the JiuFlow Method."
                )
            ))
        }

        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.subheadline)
                    .foregroundStyle(.purple)
                Text(langMgr.t("AIおすすめプラン", en: "AI Recommended Plans"))
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.jfTextPrimary)
            }

            // Profile context
            HStack(spacing: 12) {
                profileBadge(
                    icon: "medal.fill",
                    label: beltLabel(belt),
                    color: beltColor(belt)
                )
                if !weight.isEmpty {
                    profileBadge(
                        icon: "scalemass.fill",
                        label: "\(weight) kg",
                        color: .blue
                    )
                }
                Spacer()
                NavigationLink {
                    SettingsView()
                } label: {
                    Text(langMgr.t("設定", en: "Settings"))
                        .font(.caption2)
                        .foregroundStyle(Color.jfTextTertiary)
                }
            }

            // Recommendations
            ForEach(recommendations) { rec in
                recommendationCard(rec)
            }
        }
        .padding(14)
        .glassCard()
    }

    // MARK: - Recommendation Card

    private func recommendationCard(_ rec: Recommendation) -> some View {
        NavigationLink {
            if rec.templateId == "custom" {
                AICoachView()
            } else {
                GamePlansView()
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(rec.color.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: rec.icon)
                        .font(.body)
                        .foregroundStyle(rec.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(rec.name)
                        .font(.caption.bold())
                        .foregroundStyle(Color.jfTextPrimary)
                    Text(rec.reason)
                        .font(.caption2)
                        .foregroundStyle(Color.jfTextTertiary)
                        .lineSpacing(3)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(Color.jfTextTertiary)
                    .padding(.top, 10)
            }
            .padding(10)
            .background(rec.color.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Profile Badge

    private func profileBadge(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(color)
            Text(label)
                .font(.caption2.bold())
                .foregroundStyle(Color.jfTextSecondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.08))
        .clipShape(Capsule())
    }

    private func beltLabel(_ belt: String) -> String {
        switch belt.lowercased() {
        case "white": return langMgr.t("白帯", en: "White")
        case "blue": return langMgr.t("青帯", en: "Blue")
        case "purple": return langMgr.t("紫帯", en: "Purple")
        case "brown": return langMgr.t("茶帯", en: "Brown")
        case "black": return langMgr.t("黒帯", en: "Black")
        default: return belt
        }
    }

    private func beltColor(_ belt: String) -> Color {
        switch belt.lowercased() {
        case "white": return .white
        case "blue": return .blue
        case "purple": return .purple
        case "brown": return .brown
        case "black": return .gray
        default: return .gray
        }
    }
}

// MARK: - Recommendation Model

struct Recommendation: Identifiable {
    let id = UUID()
    let templateId: String
    let name: String
    let icon: String
    let color: Color
    let reason: String
}
