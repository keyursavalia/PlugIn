import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var coordinator = AppCoordinator()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Driver Tab - Always visible
            NavigationStack(path: $coordinator.path) {
                DriverMapView()
                    .navigationDestination(for: Route.self) { route in
                        NavigationDestination(route: route)
                    }
            }
            .toolbar(coordinator.isChargerDetailSheetPresented ? .hidden : .visible, for: .tabBar)
            .tabItem {
                Label("Map", systemImage: "map")
            }
            .tag(0)
            
            // Host Tab - Always visible
            NavigationStack(path: $coordinator.path) {
                HostDashboardView()
                    .navigationDestination(for: Route.self) { route in
                        NavigationDestination(route: route)
                    }
            }
            .tabItem {
                Label("Charger", systemImage: "bolt.fill")
            }
            .tag(1)
            
            // Profile Tab - Always visible
            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.circle")
            }
            .tag(2)
        }
        .environmentObject(coordinator)
        .accentColor(.green)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()

            appearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemGreen
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.systemGreen]

            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.gray
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.gray]

            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        .sheet(item: $coordinator.presentedSheet) { route in
            NavigationDestination(route: route)
                .environmentObject(coordinator)
        }
        .fullScreenCover(item: $coordinator.presentedFullScreen) { route in
            NavigationDestination(route: route)
                .environmentObject(coordinator)
        }
    }
}
