import StoreKit
import SwiftUI

@MainActor
class StoreManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var confirmedTier: String?
    private var confirmedToken: String?
    private var confirmedUntil: Date?

    var accountTier: String? {
        guard confirmedToken == tokenProvider(), let confirmedUntil, confirmedUntil > Date() else { return nil }
        return confirmedTier
    }

    func resetAccountSync() {
        confirmedToken = nil
        confirmedUntil = nil
        confirmedTier = nil
    }

    private let productIDs = [
        "jiuflow_pro_monthly",
        "jiuflow_blackbelt_monthly",
        // JiuFlow Kids（受け身採点アプリ連動・大人と同額¥1,500/月、2人目以降50%OFF¥750）
        // ⚠ App Store Connect でこのIAPサブスク商品を作成するまで Product.products は返らない
        "jiuflow_kids_monthly",
        "jiuflow_kids_sibling_monthly"
    ]

    private var updateListenerTask: Task<Void, Error>?
    private let receiptSession: URLSession
    private let receiptProvider: () -> Data?
    private let tokenProvider: () -> String?
    private var receiptSyncInFlight = false

    init(
        receiptSession: URLSession = .shared,
        receiptProvider: @escaping () -> Data? = {
            guard let url = Bundle.main.appStoreReceiptURL else { return nil }
            return try? Data(contentsOf: url)
        },
        tokenProvider: @escaping () -> String? = { KeychainHelper.loadString("auth_token") },
        startStoreKit: Bool = true
    ) {
        self.receiptSession = receiptSession
        self.receiptProvider = receiptProvider
        self.tokenProvider = tokenProvider
        guard startStoreKit else { return }
        updateListenerTask = listenForTransactions()
        Task { await loadProducts() }
        Task {
            await updatePurchasedProducts()
            await submitReceiptToServer()
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
    @discardableResult
    func submitReceiptToServer() async -> Bool {
        // The endpoint requires a logged-in account. Retry after login/foreground
        // from StoreKit's persisted entitlements rather than sending anonymous receipts.
        guard !receiptSyncInFlight,
              let token = tokenProvider(), !token.isEmpty,
              let receiptData = receiptProvider(), !receiptData.isEmpty else { return false }
        receiptSyncInFlight = true
        defer { receiptSyncInFlight = false }
        let base64 = receiptData.base64EncodedString()
        guard let url = URL(string: "https://jiuflow-ssr.fly.dev/api/v1/subscription/verify-apple") else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: ["receipt_data": base64])
            let (data, response) = try await receiptSession.data(for: request)
            guard tokenProvider() == token else { return false }
            guard let http = response as? HTTPURLResponse else { return false }
            if http.statusCode == 409 || http.statusCode == 401 {
                resetAccountSync()
                return false
            }
            guard 200..<300 ~= http.statusCode,
                  let body = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tier = body["tier"] as? String, ["free", "pro", "blackbelt"].contains(tier),
                  let status = body["status"] as? String, ["active", "inactive"].contains(status) else {
                print("[StoreManager] receipt sync not confirmed")
                return false
            }
            var validUntil = Date().addingTimeInterval(300)
            if status == "active" {
                guard let productID = body["product_id"] as? String, productIDs.contains(productID),
                      let expires = body["expires_ms"] as? NSNumber,
                      expires.doubleValue > Date().timeIntervalSince1970 * 1000 else { return false }
                validUntil = min(validUntil, Date(timeIntervalSince1970: expires.doubleValue / 1000))
            }
            confirmedToken = token
            confirmedUntil = validUntil
            confirmedTier = tier
            print("[StoreManager] receipt sync confirmed")
            return true
        } catch {
            // Receipts, bearer tokens and response bodies must not enter logs.
            print("[StoreManager] receipt sync unavailable; retry on login or foreground")
            return false
        }
    }

    func recoverReceiptSync() async {
        await updatePurchasedProducts()
        // Expired/refunded receipts must also reach the server to revoke old access.
        await submitReceiptToServer()
    }

    func updatePurchasedProducts() async {
        var purchased = Set<String>()
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               productIDs.contains(transaction.productID), transaction.revocationDate == nil,
               !transaction.isUpgraded,
               let expires = transaction.expirationDate, expires > Date() {
                purchased.insert(transaction.productID)
            }
        }
        purchasedProductIDs = purchased
    }

    func restorePurchases() async {
        do { try await AppStore.sync() }
        catch {
            print("[StoreManager] App Store restore failed")
            return
        }
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
                    // Report observed transactions. Server notifications are still
                    // needed for changes while the app is not running.
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
