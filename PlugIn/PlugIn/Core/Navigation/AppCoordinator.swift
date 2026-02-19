import SwiftUI
import Combine

enum Route: Hashable, Equatable {
    case driverMap
    case hostDashboard
    case addCharger
    case editCharger(Charger)
    case chargerDetail(Charger, String?)
    case bookingRequest(Charger)
    case requestSent(Booking)
    case incomingRequest(Booking)
    case requestsList
    case activeSession(Booking, isHost: Bool)
    case profile
}

class AppCoordinator: ObservableObject {
    @Published var path = NavigationPath()
    @Published var presentedSheet: Route?
    @Published var presentedFullScreen: Route?
    @Published var isChargerDetailSheetPresented = false // When true, the Map tab hides nav bar
    
    func push(_ route: Route) {
        path.append(route)
    }
    
    func pop() {
        path.removeLast()
    }
    
    func popToRoot() {
        path = NavigationPath()
    }
    
    func presentSheet(_ route: Route) {
        presentedSheet = route
    }
    
    func presentFullScreen(_ route: Route) {
        presentedFullScreen = route
    }
    
    func dismissSheet() {
        presentedSheet = nil
    }
    
    func dismissFullScreen() {
        presentedFullScreen = nil
    }
}

