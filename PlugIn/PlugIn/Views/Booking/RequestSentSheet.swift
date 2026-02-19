import SwiftUI
import Combine
import FirebaseFirestore

struct RequestSentSheet: View {
    let booking: Booking
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject private var viewModel = BookingViewModel()

    var body: some View {
        RequestSentView(viewModel: viewModel)
            .task {
                viewModel.currentBooking = booking
                viewModel.bookingStatus = booking.status

                // Load charger data FIRST before setting up listener
                let charger = try? await FirestoreService.shared.getCharger(id: booking.chargerId)
                viewModel.selectedCharger = charger

                // Set up real-time listener for booking status changes
                if let bookingId = booking.id {
                    viewModel.listenToBookingStatus(bookingId: bookingId)
                } else {
                    print("ERROR: Booking has no ID, cannot set up listener")
                }
            }
    }
}
