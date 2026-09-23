import SwiftUI
import StoreKit
import PhotosUI

struct SubscriptionView: View {
    @EnvironmentObject var store: StoreManager
    @EnvironmentObject var premium: PremiumManager
    @State private var isPurchasing = false
    @State private var purchaseError: String?

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // Current plan status
                currentPlanCard

                NavigationLink {
                    SubscriptionManagementView()
                } label: {
                    Label(tr("契約・料金・解約"), systemImage: "creditcard")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .accessibilityIdentifier("subscriptionManagementEntry")

                // 7-day free trial
                if !store.hasActiveSubscription {
                    HStack(spacing: 8) {
                        Image(systemName: "gift.fill")
                            .foregroundStyle(Color.jfGold)
                        Text(tr("7日間無料トライアル付き"))
                            .font(.caption.bold())
                            .foregroundStyle(Color.jfGold)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color.jfGold.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.jfGold.opacity(0.2), lineWidth: 1))
                }

                if store.isLoading {
                    LoadingWithTips()
                } else {
                    // 3-tier plan cards
                    threeColumnPlans

                    // StoreKit product cards
                    if store.products.isEmpty {
                        // Products not yet loaded — show retry
                        VStack(spacing: 10) {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(Color.jfRed)
                            Text(tr("商品情報を読み込み中..."))
                                .font(.caption)
                                .foregroundStyle(Color.jfTextTertiary)
                            Button {
                                Task { await store.loadProducts() }
                            } label: {
                                Label(tr("再読み込み"), systemImage: "arrow.clockwise")
                                    .font(.caption)
                                    .foregroundStyle(Color.jfRed)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .glassCard()
                    } else {
                        ForEach(store.products, id: \.id) { product in
                            productCard(product)
                        }
                    }
                }

                // Error message
                if let error = purchaseError ?? store.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 16)
                }

