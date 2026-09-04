import SwiftUI
import SwiftData
import UserNotifications

@main
struct JiuFlowApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var api = APIService()
    @StateObject private var lang = LanguageManager()
    @StateObject private var premium = PremiumManager()
    @StateObject private var store = StoreManager()
    @State private var showAuthError = false

    var body: some Scene {
        WindowGroup {
            ModelContextInjector(api: api) {
                ContentView()
                    .id(lang.current)   // rebuild the tree on language change so tr() strings refresh
            }
            .environmentObject(api)
            .environmentObject(lang)
            .environmentObject(premium)
            .environmentObject(store)
            .preferredColorScheme(.dark)
            .modelContainer(for: [CachedAthlete.self, CachedTournament.self])
            .onOpenURL { url in
                handleDeepLink(url)
            }
            .onChange(of: api.currentUser?.id) { _, newValue in
                syncPremium()
                if newValue != nil { requestAndRegisterPush() }
            }
            .onChange(of: api.currentUser?.role) { _, _ in
                syncPremium()
            }
            .onChange(of: store.purchasedProductIDs) { _, _ in
                syncPremium()
            }
            .onChange(of: api.authError) { _, newValue in
                if newValue != nil { showAuthError = true }
            }
            .onAppear {
                syncPremium()
                appDelegate.api = api
            }
            .task {
                // 起動時に全データを並列フェッチ
                await api.loadAllInParallel()
            }
            .overlay {
                if api.isAuthenticating {
                    ZStack {
                        Color.black.opacity(0.5).ignoresSafeArea()
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            Text("Logging in...")
                                .foregroundStyle(.white)
                                .font(.headline)
                        }
                        .padding(32)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            .alert("Login Error", isPresented: $showAuthError) {
                Button("OK") { api.authError = nil }
            } message: {
                Text(api.authError ?? "An unknown error occurred during login. Please try again.")
            }
        }
    }

    private func requestAndRegisterPush() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    private func syncPremium() {
        if let user = api.currentUser, user.isPro {
            premium.unlock()
        } else if store.hasActiveSubscription {
            premium.unlock()
        }
    }

    private func handleDeepLink(_ url: URL) {
        // Custom URL scheme: jiuflow://auth/callback?code=OTT_CODE
        // Custom URL scheme (legacy): jiuflow://auth/callback?token=SESSION_TOKEN
        // Universal Link: https://jiuflow-ssr.fly.dev/auth/magic/verify?token=xxx&platform=ios
        // Universal Link: https://jiuflow.com/auth/magic/verify?token=xxx&platform=ios

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }

        // Case 1: Custom URL scheme (jiuflow://)
        if url.scheme == "jiuflow" {
            guard url.host == "auth" else { return }

            if let code = components.queryItems?.first(where: { $0.name == "code" })?.value {
                Task { @MainActor in
                    await api.exchangeOTTCode(code)
                }
            } else if let token = components.queryItems?.first(where: { $0.name == "token" })?.value {
                Task { @MainActor in
                    api.loginWithSessionToken(token)
                }
            }
            return
        }

        // Case 2: Universal Link (https:// from jiuflow-ssr.fly.dev or jiuflow.com)
        if url.scheme == "https",
           let host = url.host,
           (host == "jiuflow-ssr.fly.dev" || host == "v2.jiuflow.art" || host == "jiuflow.com"),
           (components.path.contains("/auth/magic/verify")),
           let token = components.queryItems?.first(where: { $0.name == "token" })?.value {
            // Dedupe: iPadOS may fire onOpenURL twice for the same Universal Link
            // (Safari preflight + app handover). Skip if we saw this token recently.
            if UniversalLinkDedup.shared.shouldSkip(token: token) { return }
            // Use the API endpoint to verify the magic token directly
            Task { @MainActor in
                await api.verifyMagicLinkFromUniversalLink(token: token)
            }
        }
    }
}

// MARK: - Universal Link Dedup

/// Prevents double-consumption of magic tokens when iOS fires onOpenURL multiple times
/// for the same Universal Link (common on iPadOS 26).
final class UniversalLinkDedup {
    static let shared = UniversalLinkDedup()
    private var recent: [(token: String, at: Date)] = []
    private let window: TimeInterval = 30
    private let queue = DispatchQueue(label: "universal-link-dedup")

    func shouldSkip(token: String) -> Bool {
        queue.sync {
            let now = Date()
            recent.removeAll { now.timeIntervalSince($0.at) > window }
            if recent.contains(where: { $0.token == token }) { return true }
            recent.append((token, now))
            return false
        }
    }
}

// MARK: - AppDelegate for APNs token

class AppDelegate: NSObject, UIApplicationDelegate {
    var api: APIService?

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        Task { try? await api?.registerPushToken(token) }
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("APNs registration failed: \(error)")
    }
}

// MARK: - ModelContext Injector
// Bridges SwiftData's @Environment(\.modelContext) into the ObservableObject APIService

struct ModelContextInjector<Content: View>: View {
    @Environment(\.modelContext) private var modelContext
    let api: APIService
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .onAppear {
                api.modelContext = modelContext
            }
    }
}
