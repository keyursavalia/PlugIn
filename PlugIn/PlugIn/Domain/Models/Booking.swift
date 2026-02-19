import Foundation
import FirebaseFirestore

struct Booking: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    let chargerId: String
    let hostId: String
    let driverId: String
    var status: BookingStatus
    var requestedAt: Timestamp
    var acceptedAt: Timestamp?
    var startedAt: Timestamp?
    var endedAt: Timestamp?
    var estimatedDuration: TimeInterval
    var creditsUsed: Int?
    var amountPaid: Double?
    var driverRating: Int?
    var hostRating: Int?
    var scheduledStartTime: Timestamp?  // nil means "now/ASAP"

    // Computed
    var isActive: Bool {
        status == .accepted || status == .active
    }

    var scheduledEndTime: Date? {
        guard let start = scheduledStartTime?.dateValue() else { return nil }
        return start.addingTimeInterval(estimatedDuration)
    }

    init(id: String?, chargerId: String, hostId: String, driverId: String, status: BookingStatus, requestedAt: Timestamp, acceptedAt: Timestamp?, startedAt: Timestamp?, endedAt: Timestamp?, estimatedDuration: TimeInterval, creditsUsed: Int?, amountPaid: Double?, driverRating: Int?, hostRating: Int?, scheduledStartTime: Timestamp? = nil) {
        self.id = id
        self.chargerId = chargerId
        self.hostId = hostId
        self.driverId = driverId
        self.status = status
        self.requestedAt = requestedAt
        self.acceptedAt = acceptedAt
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.estimatedDuration = estimatedDuration
        self.creditsUsed = creditsUsed
        self.amountPaid = amountPaid
        self.driverRating = driverRating
        self.hostRating = hostRating
        self.scheduledStartTime = scheduledStartTime
    }
}

// MARK: - Hashable Conformance
extension Booking {
    static func == (lhs: Booking, rhs: Booking) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