                // Manage / Restore / Terms
                manageSection
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .background(Color.jfDarkBg)
        .navigationTitle(tr("サブスクリプション"))
        .navigationBarTitleDisplayMode(.large)
        .overlay {
            if isPurchasing {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .overlay {
                        ProgressView(tr("購入処理中..."))
                            .tint(.white)
                            .foregroundStyle(.white)
                            .padding(24)
                            .glassCard()
                    }
            }
        }
    }

    // MARK: - Current Plan Card

    private var currentPlanCard: some View {
        VStack(spacing: 8) {
            Image(systemName: store.hasActiveSubscription ? "checkmark.seal.fill" : "person.crop.circle")
                .font(.system(size: 36))
                .foregroundStyle(store.hasActiveSubscription ? .green : Color.jfTextTertiary)
            Text(store.currentPlanName.map { "プラン: \($0)" } ?? tr("フリープラン"))
                .font(.headline)
                .foregroundStyle(Color.jfTextPrimary)
            Text(store.hasActiveSubscription ? tr("有効なサブスクリプションがあります") : tr("無料機能のみ利用可能"))
                .font(.caption)
                .foregroundStyle(Color.jfTextTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .glassCard()
    }

    // MARK: - 3-Tier Plan Cards

    private var threeColumnPlans: some View {
        VStack(spacing: 16) {
            // Plan cards
            HStack(spacing: 12) {
                // Free
                tierPlanCard(
                    name: "FREE", price: "¥0", period: "",
                    color: .gray, isHighlighted: false,
                    badge: nil
                )
                // Pro
                tierPlanCard(
                    name: "PRO", price: "¥1,500", period: tr("/月"),
                    color: .jfRed, isHighlighted: true,
                    badge: "POPULAR"
                )
                // Black Belt
                tierPlanCard(
                    name: "BLACK BELT", price: "¥4,000", period: tr("/月"),
                    color: .jfGold, isHighlighted: false,
                    badge: "ULTIMATE"
                )
            }

            // Feature comparison
            tierFeatureTable
        }
    }

    private func tierPlanCard(name: String, price: String, period: String, color: Color, isHighlighted: Bool, badge: String?) -> some View {
        VStack(spacing: 8) {
            if let badge = badge {
                Text(badge)
                    .font(.system(size: 8, weight: .heavy))
                    .tracking(1)
                    .foregroundColor(color == .jfGold ? .black : .white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(color == .jfGold ? LinearGradient.jfGoldGradient : LinearGradient(colors: [color], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(4)
            }
            Text(name)
                .font(.system(size: 10, weight: .bold))
                .tracking(1)
                .foregroundColor(color)
            Text(price)
                .font(.system(size: 22, weight: .black))
                .foregroundColor(.white)
            + Text(period)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.jfCardBg)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHighlighted ? color : Color.clear, lineWidth: 2)
        )
    }

    private var tierFeatureTable: some View {
        VStack(spacing: 0) {
            tierFeatureRow(tr("動画"), tr("月5本"), tr("無制限"), tr("無制限+4K"))
            tierFeatureRow(tr("ゲームプラン"), tr("3個"), tr("全17+保存5"), tr("全17+AI生成"))
            tierFeatureRow(tr("AI良蔵"), tr("月3回"), tr("月30回"), tr("無制限"))
            tierFeatureRow(tr("練習日記"), tr("月3回"), tr("無制限"), tr("無制限+AI"))
            tierFeatureRow(tr("大会エントリー"), tr("通常"), tr("通常"), "10%OFF")
            tierFeatureRow(tr("ライブクラス"), "—", tr("アーカイブ"), tr("ライブ+録画"))
            tierFeatureRow(tr("フォーラム"), tr("閲覧+投稿"), tr("+PROバッジ"), tr("+専用"))
            tierFeatureRow(tr("広告"), tr("あり"), tr("なし"), tr("なし"))
        }
        .background(Color.jfCardBg)
        .cornerRadius(12)
    }

    private func tierFeatureRow(_ feature: String, _ free: String, _ pro: String, _ bb: String) -> some View {
        HStack {
            Text(feature)
                .font(.caption2)
                .foregroundColor(.white)
                .frame(width: 80, alignment: .leading)
            Text(free)
                .font(.caption2)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity)
            Text(pro)
                .font(.caption2)
                .foregroundColor(.jfRed)
                .frame(maxWidth: .infinity)
            Text(bb)
                .font(.caption2)
                .foregroundColor(.jfGold)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .overlay(Divider().offset(y: 16), alignment: .bottom)
    }

    // MARK: - Product Card

    private func productCard(_ product: Product) -> some View {
        let info = planInfo(for: product.id)
        let isCurrentPlan = store.purchasedProductIDs.contains(product.id)

        return Button {
            guard !isCurrentPlan else { return }
            Task { await handlePurchase(product) }
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(info.name)
                            .font(.headline)
                            .foregroundStyle(info.color)
                        if isCurrentPlan {
                            Text(tr("現在のプラン"))
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .clipShape(Capsule())
                        }
                    }
                    Text(product.displayPrice + periodLabel(product))
                        .font(.title3.bold())
                        .foregroundStyle(Color.jfTextPrimary)
                    Text(info.desc)
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                if !isCurrentPlan {
                    Text(tr("選択"))
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(info.color)
                        .clipShape(Capsule())
                }
            }
            .padding(14)
            .glassCard()
        }
        .disabled(isPurchasing || isCurrentPlan)
    }

    // MARK: - Helpers

    private struct PlanInfo {
        let name: String
        let desc: String
        let color: Color
    }

    private func planInfo(for productID: String) -> PlanInfo {
        switch productID {
        case "jiuflow_pro_monthly":
            return PlanInfo(name: "PRO", desc: tr("全動画・AIコーチ・全ゲームプラン"), color: .jfRed)
        case "jiuflow_blackbelt_monthly":
            return PlanInfo(name: "BLACK BELT", desc: tr("全機能+4K+AI無制限+大会10%OFF"), color: .white)
        default:
            return PlanInfo(name: productID, desc: "", color: .gray)
        }
    }

    private func periodLabel(_ product: Product) -> String {
        guard let sub = product.subscription else { return "" }
        switch sub.subscriptionPeriod.unit {
        case .month:
            return sub.subscriptionPeriod.value == 1 ? tr("/月") : "/\(sub.subscriptionPeriod.value)ヶ月"
        case .year:
            return sub.subscriptionPeriod.value == 1 ? tr("/年") : "/\(sub.subscriptionPeriod.value)年"
        case .week:
            return tr("/週")
        case .day:
            return tr("/日")
        @unknown default:
            return ""
        }
    }

    private func handlePurchase(_ product: Product) async {
        isPurchasing = true
        purchaseError = nil
        do {
            let success = try await store.purchase(product)
            if success {
                purchaseError = nil
            }
        } catch {
            purchaseError = trf("購入に失敗しました: %@", error.localizedDescription)
        }
        isPurchasing = false
    }

    // MARK: - Manage Subscription

    private var manageSection: some View {
        VStack(spacing: 10) {
                NavigationLink {
                    SubscriptionManagementView()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "creditcard.fill")
                            .font(.subheadline)
                        Text(tr("プランを変更・解約"))
                            .font(.subheadline.bold())
                    }
                    .foregroundStyle(Color.jfTextPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.jfCardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.jfBorder, lineWidth: 1)
                    )
                }

            Button {
                Task { await store.restorePurchases() }
            } label: {
                Text(tr("購入を復元"))
                    .font(.caption.bold())
                    .foregroundStyle(Color.jfTextTertiary)
            }

            // Auto-renewal disclosure (App Store Guideline 3.1.2)
            Text(tr("サブスクリプションは月額・自動更新です。期間終了の24時間前までに App Store の設定から解約しない限り自動的に更新されます。"))
                .font(.caption2)
                .foregroundStyle(Color.jfTextTertiary)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Link(tr("利用規約 (EULA)"), destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                    .font(.caption2).foregroundStyle(Color.jfTextTertiary)
                Link(tr("プライバシー"), destination: URL(string: "https://jiuflow.com/privacy")!)
                    .font(.caption2).foregroundStyle(Color.jfTextTertiary)
            }
        }
    }

}

