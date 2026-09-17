import StoreKit
import SwiftUI

@MainActor
class StoreManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let productIDs = [
        "jiuflow_pro_monthly",
        "jiuflow_blackbelt_monthly",
        // JiuFlow Kids（受け身採点アプリ連動・大人と同額¥1,500/月、2人目以降50%OFF¥750）
        // ⚠ App Store Connect でこのIAPサブスク商品を作成するまで Product.products は返らない
        "jiuflow_kids_monthly",
        "jiuflow_kids_sibling_monthly"
    ]

    private var updateListenerTask: Task<Void, Error>?

    init() {
        updateListenerTask = listenForTransactions()
        Task { await loadProducts() }
        Task {
            await updatePurchasedProducts()
            // Recover entitlements bought before server reporting existed.
            if hasActiveSubscription {
                await submitReceiptToServer()
            }
        }
    }

    deinit { updateListenerTask?.cancel() }

    func loadProducts() async {
        isLoading = true
        do {
            products = try await Product.products(for: productIDs)
                .sorted { $0.price < $1.price }
        } catch {
            errorMessage = "商品の読み込みに失敗しました"
        }
        isLoading = false
    }

    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await submitReceiptToServer()
            await transaction.finish()
            await updatePurchasedProducts()
            return true
        case .userCancelled:
            return false
        case .pending:
            return false
        @unknown default:
            return false
        }
    }

    /// Send the App Store receipt to jiuflow-ssr so the subscription is
    /// recorded server-side. Without this, `subscriptions.apple_product_id`
    /// stays NULL and the user is not recognised as paying on other devices,
    /// after reinstall, or on the web.
    func submitReceiptToServer() async {
        guard let receiptURL = Bundle.main.appStoreReceiptURL,
              FileManager.default.fileExists(atPath: receiptURL.path),
              let receiptData = try? Data(contentsOf: receiptURL) else {
            print("[StoreManager] no app store receipt available")
            return
        }
        let base64 = receiptData.base64EncodedString()
        guard let url = URL(string: "https://jiuflow-ssr.fly.dev/api/v1/subscription/verify-apple") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = KeychainHelper.loadString("auth_token"), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["receipt_data": base64])
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let body = String(data: data, encoding: .utf8) ?? ""
            if let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode {
                print("[StoreManager] receipt verified: \(body)")
            } else {
                print("[StoreManager] receipt verify failed: \(body)")
            }
        } catch {
            print("[StoreManager] receipt verify error: \(error)")
        }
    }

    func updatePurchasedProducts() async {
        var purchased = Set<String>()
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                purchased.insert(transaction.productID)
            }
        }
        purchasedProductIDs = purchased
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await updatePurchasedProducts()
        await submitReceiptToServer()
    }

    var hasActiveSubscription: Bool {
        !purchasedProductIDs.isEmpty
    }

    var currentPlanName: String? {
        if purchasedProductIDs.contains("jiuflow_blackbelt_monthly") { return "BLACK BELT" }
        if purchasedProductIDs.contains("jiuflow_pro_monthly") { return "PRO" }
        if purchasedProductIDs.contains("jiuflow_kids_monthly") || purchasedProductIDs.contains("jiuflow_kids_sibling_monthly") { return "KIDS" }
        return nil
    }

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    // Renewals, expiries and revocations all arrive here.
                    // Report them so the server's apple_expires_at stays current.
                    await self.submitReceiptToServer()
                    await transaction.finish()
                    await self.updatePurchasedProducts()
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    enum StoreError: Error {
        case failedVerification
    }
}
