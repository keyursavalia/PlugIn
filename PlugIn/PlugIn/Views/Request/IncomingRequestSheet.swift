import SwiftUI

struct IncomingRequestSheet: View {
    let booking: Booking
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = RequestViewModel()
    @EnvironmentObject var authService: AuthService

    var body: some View {
        IncomingRequestView(
            booking: booking,
            onAccept: {
                await viewModel.acceptBooking(booking)
                await authService.refreshCurrentUser()
                dismiss()
            },
            onDecline: {
                await viewModel.declineBooking(booking)
                dismiss()
            }
        )
    }
}
