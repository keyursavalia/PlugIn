import SwiftUI
import FirebaseCore

struct RequestSentView: View {
    @ObservedObject var viewModel: BookingViewModel
    @SwiftUI.Environment(\.dismiss) var dismiss
    @EnvironmentObject var coordinator: AppCoordinator
    @State private var hostData: User?
    @State private var chargerData: Charger?
    @State private var isLoadingHostData = true

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Status indicator - Changes based on booking status
            statusIndicator

            // Status text - Changes based on booking status
            statusText

            // Progress timeline
            requestTimeline

            // Host info
            if let booking = viewModel.currentBooking {
                hostInfoCard(booking: booking)
            }

            Spacer()

            // Actions - Changes based on status
            actionButtons
        }
        .background(Color(.systemGroupedBackground))
        .onChange(of: viewModel.currentBooking) { _, newBooking in
            // Trigger load when currentBooking is set by RequestSentSheet.task
            if newBooking != nil && hostData == nil && isLoadingHostData {
                loadHostAndChargerData()
            }
        }
        .onAppear {
            if viewModel.currentBooking != nil {
                loadHostAndChargerData()
            }
        }
        .onChange(of: viewModel.bookingStatus) { _, newStatus in
            if newStatus == .accepted {
                // Auto-navigate to active session after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    if let booking = viewModel.currentBooking {
                        dismiss()
                        coordinator.presentFullScreen(.activeSession(booking, isHost: false))
                    }
                }
            } else if newStatus == .declined {
                // Auto-dismiss after 1.5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Status Indicator
    private var statusIndicator: some View {
        ZStack {
            Circle()
                .fill(statusColor.opacity(0.2))
                .frame(width: 100, height: 100)

            Image(systemName: statusIcon)
                .font(.system(size: 50))
                .foregroundColor(statusColor)
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: viewModel.bookingStatus)
    }

    // MARK: - Status Text
    private var statusText: some View {
        VStack(spacing: 8) {
            Text(statusTitle)
                .font(.title.bold())

            Text(statusSubtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .animation(.easeInOut, value: viewModel.bookingStatus)
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            if viewModel.bookingStatus == .pending {
                DestructiveButton(title: "Cancel Request") {
                    Task {
                        await viewModel.cancelBooking()
                        dismiss()
                    }
                }
            } else if viewModel.bookingStatus == .accepted {
                PrimaryButton(title: "View Session") {
                    if let booking = viewModel.currentBooking {
                        dismiss()
                        coordinator.presentFullScreen(.activeSession(booking, isHost: false))
                    }
                }
            }
        }
        .padding()
    }

    // MARK: - Computed Properties
    private var statusColor: Color {
        switch viewModel.bookingStatus {
        case .pending:
            return .orange
        case .accepted:
            return .green
        case .declined:
            return .red
        default:
            return .gray
        }
    }

    private var statusIcon: String {
        switch viewModel.bookingStatus {
        case .pending:
            return "clock.fill"
        case .accepted:
            return "checkmark.circle.fill"
        case .declined:
            return "xmark.circle.fill"
        default:
            return "clock.fill"
        }
    }

    private var statusTitle: String {
        switch viewModel.bookingStatus {
        case .pending:
            return "Request Sent"
        case .accepted:
            return "Booking Confirmed!"
        case .declined:
            return "Request Declined"
        default:
            return "Request Sent"
        }
    }

    private var statusSubtitle: String {
        switch viewModel.bookingStatus {
        case .pending:
            return "Waiting for host approval..."
        case .accepted:
            return "Your charging session is ready!\nPreparing session..."
        case .declined:
            return "The host declined your request.\nTry another charger nearby."
        default:
            return "Processing..."
        }
    }
    
    private var requestTimeline: some View {
        VStack(alignment: .leading, spacing: 0) {
            TimelineStep(
                title: "Request Sent",
                time: viewModel.currentBooking?.requestedAt.dateValue().timeFormatted() ?? "--:--",
                isCompleted: true,
                isActive: false
            )
            
            TimelineStep(
                title: "Host Notified",
                time: "Waiting for response...",
                isCompleted: viewModel.bookingStatus != .pending,
                isActive: viewModel.bookingStatus == .pending
            )
            
            TimelineStep(
                title: "Booking Confirmed",
                time: viewModel.bookingStatus == .accepted ?
                    (viewModel.currentBooking?.acceptedAt?.dateValue().timeFormatted() ?? "--:--") : "--:--",
                isCompleted: viewModel.bookingStatus == .accepted,
                isActive: false,
                isLast: true
            )
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func hostInfoCard(booking: Booking) -> some View {
        HStack(spacing: 12) {
            // Host avatar with profile image
            if isLoadingHostData {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(ProgressView().tint(.green))
            } else if let imageURL = hostData?.profileImageURL, !imageURL.isEmpty {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .overlay(
                            Text(hostData?.name.prefix(1).uppercased() ?? "H")
                                .font(.title2.bold())
                                .foregroundColor(.green)
                        )
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(hostData?.name.prefix(1).uppercased() ?? "H")
                            .font(.title2.bold())
                            .foregroundColor(.green)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(hostData?.name ?? "Host")
                    .font(.headline)
                    .redacted(reason: isLoadingHostData ? .placeholder : [])

                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(chargerData?.address ?? "Loading location...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .redacted(reason: isLoadingHostData ? .placeholder : [])
                }
            }

            Spacer()

            if let credits = booking.creditsUsed {
                HStack(spacing: 4) {
                    Text("\(credits)")
                        .font(.title3.bold())
                        .foregroundColor(.green)
                    Image(systemName: "leaf.fill")
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal)
    }

    // MARK: - Helper Methods
    private func loadHostAndChargerData() {
        guard let booking = viewModel.currentBooking else { return }

        Task {
            do {
                // Fetch host and charger in parallel - no dependency on viewModel.selectedCharger
                async let hostFetch = FirestoreService.shared.getUser(uid: booking.hostId)
                async let chargerFetch = FirestoreService.shared.getCharger(id: booking.chargerId)

                let host = try await hostFetch
                let charger = try await chargerFetch

                await MainActor.run {
                    self.hostData = host
                    self.chargerData = charger
                    self.isLoadingHostData = false
                }

                print("✅ Loaded host data: \(host.name) and location: \(charger.address)")
            } catch {
                print("❌ Failed to load host/charger data: \(error.localizedDescription)")
                await MainActor.run {
                    self.isLoadingHostData = false
                }
            }
        }
    }
}

struct TimelineStep: View {
    let title: String
    let time: String
    let isCompleted: Bool
    let isActive: Bool
    var isLast: Bool = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Timeline indicator
            VStack(spacing: 0) {
                Circle()
                    .fill(isCompleted ? Color.green : (isActive ? Color.orange : Color.gray.opacity(0.3)))
                    .frame(width: 20, height: 20)
                    .overlay(
                        Group {
                            if isCompleted {
                                Image(systemName: "checkmark")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                            }
                        }
                    )
                
                if !isLast {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2, height: 40)
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(isActive ? .semibold : .regular))
                    .foregroundColor(isActive ? .primary : .secondary)
                Text(time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}
