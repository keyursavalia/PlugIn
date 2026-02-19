import SwiftUI
import FirebaseFirestore

struct PastRequestsView: View {
    @EnvironmentObject var authService: AuthService
    @State private var bookings: [Booking] = []
    @State private var drivers: [String: User] = [:]
    @State private var chargers: [String: Charger] = [:]
    @State private var isLoading = true

    var body: some View {
        ZStack {
            if isLoading {
                loadingView
            } else if bookings.isEmpty {
                emptyStateView
            } else {
                bookingsListView
            }
        }
        .navigationTitle("Past Requests")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadPastBookings()
        }
    }

    private var loadingView: some View {
        ProgressView("Loading past requests...")
            .foregroundColor(.secondary)
    }

    private var bookingsListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(sortedSections, id: \.self) { section in
                    sectionView(for: section)
                }
            }
            .padding(.vertical)
        }
    }

    private func sectionView(for section: Date) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(sectionTitle(for: section))
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.top, isFirstSection(section) ? 8 : 0)

            ForEach(groupedBookings[section] ?? [], id: \.id) { booking in
                BookingHistoryCard(
                    booking: booking,
                    driver: otherUser(for: booking),
                    charger: chargers[booking.chargerId]
                )
            }
        }
    }

    private var sortedSections: [Date] {
        groupedBookings.keys.sorted(by: { $0 > $1 })
    }

    private func isFirstSection(_ section: Date) -> Bool {
        section == sortedSections.first
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))

            Text("No Past Requests")
                .font(.title2.bold())
                .foregroundColor(.primary)

            Text("Your booking history will appear here")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Data Grouping

    private var groupedBookings: [Date: [Booking]] {
        Dictionary(grouping: bookings) { booking in
            Calendar.current.startOfDay(for: booking.requestedAt.dateValue())
        }
    }

    private func otherUser(for booking: Booking) -> User? {
        // If current user is the driver, show the host. Otherwise, show the driver.
        guard let currentUserId = authService.currentUser?.id else { return nil }

        if booking.driverId == currentUserId {
            return drivers[booking.hostId]
        } else {
            return drivers[booking.driverId]
        }
    }

    private func sectionTitle(for date: Date) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!

        if calendar.isDate(date, inSameDayAs: today) {
            return "Today"
        } else if calendar.isDate(date, inSameDayAs: yesterday) {
            return "Yesterday"
        } else if date >= weekAgo {
            return "This Week"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }

    // MARK: - Data Loading

    private func loadPastBookings() async {
        guard let userId = authService.currentUser?.id else { return }

        do {
            // Fetch bookings (both as host and driver)
            let fetchedBookings = try await FirestoreService.shared.getPastBookings(userId: userId)

            // Fetch related drivers and chargers
            var driverDict: [String: User] = [:]
            var chargerDict: [String: Charger] = [:]

            for booking in fetchedBookings {
                // Fetch driver if not already fetched
                if driverDict[booking.driverId] == nil {
                    if let driver = try? await FirestoreService.shared.getUser(uid: booking.driverId) {
                        driverDict[booking.driverId] = driver
                    }
                }

                // Fetch host if not already fetched
                if driverDict[booking.hostId] == nil {
                    if let host = try? await FirestoreService.shared.getUser(uid: booking.hostId) {
                        driverDict[booking.hostId] = host
                    }
                }

                // Fetch charger if not already fetched
                if chargerDict[booking.chargerId] == nil {
                    if let charger = try? await FirestoreService.shared.getCharger(id: booking.chargerId) {
                        chargerDict[booking.chargerId] = charger
                    }
                }
            }

            await MainActor.run {
                self.bookings = fetchedBookings
                self.drivers = driverDict
                self.chargers = chargerDict
                self.isLoading = false
            }
        } catch {
            print("Error loading past bookings: \(error)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}

// MARK: - Booking History Card

struct BookingHistoryCard: View {
    let booking: Booking
    let driver: User?
    let charger: Charger?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                // Driver Image
                if let profileImageURL = driver?.profileImageURL, !profileImageURL.isEmpty {
                    AsyncImage(url: URL(string: profileImageURL)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        driverInitialsView
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                } else {
                    driverInitialsView
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(driver?.name ?? "Unknown Driver")
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        Text(timeAgo(from: booking.requestedAt.dateValue()))
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Circle()
                            .fill(Color.secondary)
                            .frame(width: 3, height: 3)

                        Text(chargerDisplayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                statusBadge
            }
            .padding()

            Divider()

            // Details
            HStack {
                // Duration
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(durationText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Credits
                if let credits = booking.creditsUsed, booking.status == .accepted || booking.status == .completed || booking.status == .active {
                    HStack(spacing: 4) {
                        Image(systemName: "leaf.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("+\(credits)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.green)
                        Text("credits")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal)
    }

    private var driverInitialsView: some View {
        Circle()
            .fill(Color.green.opacity(0.2))
            .frame(width: 50, height: 50)
            .overlay(
                Text(driver?.name.prefix(1).uppercased() ?? "D")
                    .font(.title3.bold())
                    .foregroundColor(.green)
            )
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Text(statusText)
                .font(.caption.weight(.medium))
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(statusColor.opacity(0.1))
        .cornerRadius(12)
    }

    private var statusColor: Color {
        switch booking.status {
        case .accepted:
            return .green
        case .declined:
            return .red
        case .completed:
            return .blue
        case .active:
            return .orange
        default:
            return .gray
        }
    }

    private var statusText: String {
        switch booking.status {
        case .accepted:
            return "Accepted"
        case .declined:
            return "Declined"
        case .completed:
            return "Completed"
        case .active:
            return "Active"
        default:
            return "Unknown"
        }
    }

    private var durationText: String {
        let hours = Int(booking.estimatedDuration / 3600)
        let minutes = Int((booking.estimatedDuration.truncatingRemainder(dividingBy: 3600)) / 60)

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    private var chargerDisplayName: String {
        guard let charger = charger else { return "Unknown Charger" }
        return "\(charger.type.rawValue.capitalized) • \(charger.connectorType.rawValue.uppercased())"
    }

    private func timeAgo(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day, .weekOfYear], from: date, to: now)

        if let weeks = components.weekOfYear, weeks > 0 {
            return "\(weeks)w ago"
        } else if let days = components.day, days > 0 {
            return "\(days)d ago"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours)h ago"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes)m ago"
        } else {
            return "Just now"
        }
    }
}

// MARK: - Preview

struct PastRequestsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PastRequestsView()
                .environmentObject(AuthService())
        }
    }
}