// Native account management. Apple owns Apple billing; Web subscriptions use
// the authenticated server API, never an embedded checkout or an inferred tier.
struct SubscriptionManagementView: View {
    @EnvironmentObject var api: APIService
    @EnvironmentObject var store: StoreManager
    @Environment(\.dismiss) private var dismiss
    @State private var subscriptions: [ManagedSubscription] = []
    @State private var loading = false
    @State private var changing = false
    @State private var message: String?
    @State private var errorMessage: String?
    @State private var showWebConfirmation: ManagedSubscription?

    struct ManagedSubscription: Decodable, Identifiable {
        let id: String
        let plan: String
        let status: String
        let provider: String
        let period_end: String
        var cancel_at_period_end: Bool
        var renewable: Bool { ["active", "trialing", "past_due", "unpaid"].contains(status) }
    }
    private struct ListResponse: Decodable { let subscriptions: [ManagedSubscription] }
    private struct CancelResponse: Decodable { let cancel_at_period_end: Bool }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(tr("解約の前に、これからのJiuFlowについて")).font(.headline)
                    Text(tr("動画で学んだ技を、次の練習で使える一手につなげることを目指しています。"))
                    Text(tr("今使える動画・技マップ・練習記録を、次の練習に役立ててみませんか。"))
                    DisclosureGroup(tr("開発中の改善を見る")) {
                        Text(tr("「学ぶ→記録→練習」の導線と、技を探しやすい検索・絞り込みを改善中です。公開時期は未定で、内容は変更される場合があります。"))
                            .padding(.top, 8)
                    }
                    Text(tr("Web版PROは2026年10月1日から新規契約が月額1,980円／年額19,800円。既存契約は据え置き、再契約はその時点の料金です。Apple購入の料金・更新日はAppleの管理画面でご確認ください。"))
                        .font(.footnote).foregroundStyle(Color.jfTextSecondary)
                    Button { dismiss() } label: {
                        Text(tr("契約を変更せず戻る")).frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("keepSubscription")
                }
                .padding(16).glassCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text(tr("Appleで購入した場合")).font(.headline)
                    Text(tr("解約は次のAppleの画面で確定します。画面を開いただけでは解約されません。"))
                        .font(.footnote)
                    Button { Task { await openAppleManagement() } } label: {
                        Text(tr("説明を確認してAppleの管理画面へ"))
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("manageAppleSubscription")
                    .disabled(changing)
                }.padding(16).glassCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text(tr("Webで購入した場合")).font(.headline)
                    if !api.isLoggedIn {
                        Text(tr("Webで契約したメールアドレスでアプリにログインしてください。"))
                    } else if loading {
                        ProgressView()
                    } else {
                        ForEach(subscriptions.filter { $0.provider == "stripe" }) { sub in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(sub.plan.uppercased()).font(.headline)
                                if sub.cancel_at_period_end {
                                    Text(tr("自動更新は停止済みです。"))
                                } else if sub.renewable {
                                    Text(tr("自動更新を停止しても、支払い済み期間の終了まで利用できます。"))
                                    if sub.status == "past_due" || sub.status == "unpaid" {
                                        Text(tr("すでに発生した未払い料金は取り消されません。"))
                                    }
                                    Button(role: .destructive) { showWebConfirmation = sub } label: {
                                        Text(tr("説明を確認してWeb契約を解約"))
                                            .frame(maxWidth: .infinity, minHeight: 44)
                                    }
                                    .buttonStyle(.bordered)
                                    .disabled(changing)
                                    .accessibilityIdentifier("cancelWebSubscription")
                                } else {
                                    Text(tr("自動更新中のWeb契約ではありません。"))
                                }
                            }
                        }
                        if subscriptions.filter({ $0.provider == "stripe" }).isEmpty && errorMessage == nil {
                            Text(tr("このアカウントにWeb契約が見つかりません。Apple購入または契約時のメールアドレスをご確認ください。"))
                        }
                        Button(tr("再読み込み")) { Task { await loadWebSubscriptions() } }
                            .disabled(changing)
                    }
                }.padding(16).glassCard()
                if let message { Text(message).foregroundStyle(.green).accessibilityIdentifier("billingResult") }
                if let errorMessage { Text(errorMessage).foregroundStyle(.red).accessibilityIdentifier("billingError") }
                Link(tr("お問い合わせ"), destination: URL(string: "mailto:support@jiuflow.com")!)
            }.padding(16)
        }
        .background(Color.jfDarkBg)
        .navigationTitle(tr("契約・料金・解約"))
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadWebSubscriptions() }
        .confirmationDialog(tr("自動更新を停止しますか？"), isPresented: Binding(
            get: { showWebConfirmation != nil }, set: { if !$0 { showWebConfirmation = nil } }
        ), titleVisibility: .visible) {
            if let sub = showWebConfirmation {
                Button(tr("解約する（自動更新を停止）"), role: .destructive) {
                    Task { await cancelWebSubscription(sub) }
                }
            }
            Button(tr("キャンセル"), role: .cancel) { showWebConfirmation = nil }
        }
    }

    private func request(_ path: String, body: [String: String]? = nil) throws -> URLRequest {
        guard api.isLoggedIn, let token = api.authToken, !token.isEmpty else { throw URLError(.userAuthenticationRequired) }
        var request = URLRequest(url: URL(string: api.baseURL + path)!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        return request
    }

    @MainActor private func loadWebSubscriptions() async {
        guard api.isLoggedIn else { return }
        loading = true
        defer { loading = false }
        errorMessage = nil
        let account = api.currentUser?.id
        do {
            let (data, response) = try await URLSession.shared.data(for: request("/api/v1/subscription/manage"))
            guard (response as? HTTPURLResponse)?.statusCode == 200, account == api.currentUser?.id else { throw URLError(.badServerResponse) }
            subscriptions = try JSONDecoder().decode(ListResponse.self, from: data).subscriptions
        } catch {
            errorMessage = tr("契約情報を確認できませんでした。再読み込みするか、サポートへご連絡ください。")
        }
    }

    @MainActor private func cancelWebSubscription(_ sub: ManagedSubscription) async {
        changing = true
        defer { changing = false }
        errorMessage = nil
        message = nil
        do {
            let (data, response) = try await URLSession.shared.data(for: request("/api/v1/subscription/cancel", body: ["subscription_id": sub.id, "lang": L10n.language]))
            guard (response as? HTTPURLResponse)?.statusCode == 200,
                  try JSONDecoder().decode(CancelResponse.self, from: data).cancel_at_period_end else { throw URLError(.badServerResponse) }
            message = tr("自動更新は停止済みです。")
            await loadWebSubscriptions()
        } catch {
            errorMessage = tr("解約の完了を確認できませんでした。契約状況を再読み込みして確認してください。")
        }
    }

    @MainActor private func openAppleManagement() async {
        changing = true
        defer { changing = false }
        errorMessage = nil
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first(where: { $0.activationState == .foregroundActive }) else {
            errorMessage = tr("Appleの管理画面を開けませんでした。iPhoneの設定→Apple Account→サブスクリプションから確認できます。")
            return
        }
        do {
            try await AppStore.showManageSubscriptions(in: scene)
            await store.updatePurchasedProducts()
            // Returning from the sheet is NOT evidence of cancellation.
        } catch {
            errorMessage = tr("Appleの管理画面を開けませんでした。iPhoneの設定→Apple Account→サブスクリプションから確認できます。")
        }
    }
}

