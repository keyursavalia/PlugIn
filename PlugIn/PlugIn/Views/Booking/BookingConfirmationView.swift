import SwiftUI
import FirebaseFirestore
import MapKit

struct BookingConfirmationView: View {
    let booking: Booking
    let isHost: Bool
    @State private var charger: Charger?
    @State private var host: User?
    @State private var driver: User?
    @State private var isLoading = true
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            if isLoading {
                ProgressView("Loading booking details...")
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "chevron.left")
                                    .font(.title3)
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)

                        // Success Icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.green.opacity(0.2), Color.green.opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)

                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 70))
                                .foregroundColor(.green)
                        }
                        .padding(.top, 20)

                        VStack(spacing: 8) {
                            Text("Booking Confirmed!")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.primary)

                            Text(isHost ? "Driver is on the way" : "Your spot is reserved")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }

                        // Charger Information Card
                        if let charger = charger {
                            chargerInfoCard(charger)
                        }

                        // Location Card
                        if let charger = charger {
                            locationCard(charger)
                        }

                        // Booking Details Card
                        bookingDetailsCard

                        // Credits Card
                        creditsCard

                        // Host/Driver Info Card
                        if isHost {
                            if let driver = driver {
                                driverInfoCard(driver)
                            }
                        } else {
                            if let host = host {
                                hostInfoCard(host)
                            }
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.bottom, 32)
                }
            }
        }
        .task {
            await loadBookingData()
        }
    }

    // MARK: - Charger Info Card

    private func chargerInfoCard(_ charger: Charger) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Charger Details")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(spacing: 12) {
                DetailRow(
                    icon: "bolt.fill",
                    title: "Type",
                    value: "\(charger.type.rawValue.capitalized) • \(charger.connectorType.rawValue.uppercased())"
                )

                Divider()

                DetailRow(
                    icon: "speedometer",
                    title: "Max Speed",
                    value: "\(String(format: "%.1f", charger.maxSpeed)) kW"
                )

                Divider()

                DetailRow(
                    icon: "cable.connector",
                    title: "Cable",
                    value: charger.hasTetheredCable ? "Tethered" : "Bring Your Own"
                )

                if let instructions = charger.accessInstructions, !instructions.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("Access Instructions")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.primary)
                        }

                        Text(instructions)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 28)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal)
    }

    // MARK: - Location Card

    private func locationCard(_ charger: Charger) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Location")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red)

                    Text(charger.address)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(3)
                }

                Button(action: {
                    openInMaps(charger)
                }) {
                    HStack {
                        Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                            .font(.title3)
                        Text("Open in Maps")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.green, Color.green.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal)
    }

    // MARK: - Booking Details Card

    private var bookingDetailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Booking Details")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(spacing: 12) {
                DetailRow(
                    icon: "calendar",
                    title: "Requested",
                    value: formatDate(booking.requestedAt.dateValue())
                )

                if let acceptedAt = booking.acceptedAt {
                    Divider()
                    DetailRow(
                        icon: "checkmark.circle",
                        title: "Accepted",
                        value: formatDate(acceptedAt.dateValue())
                    )
                }

                Divider()

                DetailRow(
                    icon: "clock",
                    title: "Duration",
                    value: formatDuration(booking.estimatedDuration)
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal)
    }

    // MARK: - Credits Card

    private var creditsCard: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "leaf.fill")
                            .font(.title2)
                            .foregroundColor(.green)

                        Text(isHost ? "Credits Earned" : "Credits Used")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }

                    Text(isHost ? "Added to your balance" : "Deducted from your balance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack(spacing: 4) {
                    Text(isHost ? "+" : "-")
                        .font(.title.bold())
                        .foregroundColor(.green)
                    Text("\(booking.creditsUsed ?? 0)")
                        .font(.title.bold())
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.green.opacity(0.1), Color.green.opacity(0.05)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.3), lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal)
    }

    // MARK: - Driver Info Card

    private func driverInfoCard(_ driver: User) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Driver Information")
                .font(.headline)
                .foregroundColor(.primary)

            HStack(spacing: 16) {
                if let profileImageURL = driver.profileImageURL, !profileImageURL.isEmpty {
                    AsyncImage(url: URL(string: profileImageURL)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        driverInitialsView(driver)
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                } else {
                    driverInitialsView(driver)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(driver.name)
                        .font(.title3.bold())
                        .foregroundColor(.primary)

                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("Verified Driver")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal)
    }

    private func driverInitialsView(_ driver: User) -> some View {
        Circle()
            .fill(Color.green.opacity(0.2))
            .frame(width: 60, height: 60)
            .overlay(
                Text(driver.name.prefix(1).uppercased())
                    .font(.title2.bold())
                    .foregroundColor(.green)
            )
    }

    // MARK: - Host Info Card

    private func hostInfoCard(_ host: User) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Host Information")
                .font(.headline)
                .foregroundColor(.primary)

            HStack(spacing: 16) {
                if let profileImageURL = host.profileImageURL, !profileImageURL.isEmpty {
                    AsyncImage(url: URL(string: profileImageURL)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        hostInitialsView(host)
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                } else {
                    hostInitialsView(host)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(host.name)
                        .font(.title3.bold())
                        .foregroundColor(.primary)

                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("Verified Host")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal)
    }

    private func hostInitialsView(_ host: User) -> some View {
        Circle()
            .fill(Color.green.opacity(0.2))
            .frame(width: 60, height: 60)
            .overlay(
                Text(host.name.prefix(1).uppercased())
                    .font(.title2.bold())
                    .foregroundColor(.green)
            )
    }

    // MARK: - Helper Methods

    private func loadBookingData() async {
        do {
            async let chargerFetch = FirestoreService.shared.getCharger(id: booking.chargerId)
            async let hostFetch = FirestoreService.shared.getUser(uid: booking.hostId)
            async let driverFetch = FirestoreService.shared.getUser(uid: booking.driverId)

            let (fetchedCharger, fetchedHost, fetchedDriver) = try await (chargerFetch, hostFetch, driverFetch)

            await MainActor.run {
                self.charger = fetchedCharger
                self.host = fetchedHost
                self.driver = fetchedDriver
                self.isLoading = false
            }
        } catch {
            print("Error loading booking data: \(error)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds / 3600)
        let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)

        if hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s") \(minutes) min"
        } else {
            return "\(minutes) min"
        }
    }

    private func openInMaps(_ charger: Charger) {
        let coordinate = CLLocationCoordinate2D(
            latitude: charger.location.latitude,
            longitude: charger.location.longitude
        )
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = charger.address
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}

// MARK: - Detail Row Component

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.green)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)
            }

            Spacer()
        }
    }
}

// MARK: - Preview

struct BookingConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        BookingConfirmationView(
            booking: Booking(
                id: "123",
                chargerId: "456",
                hostId: "789",
                driverId: "012",
                status: .accepted,
                requestedAt: Timestamp(),
                acceptedAt: Timestamp(),
                startedAt: nil,
                endedAt: nil,
                estimatedDuration: 7200,
                creditsUsed: 6,
                amountPaid: nil,
                driverRating: nil,
                hostRating: nil
            ),
            isHost: false
        )
    }
}
