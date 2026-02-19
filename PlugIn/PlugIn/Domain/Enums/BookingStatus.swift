enum BookingStatus: String, Codable {
    case pending = "pending"
    case accepted = "accepted"
    case active = "active"
    case completed = "completed"
    case declined = "declined"
    case cancelled = "cancelled"
}

