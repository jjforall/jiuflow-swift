import SwiftUI

@main
struct JiuFlowApp: App {
    @StateObject private var api = APIService()
    @StateObject private var lang = LanguageManager()
    @StateObject private var premium = PremiumManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(api)
                .environmentObject(lang)
                .environmentObject(premium)
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .onChange(of: api.currentUser?.id) { _, _ in
                    syncPremium()
                }
                .onAppear { syncPremium() }
        }
    }

    private func syncPremium() {
        if let user = api.currentUser, user.isPro {
            premium.unlock()
        }
    }

    private func handleDeepLink(_ url: URL) {
        // jiuflow://auth/callback?token=SESSION_TOKEN
        // The server already verified the magic token and created a session.
        // The token in the URL IS the session token — just store it directly.
        guard url.scheme == "jiuflow",
              url.host == "auth",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let token = components.queryItems?.first(where: { $0.name == "token" })?.value
        else { return }

        Task { @MainActor in
            api.loginWithSessionToken(token)
        }
    }
}
