import SwiftUI
import Combine

@MainActor
class RequestViewModel: ObservableObject {
    @Published var incomingRequests: [Booking] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let bookingRepository = BookingRepository()
    private var cancellables = Set<AnyCancellable>()

    init() {
        bookingRepository.$incomingRequests
            .receive(on: DispatchQueue.main)
            .sink { [weak self] requests in
                self?.incomingRequests = requests
            }
            .store(in: &cancellables)
    }

    /// Start or restart the incoming requests listener. Call on appear so the host sees new bookings in real time.
    func ensureListening(hostId: String) {
        bookingRepository.listenToIncomingRequests(hostId: hostId)
    }
    
    func acceptBooking(_ booking: Booking) async {
        isLoading = true

        do {
            try await bookingRepository.acceptBooking(booking)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to accept booking"
        }
    }

    func declineBooking(_ booking: Booking) async {
        isLoading = true

        do {
            try await bookingRepository.declineBooking(booking)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to decline booking"
        }
    }
}
