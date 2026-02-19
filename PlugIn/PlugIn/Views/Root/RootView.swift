import SwiftUI

struct RootView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                // Always show loading view while user data is being fetched
                if authService.isLoadingUser || authService.currentUser == nil {
                    LoadingView()
                } else {
                    MainTabView()
                }
            } else {
                if authService.isLoadingUser {
                    // Show loading on initial app launch while checking auth state
                    LoadingView()
                } else {
                    SignUpView()
                }
            }
        }
    }
}
