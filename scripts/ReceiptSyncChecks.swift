import Foundation

// Runs the production StoreManager with a local URLProtocol, without purchases,
// credentials, a network connection, or a simulator.
final class ReceiptProtocol: URLProtocol {
    static var status = 200
    static var body = Data()
    static var failure: URLError?
    static var calls = 0
    static var onRequest: ((URLRequest) -> Void)?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.calls += 1
        Self.onRequest?(request)
        if let error = Self.failure {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        let response = HTTPURLResponse(url: request.url!, statusCode: Self.status,
                                       httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.body)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

@main
struct ReceiptSyncChecks {
    @MainActor static func main() async throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [ReceiptProtocol.self]
        let session = URLSession(configuration: config)
        defer { session.invalidateAndCancel() }
        var token: String? = nil
        var receipt: Data? = Data("test-receipt".utf8)
        let store = StoreManager(receiptSession: session, receiptProvider: { receipt },
                                 tokenProvider: { token }, startStoreKit: false)
        func check(_ result: Bool, _ label: String) {
            precondition(result, label)
            print("PASS: \(label)")
        }
        func response(_ status: String = "active", product: String = "jiuflow_pro_monthly",
                      expires: Double = Date().timeIntervalSince1970 * 1000 + 60000) throws {
            ReceiptProtocol.body = try JSONSerialization.data(withJSONObject: [
                "status": status, "product_id": product, "expires_ms": expires, "tier": "pro"
            ])
        }
        check(await store.submitReceiptToServer() == false && ReceiptProtocol.calls == 0,
              "logged-out receipt is not sent")
        token = "local-test-token"
        receipt = nil
        check(await store.submitReceiptToServer() == false && ReceiptProtocol.calls == 0,
              "missing receipt is not sent")
        receipt = Data("test-receipt".utf8)
        ReceiptProtocol.onRequest = { request in
            precondition(request.httpMethod == "POST")
            precondition(request.value(forHTTPHeaderField: "Authorization") == "Bearer local-test-token")
            precondition(request.timeoutInterval == 20)
        }
        try response("invalid")
        check(await store.submitReceiptToServer() == false, "HTTP 200 invalid is not success")
        try response(product: "unrelated_product")
        check(await store.submitReceiptToServer() == false, "unrelated product is rejected")
        try response(expires: 1)
        check(await store.submitReceiptToServer() == false, "expired receipt is not active")
        try response()
        ReceiptProtocol.status = 401
        check(await store.submitReceiptToServer() == false, "HTTP 401 is not success")
        ReceiptProtocol.status = 200
        ReceiptProtocol.failure = URLError(.notConnectedToInternet)
        check(await store.submitReceiptToServer() == false, "offline attempt fails explicitly")
        ReceiptProtocol.failure = nil
        check(await store.submitReceiptToServer(), "same receipt retries successfully after reconnect/login")
        check(store.accountTier == "pro", "confirmed tier belongs to current account")
        ReceiptProtocol.onRequest = { _ in token = "another-test-account" }
        check(await store.submitReceiptToServer() == false, "account change ignores stale response")
        check(store.accountTier == nil, "old account grant is not reused")
        ReceiptProtocol.onRequest = nil
        ReceiptProtocol.body = Data("not-json".utf8)
        check(await store.submitReceiptToServer() == false, "malformed response is not success")
        ReceiptProtocol.body = try JSONSerialization.data(withJSONObject: ["status":"inactive", "tier":"free"])
        check(await store.submitReceiptToServer() && store.accountTier == "free", "revocation sync locks account")
        try response()
        check(await store.submitReceiptToServer(), "active grant restored by confirmed server response")
        ReceiptProtocol.status = 409
        check(await store.submitReceiptToServer() == false && store.accountTier == nil, "ownership conflict clears grant")
        print("15 receipt sync checks passed; StoreKit/Sandbox remains unverified")
    }
}
