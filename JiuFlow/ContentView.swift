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

    var body: some View {
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

            DojosTab()
                .tabItem {
                    Label(lang.t("道場", en: "Dojos"), systemImage: "mappin.circle.fill")
                }
                .tag(2)

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
