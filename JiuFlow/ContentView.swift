import SwiftUI

struct ContentView: View {
    @EnvironmentObject var api: APIService
    @EnvironmentObject var lang: LanguageManager
    @State private var selectedTab = 0
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showOnboarding = false

    init() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(red: 0.04, green: 0.04, blue: 0.04, alpha: 1.0)
        tabBarAppearance.shadowColor = .clear
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().unselectedItemTintColor = UIColor.white.withAlphaComponent(0.35)

        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor.black
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.shadowColor = .clear
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
    }

    @State private var showQuickLog = false
    @State private var lastTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeDashboardTab()
                    .fabClearance()
                    .tabItem {
                        Label(lang.t("ホーム", en: "Home"), systemImage: "house.fill")
                    }
                    .tag(0)

                LearnTab()
                    .fabClearance()
                    .tabItem {
                        Label(lang.t("学ぶ", en: "Learn"), systemImage: "book.fill")
                    }
                    .tag(1)

                // Placeholder for center button
                Color.clear
                    .tabItem {
                        Label(lang.t("記録", en: "Log"), systemImage: "pencil.and.list.clipboard")
                    }
                    .tag(99)

                WearableTab()
                    .fabClearance()
                    .tabItem {
                        Label(lang.t("練習", en: "Train"), systemImage: "figure.martial.arts")
                    }
                    .tag(3)

                MyPageTab()
                    .fabClearance()
                    .tabItem {
                        Label(lang.t("マイページ", en: "My Page"), systemImage: "person.circle.fill")
                    }
                    .tag(4)
            }
            .tint(Color.jfRed)
            .onChange(of: selectedTab) { _, newValue in
                if newValue == 99 {
                    selectedTab = lastTab
                    showQuickLog = true
                } else {
                    lastTab = newValue
                }
            }

            // Floating center button
            Button {
                showQuickLog = true
            } label: {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Color.jfRed, Color.jfRed.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 56, height: 56)
                        .shadow(color: Color.jfRed.opacity(0.4), radius: 8, y: 2)
                    Image(systemName: "plus")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                }
            }
            .hapticOnTap(.medium)
            .accessibilityIdentifier("quickLogFab")
            .accessibilityLabel(lang.t("記録する", en: "Log"))
            .offset(y: -24)
        }
        .sheet(isPresented: $showQuickLog) {
            NavigationStack {
                QuickLogSheet()
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView {
                hasSeenOnboarding = true
                showOnboarding = false
            }
        }
        .onAppear {
            if !hasSeenOnboarding { showOnboarding = true }
        }
    }
}

private extension View {
    /// The floating "+" protrudes ~30pt above the tab bar; reserve that space so scroll content
    /// (last card, chart labels) is never hidden behind it.
    func fabClearance() -> some View {
        safeAreaInset(edge: .bottom, spacing: 0) { Color.clear.frame(height: 32) }
    }
}