// MARK: - Profile Edit View

struct ProfileEditView: View {
    @EnvironmentObject var api: APIService
    @State private var displayName: String = ""
    @State private var belt: String = "white"
    @State private var weight: String = ""
    @State private var dojo: String = ""
    @State private var yearsTraining: String = ""
    @State private var bio: String = ""
    @State private var goals: String = ""
    @State private var isSaving = false
    @State private var result: String?
    @State private var showPhotoPicker = false
    @State private var avatarImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    private let beltOptions = [
        ("white", tr("白帯")), ("blue", tr("青帯")), ("purple", tr("紫帯")),
        ("brown", tr("茶帯")), ("black", tr("黒帯"))
    ]

    private let beltColors: [String: Color] = [
        "white": .gray, "blue": .blue, "purple": .purple,
        "brown": .brown, "black": .red
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                // Avatar
                avatarSection

                // Basic info
                profileSection(title: tr("基本情報"), icon: "person.fill") {
                    profileField(tr("表示名"), text: $displayName, placeholder: tr("名前を入力"))
                    profileField(tr("所属道場"), text: $dojo, placeholder: tr("道場名"))
                    profileField(tr("柔術歴（年）"), text: $yearsTraining, placeholder: tr("例: 3"), keyboard: .numberPad)
                }

                // Belt
                profileSection(title: tr("帯"), icon: "circle.hexagongrid.fill") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(beltOptions, id: \.0) { id, name in
                                Button {
                                    belt = id
                                } label: {
                                    VStack(spacing: 4) {
                                        Circle()
                                            .fill(beltColors[id] ?? .gray)
                                            .frame(width: 32, height: 32)
                                            .overlay(
                                                Circle()
                                                    .stroke(belt == id ? Color.white : Color.clear, lineWidth: 2)
                                            )
                                        Text(name)
                                            .font(.caption2.bold())
                                            .foregroundStyle(belt == id ? Color.jfTextPrimary : Color.jfTextTertiary)
                                    }
                                }
                            }
                        }
                    }
                }

                // Physical
                profileSection(title: tr("体格"), icon: "scalemass.fill") {
                    profileField(tr("体重 (kg)"), text: $weight, placeholder: tr("例: 75.0"), keyboard: .decimalPad)
                }

                // Bio
                profileSection(title: tr("自己紹介"), icon: "text.quote") {
                    TextEditor(text: $bio)
                        .frame(minHeight: 80)
                        .scrollContentBackground(.hidden)
                        .background(Color.jfCardBg)
                        .foregroundStyle(Color.jfTextPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            Group {
                                if bio.isEmpty {
                                    Text(tr("柔術を始めたきっかけ、得意技など"))
                                        .font(.subheadline)
                                        .foregroundStyle(Color.jfTextTertiary.opacity(0.5))
                                        .padding(.horizontal, 4)
                                        .padding(.top, 8)
                                        .allowsHitTesting(false)
                                }
                            }, alignment: .topLeading
                        )
                }

                // Goals
                profileSection(title: tr("目標"), icon: "target") {
                    TextEditor(text: $goals)
                        .frame(minHeight: 60)
                        .scrollContentBackground(.hidden)
                        .background(Color.jfCardBg)
                        .foregroundStyle(Color.jfTextPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            Group {
                                if goals.isEmpty {
                                    Text(tr("例: 青帯を取る、大会で1勝する"))
                                        .font(.subheadline)
                                        .foregroundStyle(Color.jfTextTertiary.opacity(0.5))
                                        .padding(.horizontal, 4)
                                        .padding(.top, 8)
                                        .allowsHitTesting(false)
                                }
                            }, alignment: .topLeading
                        )
                }

                // Save
                Button {
                    Task { await save() }
                } label: {
                    HStack {
                        if isSaving { ProgressView().tint(.white) }
                        Text(isSaving ? tr("保存中...") : tr("プロフィールを保存"))
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        Group {
                            if displayName.isEmpty { Color.gray.opacity(0.4) }
                            else { LinearGradient.jfRedGradient }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(displayName.isEmpty || isSaving)

                if let r = result {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        Text(r).font(.caption).foregroundStyle(.green)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .background(Color.jfDarkBg)
        .navigationTitle(tr("プロフィール編集"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadProfile() }
    }

    // MARK: - Avatar

    private var avatarSection: some View {
        VStack(spacing: 10) {
            Button { showPhotoPicker = true } label: {
                ZStack(alignment: .bottomTrailing) {
                    if let img = avatarImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 90, height: 90)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(beltColors[belt]?.opacity(0.15) ?? Color.gray.opacity(0.15))
                            .frame(width: 90, height: 90)
                            .overlay(
                                Text(String(displayName.prefix(1).uppercased()))
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundStyle(beltColors[belt] ?? .gray)
                            )
                    }

                    ZStack {
                        Circle().fill(Color.jfRed).frame(width: 28, height: 28)
                        Image(systemName: "camera.fill")
                            .font(.caption2)
                            .foregroundStyle(.white)
                    }
                    .offset(x: 2, y: 2)
                }
                .overlay(
                    Circle()
                        .stroke(beltColors[belt] ?? .gray, lineWidth: 3)
                        .padding(-3)
                )
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhoto, matching: .images)

            if !displayName.isEmpty {
                Text(displayName)
                    .font(.title3.bold())
                    .foregroundStyle(Color.jfTextPrimary)
            }
            if !dojo.isEmpty {
                Label(dojo, systemImage: "building.2.fill")
                    .font(.caption)
                    .foregroundStyle(Color.jfTextTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
        .onChange(of: selectedPhoto) { _, newValue in
            Task { await loadPhoto(newValue) }
        }
    }

    @State private var selectedPhoto: PhotosPickerItem?

    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item = item,
              let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data) else { return }
        avatarImage = uiImage
        // Save locally
        if let jpegData = uiImage.jpegData(compressionQuality: 0.7) {
            UserDefaults.standard.set(jpegData, forKey: "profile_avatar")
        }
    }

    // MARK: - Helpers

    private func profileSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(Color.jfRed)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.jfTextPrimary)
            }
            content()
        }
        .padding(14)
        .glassCard()
    }

    private func profileField(_ label: String, text: Binding<String>, placeholder: String, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.jfTextTertiary)
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .padding(10)
                .background(Color.jfCardBg)
                .foregroundStyle(Color.jfTextPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Load / Save

    private func loadProfile() {
        displayName = api.currentUser?.display_name ?? ""
        // Load avatar
        if let imgData = UserDefaults.standard.data(forKey: "profile_avatar") {
            avatarImage = UIImage(data: imgData)
        }
        // Load saved profile from UserDefaults
        belt = UserDefaults.standard.string(forKey: "profile_belt") ?? "white"
        weight = UserDefaults.standard.string(forKey: "profile_weight") ?? ""
        dojo = UserDefaults.standard.string(forKey: "profile_dojo") ?? ""
        yearsTraining = UserDefaults.standard.string(forKey: "profile_years") ?? ""
        bio = UserDefaults.standard.string(forKey: "profile_bio") ?? ""
        goals = UserDefaults.standard.string(forKey: "profile_goals") ?? ""
    }

    private func save() async {
        isSaving = true
        // Save locally
        UserDefaults.standard.set(belt, forKey: "profile_belt")
        UserDefaults.standard.set(weight, forKey: "profile_weight")
        UserDefaults.standard.set(dojo, forKey: "profile_dojo")
        UserDefaults.standard.set(yearsTraining, forKey: "profile_years")
        UserDefaults.standard.set(bio, forKey: "profile_bio")
        UserDefaults.standard.set(goals, forKey: "profile_goals")

        // Save display name to server
        guard let url = URL(string: "\(api.baseURL)/mypage/profile") else {
            isSaving = false
            return
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        if let t = api.authToken { req.setValue("Bearer \(t)", forHTTPHeaderField: "Authorization") }
        let encoded = displayName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        req.httpBody = "display_name=\(encoded)".data(using: .utf8)
        do {
            let (_, response) = try await URLSession.shared.data(for: req)
            if let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode {
                result = tr("プロフィールを保存しました！")
            } else {
                result = tr("保存しました（ローカル）")
            }
        } catch {
            result = tr("保存しました（ローカル）")
        }
        isSaving = false
    }
}
