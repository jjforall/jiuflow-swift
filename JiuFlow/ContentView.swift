import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

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
            HomeTab()
                .tabItem {
                    Label("ホーム", systemImage: "house.fill")
                }
                .tag(0)

            TechniqueTab()
                .tabItem {
                    Label("テクニック", systemImage: "figure.martial.arts")
                }
                .tag(1)

            VideosTab()
                .tabItem {
                    Label("動画", systemImage: "play.rectangle.fill")
                }
                .tag(2)

            DojosTab()
                .tabItem {
                    Label("道場", systemImage: "mappin.circle.fill")
                }
                .tag(3)

            MyPageTab()
                .tabItem {
                    Label("マイページ", systemImage: "person.circle.fill")
                }
                .tag(4)
        }
        .tint(Color.jfRed)
    }
}
