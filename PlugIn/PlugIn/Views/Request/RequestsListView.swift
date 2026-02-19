import SwiftUI
import FirebaseCore

struct RequestsListView: View {
    @ObservedObject var viewModel: RequestViewModel
    @EnvironmentObject var coordinator: AppCoordinator
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                } else if viewModel.incomingRequests.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(viewModel.incomingRequests) { booking in
                                RequestCard(booking: booking) {
                                    // Open full request detail
                                    dismiss()
                                    coordinator.presentSheet(.incomingRequest(booking))
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Pending Requests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.green)
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            if let hostId = authService.currentUser?.id {
                viewModel.ensureListening(hostId: hostId)
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()

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

                Image(systemName: "bell.slash.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.green.opacity(0.6))
            }

            VStack(spacing: 12) {
                Text("No Pending Requests")
                    .font(.title2.bold())

                Text("When drivers request to use your charger, you'll see them here")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()
        }
    }
}

// MARK: - Request Card

struct RequestCard: View {
    let booking: Booking
    let onTap: () -> Void
    @State private var driver: User?
    @State private var isLoadingDriver = true

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header: Driver info
                HStack(spacing: 12) {
                    // Driver avatar
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Group {
                                if isLoadingDriver {
                                    ProgressView()
                                        .tint(.green)
                                } else {
                                    Text(driver?.name.prefix(1).uppercased() ?? "D")
                                        .font(.title3.bold())
                                        .foregroundColor(.green)
                                }
                            }
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(driver?.name ?? "Loading...")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .redacted(reason: isLoadingDriver ? .placeholder : [])

                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption2)
                                .foregroundColor(.orange)
                            Text(booking.requestedAt.dateValue(), style: .relative)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("ago")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }

                Divider()

                // Time slot indicator
                if let startTime = booking.scheduledStartTime {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text(startTime.dateValue(), style: .date)
                            .font(.caption.weight(.medium))
                        Text("at")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(startTime.dateValue(), style: .time)
                            .font(.caption.weight(.medium))
                    }
                    .foregroundColor(.primary)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("Wants to charge now")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.primary)
                    }
                }

                // Booking details
                HStack(spacing: 16) {
                    // Duration
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text(formatDuration(booking.estimatedDuration))
                            .font(.caption.weight(.medium))
                    }

                    // Earnings
                    HStack(spacing: 4) {
                        Image(systemName: "leaf.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("+\(booking.creditsUsed ?? 0) credits")
                            .font(.caption.weight(.medium))
                    }

                    Spacer()

                    // Pending badge
                    Text("PENDING")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.15))
                        .cornerRadius(6)
                }
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            loadDriverData()
        }
    }

    // MARK: - Helper Methods

    private func loadDriverData() {
        Task {
            do {
                let fetchedDriver = try await FirestoreService.shared.getUser(uid: booking.driverId)
                await MainActor.run {
                    self.driver = fetchedDriver
                    self.isLoadingDriver = false
                }
            } catch {
                await MainActor.run {
                    self.isLoadingDriver = false
                }
            }
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60

        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
}
