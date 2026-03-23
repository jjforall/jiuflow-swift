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

                // 7-day free trial
                if !store.hasActiveSubscription {
                    HStack(spacing: 8) {
                        Image(systemName: "gift.fill")
                            .foregroundStyle(Color.jfGold)
                        Text("7日間無料トライアル付き")
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

                    // StoreKit product cards (if available)
                    if !store.products.isEmpty {
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
                    name: "PRO", price: "¥1,480", period: "/月",
                    color: .jfRed, isHighlighted: true,
                    badge: "POPULAR"
                )
                // Black Belt
                tierPlanCard(
                    name: "BLACK BELT", price: "¥4,900", period: "/月",
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
            tierFeatureRow("動画", "月5本", "無制限", "無制限+4K")
            tierFeatureRow("ゲームプラン", "3個", "全17+保存5", "全17+AI生成")
            tierFeatureRow("AI良蔵", "月3回", "月30回", "無制限")
            tierFeatureRow("練習日記", "月3回", "無制限", "無制限+AI")
            tierFeatureRow("大会エントリー", "通常", "通常", "10%OFF")
            tierFeatureRow("ライブクラス", "—", "アーカイブ", "ライブ+録画")
            tierFeatureRow("フォーラム", "閲覧+投稿", "+PROバッジ", "+専用")
            tierFeatureRow("広告", "あり", "なし", "なし")
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
        ("white", "白帯"), ("blue", "青帯"), ("purple", "紫帯"),
        ("brown", "茶帯"), ("black", "黒帯")
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
                profileSection(title: "基本情報", icon: "person.fill") {
                    profileField("表示名", text: $displayName, placeholder: "名前を入力")
                    profileField("所属道場", text: $dojo, placeholder: "道場名")
                    profileField("柔術歴（年）", text: $yearsTraining, placeholder: "例: 3", keyboard: .numberPad)
                }

                // Belt
                profileSection(title: "帯", icon: "circle.hexagongrid.fill") {
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
                profileSection(title: "体格", icon: "scalemass.fill") {
                    profileField("体重 (kg)", text: $weight, placeholder: "例: 75.0", keyboard: .decimalPad)
                }

                // Bio
                profileSection(title: "自己紹介", icon: "text.quote") {
                    TextEditor(text: $bio)
                        .frame(minHeight: 80)
                        .scrollContentBackground(.hidden)
                        .background(Color.jfCardBg)
                        .foregroundStyle(Color.jfTextPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            Group {
                                if bio.isEmpty {
                                    Text("柔術を始めたきっかけ、得意技など")
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
                profileSection(title: "目標", icon: "target") {
                    TextEditor(text: $goals)
                        .frame(minHeight: 60)
                        .scrollContentBackground(.hidden)
                        .background(Color.jfCardBg)
                        .foregroundStyle(Color.jfTextPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            Group {
                                if goals.isEmpty {
                                    Text("例: 青帯を取る、大会で1勝する")
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
                        Text(isSaving ? "保存中..." : "プロフィールを保存")
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
        .navigationTitle("プロフィール編集")
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
                result = "プロフィールを保存しました！"
            } else {
                result = "保存しました（ローカル）"
            }
        } catch {
            result = "保存しました（ローカル）"
        }
        isSaving = false
    }
}
