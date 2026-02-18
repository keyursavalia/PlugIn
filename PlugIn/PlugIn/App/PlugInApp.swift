import SwiftUI
import FirebaseCore

@main
struct Plug_InApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authService = AuthService()
    @StateObject private var locationService = LocationService()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authService)
                .environmentObject(locationService)
        }
    }
}
