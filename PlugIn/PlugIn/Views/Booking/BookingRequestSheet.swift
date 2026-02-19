import SwiftUI

struct BookingRequestSheet: View {
    let charger: Charger
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject private var viewModel = BookingViewModel()
    
    var body: some View {
        BookingRequestView(viewModel: viewModel, charger: charger)
            .onAppear {
                viewModel.selectedCharger = charger
            }
            .onChange(of: viewModel.showRequestSent) { showRequestSent in
                if showRequestSent, let booking = viewModel.currentBooking {
                    coordinator.dismissSheet()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        coordinator.presentFullScreen(.requestSent(booking))
                    }
                }
            }
    }
}
