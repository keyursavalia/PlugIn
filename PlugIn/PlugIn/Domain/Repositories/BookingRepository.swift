import Foundation
import Combine
import FirebaseFirestore

class BookingRepository: ObservableObject {
    @Published var activeBooking: Booking?
    @Published var incomingRequests: [Booking] = []
    
    private let firestoreService = FirestoreService.shared
    private var requestsListener: ListenerRegistration?
    
    func createBooking(_ booking: Booking) async throws -> String {
        return try await firestoreService.createBooking(booking)
    }
    
    func acceptBooking(_ booking: Booking) async throws {
        var updated = booking
        updated.status = .accepted
        updated.acceptedAt = Timestamp()
        try await firestoreService.updateBooking(updated)

        // Credit host when they accept (host is the authenticated user here)
        // Driver debit happens on driver's side via BookingViewModel.handleBookingAccepted()
        // This split is required because Firestore rules only allow users to update their own document
        if let creditsUsed = booking.creditsUsed {
            try await firestoreService.updateUserCredits(
                userId: booking.hostId,
                creditsChange: creditsUsed
            )
        }

        await MainActor.run {
            self.activeBooking = updated
        }
    }
    
    func declineBooking(_ booking: Booking) async throws {
        var updated = booking
        updated.status = .declined
        try await firestoreService.updateBooking(updated)
    }
    
    func updateBooking(_ booking: Booking) async throws {
        try await firestoreService.updateBooking(booking)
        
        await MainActor.run {
            if self.activeBooking?.id == booking.id {
                self.activeBooking = booking
            }
        }
    }
    
    func listenToIncomingRequests(hostId: String) {
        requestsListener?.remove()
        requestsListener = firestoreService.listenToIncomingRequests(hostId: hostId) { [weak self] bookings in
            DispatchQueue.main.async {
                self?.incomingRequests = bookings
            }
        }
    }
    
    deinit {
        requestsListener?.remove()
    }
}
