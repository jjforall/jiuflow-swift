import SwiftUI
import StoreKit

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

                if store.isLoading {
                    LoadingWithTips()
                } else if store.products.isEmpty {
                    emptyProductsView
                } else {
                    // Plan cards from StoreKit
                    ForEach(store.products, id: \.id) { product in
                        productCard(product)
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
        .navigationTitle("サブスクリプション")
        .navigationBarTitleDisplayMode(.large)
        .overlay {
            if isPurchasing {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .overlay {
                        ProgressView("購入処理中...")
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
            Text(store.currentPlanName.map { "プラン: \($0)" } ?? "フリープラン")
                .font(.headline)
                .foregroundStyle(Color.jfTextPrimary)
            Text(store.hasActiveSubscription ? "有効なサブスクリプションがあります" : "無料機能のみ利用可能")
                .font(.caption)
                .foregroundStyle(Color.jfTextTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .glassCard()
    }

    // MARK: - Empty Products

    private var emptyProductsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28))
                .foregroundStyle(Color.jfTextTertiary)
            Text("プランを読み込めませんでした")
                .font(.subheadline)
                .foregroundStyle(Color.jfTextSecondary)
            Button("再読み込み") {
                Task { await store.loadProducts() }
            }
            .font(.caption.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.jfRed)
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .glassCard()
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
                            Text("現在のプラン")
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
                    Text("選択")
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
        case "jiuflow_founder_monthly":
            return PlanInfo(name: "Founder", desc: "全動画・テクニックマップ・ゲームプラン", color: .jfRed)
        case "jiuflow_regular_monthly":
            return PlanInfo(name: "Regular", desc: "AI解析・優先サポート・全機能", color: .blue)
        case "jiuflow_annual":
            return PlanInfo(name: "年間プラン", desc: "2ヶ月分お得・限定コンテンツ", color: .green)
        default:
            return PlanInfo(name: productID, desc: "", color: .gray)
        }
    }

    private func periodLabel(_ product: Product) -> String {
        guard let sub = product.subscription else { return "" }
        switch sub.subscriptionPeriod.unit {
        case .month:
            return sub.subscriptionPeriod.value == 1 ? "/月" : "/\(sub.subscriptionPeriod.value)ヶ月"
        case .year:
            return sub.subscriptionPeriod.value == 1 ? "/年" : "/\(sub.subscriptionPeriod.value)年"
        case .week:
            return "/週"
        case .day:
            return "/日"
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
            purchaseError = "購入に失敗しました: \(error.localizedDescription)"
        }
        isPurchasing = false
    }

    // MARK: - Manage Subscription

    private var manageSection: some View {
        VStack(spacing: 10) {
            if store.hasActiveSubscription {
                Button {
                    Task { await openSubscriptionManagement() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "creditcard.fill")
                            .font(.subheadline)
                        Text("プランを変更・解約")
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
            }

            Button {
                Task { await store.restorePurchases() }
            } label: {
                Text("購入を復元")
                    .font(.caption.bold())
                    .foregroundStyle(Color.jfTextTertiary)
            }

            HStack(spacing: 16) {
                Link("利用規約", destination: URL(string: "https://jiuflow.art/terms")!)
                    .font(.caption2).foregroundStyle(Color.jfTextTertiary)
                Link("プライバシー", destination: URL(string: "https://jiuflow.art/privacy")!)
                    .font(.caption2).foregroundStyle(Color.jfTextTertiary)
            }
        }
    }

    @MainActor
    private func openSubscriptionManagement() async {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            try? await AppStore.showManageSubscriptions(in: windowScene)
        }
    }
}

// MARK: - Profile Edit View

struct ProfileEditView: View {
    @EnvironmentObject var api: APIService
    @State private var displayName: String = ""
    @State private var isSaving = false
    @State private var result: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("表示名")
                    .font(.headline)
                    .foregroundStyle(Color.jfTextPrimary)
                TextField("名前を入力", text: $displayName)
                    .padding(12)
                    .background(Color.jfCardBg)
                    .foregroundStyle(Color.jfTextPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(16)
            .glassCard()

            Button {
                Task { await save() }
            } label: {
                HStack {
                    if isSaving { ProgressView().tint(.white) }
                    Text(isSaving ? "保存中..." : "保存")
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
                Text(r).font(.caption).foregroundStyle(.green)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.jfDarkBg)
        .navigationTitle("プロフィール編集")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            displayName = api.currentUser?.display_name ?? ""
        }
    }

    private func save() async {
        isSaving = true
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
            if let http = response as? HTTPURLResponse, 200..<400 ~= http.statusCode {
                result = "保存しました！"
            }
        } catch { }
        isSaving = false
    }
}
