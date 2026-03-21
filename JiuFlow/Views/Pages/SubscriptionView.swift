import SwiftUI

struct SubscriptionView: View {
    @EnvironmentObject var api: APIService
    @State private var currentPlan: String?
    @State private var isLoading = true

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                if isLoading {
                    LoadingWithTips()
                } else {
                    // Current plan
                    currentPlanCard

                    // Plans
                    planCard(name: "Founder", price: "¥980/月", desc: "全動画・テクニックマップ・ゲームプラン", color: .jfRed, id: "founder")
                    planCard(name: "Regular", price: "¥2,900/月", desc: "AI解析・優先サポート・全機能", color: .blue, id: "regular")
                    planCard(name: "年間プラン", price: "¥29,000/年", desc: "2ヶ月分お得・限定コンテンツ", color: .green, id: "annual")

                    Text("初月無料トライアル付き")
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                }
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .background(Color.jfDarkBg)
        .navigationTitle("サブスクリプション")
        .navigationBarTitleDisplayMode(.large)
        .task { await loadSubscription() }
    }

    private var currentPlanCard: some View {
        VStack(spacing: 8) {
            Image(systemName: currentPlan != nil ? "checkmark.seal.fill" : "person.crop.circle")
                .font(.system(size: 36))
                .foregroundStyle(currentPlan != nil ? .green : Color.jfTextTertiary)
            Text(currentPlan != nil ? "プラン: \(currentPlan!)" : "フリープラン")
                .font(.headline)
                .foregroundStyle(Color.jfTextPrimary)
            Text(currentPlan != nil ? "有効なサブスクリプションがあります" : "無料機能のみ利用可能")
                .font(.caption)
                .foregroundStyle(Color.jfTextTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .glassCard()
    }

    private func planCard(name: String, price: String, desc: String, color: Color, id: String) -> some View {
        Button {
            Task { await checkout(planId: id) }
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.headline)
                        .foregroundStyle(color)
                    Text(price)
                        .font(.title3.bold())
                        .foregroundStyle(Color.jfTextPrimary)
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Text("選択")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(color)
                    .clipShape(Capsule())
            }
            .padding(14)
            .glassCard()
        }
    }

    private func loadSubscription() async {
        guard let url = URL(string: "\(api.baseURL)/api/v1/subscription"),
              let token = api.authToken else {
            isLoading = false
            return
        }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                currentPlan = json["plan"] as? String
            }
        } catch { }
        isLoading = false
    }

    private func checkout(planId: String) async {
        guard let url = URL(string: "\(api.baseURL)/api/v1/subscription/checkout"),
              let token = api.authToken else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["plan_id": planId])
        if let (data, _) = try? await URLSession.shared.data(for: req),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let checkoutURL = json["url"] as? String,
           let url = URL(string: checkoutURL) {
            await MainActor.run { UIApplication.shared.open(url) }
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
