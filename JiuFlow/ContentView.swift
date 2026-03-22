import SwiftUI

struct ContentView: View {
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
                FlowTab()
                    .tabItem {
                        Label(lang.t("フロー", en: "Flow"), systemImage: "arrow.triangle.branch")
                    }
                    .tag(0)

                VideosTab()
                    .tabItem {
                        Label(lang.t("動画", en: "Videos"), systemImage: "play.rectangle.fill")
                    }
                    .tag(1)

                // Placeholder for center button
                Color.clear
                    .tabItem {
                        Label(lang.t("記録", en: "Log"), systemImage: "plus.circle")
                    }
                    .tag(99)

                DiscoverTab()
                    .tabItem {
                        Label(lang.t("探す", en: "Discover"), systemImage: "sparkle.magnifyingglass")
                    }
                    .tag(3)

                MyPageTab()
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
