import SwiftUI
import Combine
import FirebaseFirestore

@MainActor
class BookingViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedCharger: Charger?
    @Published var currentBooking: Booking?
    @Published var bookingStatus: BookingStatus = .pending
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showBookingRequest = false
    @Published var showRequestSent = false
    
    // Booking details
    @Published var estimatedDuration: TimeInterval = 7200 // 2 hours default
    @Published var useCredits = false
    @Published var scheduleForLater = false
    @Published var scheduledStartTime: Date = {
        // Default to next 15-min rounded time + 30 min
        let now = Date()
        let calendar = Calendar.current
        let minute = calendar.component(.minute, from: now)
        let roundedMinute = ((minute / 15) + 1) * 15
        let rounded = calendar.date(bySetting: .minute, value: roundedMinute, of: now) ?? now
        return rounded.addingTimeInterval(30 * 60)
    }()
    
    // MARK: - Dependencies
    private let bookingRepository = BookingRepository()
    private let chargerRepository = ChargerRepository()
    private let authService = AuthService()
    private var cancellables = Set<AnyCancellable>()
    private var bookingListener: ListenerRegistration?
    
    // MARK: - Computed Properties
    var estimatedCost: Double {
        guard let charger = selectedCharger else { return 0 }
        let hours = estimatedDuration / 3600
        return charger.pricePerHour * hours
    }
    
    var estimatedCredits: Int {
        guard let charger = selectedCharger else { return 0 }
        let hours = Int(estimatedDuration / 3600)
        return charger.creditsPerHour * hours
    }
    
    var durationInHours: Double {
        estimatedDuration / 3600
    }
    
    // MARK: - Methods
    func requestBooking() async {
        guard let charger = selectedCharger,
              let driverId = authService.currentUser?.id else {
            errorMessage = "Unable to create booking"
            return
        }

        guard let chargerId = charger.id else {
            errorMessage = "Invalid charger"
            return
        }

        // Validate availability at requested time
        let bookingTime = scheduleForLater ? scheduledStartTime : Date()
        if !charger.isAvailable(at: bookingTime) {
            errorMessage = "This charger is not available at the requested time. Please choose a different time."
            return
        }

        isLoading = true
        errorMessage = nil

        let booking = Booking(
            id: nil,
            chargerId: chargerId,
            hostId: charger.hostId,
            driverId: driverId,
            status: .pending,
            requestedAt: Timestamp(),
            acceptedAt: nil,
            startedAt: nil,
            endedAt: nil,
            estimatedDuration: estimatedDuration,
            creditsUsed: useCredits ? estimatedCredits : nil,
            amountPaid: useCredits ? nil : estimatedCost,
            driverRating: nil,
            hostRating: nil,
            scheduledStartTime: scheduleForLater ? Timestamp(date: scheduledStartTime) : nil
        )

        do {
            let bookingId = try await bookingRepository.createBooking(booking)
            var createdBooking = booking
            createdBooking.id = bookingId

            currentBooking = createdBooking
            showRequestSent = true
            isLoading = false

            // Start listening for status changes
            listenToBookingStatus(bookingId: bookingId)

        } catch {
            isLoading = false
            errorMessage = "Failed to create booking: \(error.localizedDescription)"
        }
    }
    
    func cancelBooking() async {
        guard var booking = currentBooking else { return }
        
        isLoading = true
        
        booking.status = .cancelled
        
        do {
            try await bookingRepository.updateBooking(booking)
            currentBooking = nil
            showRequestSent = false
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to cancel booking"
        }
    }
    
    func listenToBookingStatus(bookingId: String) {
        bookingListener?.remove() // Remove any existing listener first

        bookingListener = FirestoreService.shared.listenToBooking(id: bookingId) { [weak self] booking in
            guard let booking = booking else {
                return
            }

            Task { @MainActor in
                self?.currentBooking = booking
                self?.bookingStatus = booking.status

                // Handle status changes
                if booking.status == .accepted {
                    self?.handleBookingAccepted()
                } else if booking.status == .declined {
                    self?.handleBookingDeclined()
                }
            }
        }
    }
    
    private var hasDebitedCredits = false

    private func handleBookingAccepted() {
        // Debit driver's own credits (driver is the authenticated user here)
        // Host already credited themselves in BookingRepository.acceptBooking()
        guard !hasDebitedCredits,
              let booking = currentBooking,
              let creditsUsed = booking.creditsUsed else { return }

        hasDebitedCredits = true

        Task {
            do {
                try await FirestoreService.shared.updateUserCredits(
                    userId: booking.driverId,
                    creditsChange: -creditsUsed
                )
            } catch {
                hasDebitedCredits = false
            }
        }
    }
    
    private func handleBookingDeclined() {
        errorMessage = "Host declined your request"
        currentBooking = nil
        showRequestSent = false
    }
    
    func updateDuration(hours: Double) {
        estimatedDuration = hours * 3600
    }
    
    deinit {
        bookingListener?.remove()
    }
}
