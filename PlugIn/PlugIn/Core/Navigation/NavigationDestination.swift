import SwiftUI
import Combine

struct NavigationDestination: View {
    let route: Route
    
    var body: some View {
        switch route {
        case .driverMap:
            DriverMapView()
            
        case .hostDashboard:
            HostDashboardView()
            
        case .addCharger:
            AddChargerView(chargerToEdit: nil)
            
        case .editCharger(let charger):
            AddChargerView(chargerToEdit: charger)
            
        case .chargerDetail(let charger, let distance):
            ChargerDetailView(charger: charger, distance: distance)
            
        case .bookingRequest(let charger):
            BookingRequestSheet(charger: charger)
            
        case .requestSent(let booking):
            RequestSentSheet(booking: booking)
            
        case .incomingRequest(let booking):
            IncomingRequestSheet(booking: booking)

        case .requestsList:
            RequestsListSheet()

        case .activeSession(let booking, let isHost):
            BookingConfirmationView(booking: booking, isHost: isHost)

        case .profile:
            ProfileView()
        }
    }
}

extension Route: Identifiable {
    public var id: String {
        switch self {
        case .driverMap: return "driverMap"
        case .hostDashboard: return "hostDashboard"
        case .addCharger: return "addCharger"
        case .editCharger(let charger): return "editCharger_\(charger.id ?? "")"
        case .chargerDetail(let charger, _): return "chargerDetail_\(charger.id ?? "")"
        case .bookingRequest(let charger): return "bookingRequest_\(charger.id ?? "")"
        case .requestSent(let booking): return "requestSent_\(booking.id ?? "")"
        case .incomingRequest(let booking): return "incomingRequest_\(booking.id ?? "")"
        case .requestsList: return "requestsList"
        case .activeSession(let booking, _): return "activeSession_\(booking.id ?? "")"
        case .profile: return "profile"
        }
    }
}

