import SwiftUI
import FirebaseFirestore

struct IncomingRequestView: View {
    let booking: Booking
    let onAccept: () async -> Void
    let onDecline: () async -> Void
    @Environment(\.dismiss) var dismiss
    @State private var isProcessing = false
    @State private var driver: User?
    @State private var isLoadingDriver = true

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("INCOMING REQUEST")
                    .font(.headline.bold())
                    .foregroundColor(.black)
                    .tracking(1)

                // Driver profile
                VStack(spacing: 12) {
                    // Driver image/avatar
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.green.opacity(0.3), Color.green.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .overlay(
                            Group {
                                if isLoadingDriver {
                                    ProgressView()
                                        .tint(.green)
                                } else if let imageURL = driver?.profileImageURL, !imageURL.isEmpty {
                                    // TODO: Load image from URL
                                    AsyncImage(url: URL(string: imageURL)) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    } placeholder: {
                                        Text(driver?.name.prefix(1).uppercased() ?? "D")
                                            .font(.title.bold())
                                            .foregroundColor(.green)
                                    }
                                } else {
                                    Text(driver?.name.prefix(1).uppercased() ?? "D")
                                        .font(.title.bold())
                                        .foregroundColor(.green)
                                }
                            }
                        )
                        .overlay(
                            Group {
                                if let rating = driver?.rating {
                                    HStack(spacing: 4) {
                                        Image(systemName: "star.fill")
                                            .font(.caption)
                                        Text(String(format: "%.1f", rating))
                                            .font(.caption.bold())
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green)
                                    .cornerRadius(12)
                                    .offset(y: 35)
                                }
                            }
                        )

                    if isLoadingDriver {
                        Text("Loading...")
                            .font(.title2.bold())
                            .foregroundColor(.secondary)
                            .redacted(reason: .placeholder)
                    } else {
                        Text(driver?.name ?? "Driver")
                            .font(.title.bold())
                            .foregroundColor(.primary)
                    }
                }
            }
            .onAppear {
                Task {
                    await fetchDriverData()
                }
            }
            
            // Request details
            VStack(spacing: 16) {
                DetailCard {
                    VStack(spacing: 12) {
                        // Scheduled time slot
                        HStack(spacing: 12) {
                            Image(systemName: booking.scheduledStartTime != nil ? "calendar.badge.clock" : "bolt.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(booking.scheduledStartTime != nil ? Color.orange : Color.green)
                                .cornerRadius(10)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("SCHEDULED FOR")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                if let startTime = booking.scheduledStartTime {
                                    Text(startTime.dateValue(), style: .date)
                                        .font(.headline)
                                    HStack(spacing: 4) {
                                        Text(startTime.dateValue(), style: .time)
                                        Text("-")
                                        if let endTime = booking.scheduledEndTime {
                                            Text(endTime, style: .time)
                                        }
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                } else {
                                    Text("Immediate / ASAP")
                                        .font(.headline)
                                    Text("Driver wants to charge now")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()
                        }

                        Divider()

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("REQUESTED AT")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(booking.requestedAt.dateValue(), style: .relative)
                                    .font(.subheadline)
                                + Text(" ago")
                                    .font(.subheadline)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text("DURATION")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(formatDuration(booking.estimatedDuration))
                                    .font(.headline)
                            }
                        }

                        Divider()

                        HStack {
                            Text("EST. EARNINGS")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            if let credits = booking.creditsUsed {
                                HStack(spacing: 4) {
                                    Text("+\(credits)")
                                        .font(.title3.bold())
                                        .foregroundColor(.green)
                                    Image(systemName: "leaf.fill")
                                        .foregroundColor(.green)
                                }
                            } else {
                                Text("+$\(String(format: "%.2f", booking.amountPaid ?? 0))")
                                    .font(.title3.bold())
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            // Actions
            VStack(spacing: 12) {
                PrimaryButton(
                    title: "Accept Request",
                    action: {
                        isProcessing = true
                        Task {
                            await onAccept()
                            isProcessing = false
                            dismiss()
                        }
                    },
                    isLoading: isProcessing
                )

                DestructiveButton(title: "Decline Request") {
                    isProcessing = true
                    Task {
                        await onDecline()
                        isProcessing = false
                        dismiss()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Helper Methods

    private func fetchDriverData() async {
        isLoadingDriver = true
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

struct DetailCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
