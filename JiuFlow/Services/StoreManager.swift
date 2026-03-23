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
        "jiuflow_blackbelt_monthly"
    ]

    private var updateListenerTask: Task<Void, Error>?

    init() {
        updateListenerTask = listenForTransactions()
        Task { await loadProducts() }
        Task { await updatePurchasedProducts() }
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
    }

    var hasActiveSubscription: Bool {
        !purchasedProductIDs.isEmpty
    }

    var currentPlanName: String? {
        if purchasedProductIDs.contains("jiuflow_blackbelt_monthly") { return "BLACK BELT" }
        if purchasedProductIDs.contains("jiuflow_pro_monthly") { return "PRO" }
        return nil
    }

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
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
