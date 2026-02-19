import SwiftUI

struct BookingRequestView: View {
    @ObservedObject var viewModel: BookingViewModel
    let charger: Charger
    @Environment(\.dismiss) var dismiss
    @State private var hostData: User?
    @State private var isLoadingHost = true

    /// Whether the charger is currently available based on its schedule
    private var isChargerAvailableNow: Bool {
        charger.isAvailable(at: Date())
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                    // Charger Summary
                    chargerSummaryCard

                    // Schedule Section
                    scheduleSection

                    // Duration Picker
                    durationSection

                    // Credits Summary
                    creditsSummary

                    // Request Button
                    PrimaryButton(
                        title: "Request Charge",
                        action: {
                            Task {
                                // Always use credits
                                viewModel.useCredits = true
                                await viewModel.requestBooking()
                                if viewModel.currentBooking != nil {
                                    dismiss()
                                }
                            }
                        },
                        isLoading: viewModel.isLoading
                    )
                    .padding(.top)
                }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
            .navigationTitle("Request Booking")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadHostData()
            }
            .alert("Cannot Book", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
    }

    private var chargerSummaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Host info with image
            HStack(spacing: 12) {
                if isLoadingHost {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 44, height: 44)
                        .overlay(ProgressView().tint(.green).scaleEffect(0.8))
                } else if let imageURL = hostData?.profileImageURL, !imageURL.isEmpty {
                    AsyncImage(url: URL(string: imageURL)) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Circle()
                            .fill(Color.green.opacity(0.2))
                            .overlay(
                                Text(hostData?.name.prefix(1).uppercased() ?? "H")
                                    .font(.headline.bold())
                                    .foregroundColor(.green)
                            )
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Text(hostData?.name.prefix(1).uppercased() ?? "H")
                                .font(.headline.bold())
                                .foregroundColor(.green)
                        )
                }

                Text(hostData?.name ?? "Loading...")
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                    .redacted(reason: isLoadingHost ? .placeholder : [])
            }

            Divider()

            // Address
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "mappin.circle.fill")
                    .font(.title3)
                    .foregroundColor(.green)

                Text(charger.address)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Hardware specs
            VStack(alignment: .leading, spacing: 12) {
                Text("Hardware Specs")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)

                HStack(spacing: 8) {
                    SpecPill(icon: charger.type.icon, text: charger.type.rawValue.capitalized)
                    SpecPill(icon: "cable.connector", text: charger.connectorType.rawValue.uppercased())
                }

                HStack(spacing: 8) {
                    SpecPill(icon: "bolt.fill", text: "\(String(format: "%.1f", charger.maxSpeed)) kW")
                    SpecPill(icon: charger.hasTetheredCable ? "checkmark.circle.fill" : "xmark.circle.fill",
                             text: charger.hasTetheredCable ? "Cable included" : "Bring cable")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("When")
                .font(.headline)

            // Toggle between now and later
            HStack(spacing: 12) {
                scheduleOptionButton(
                    title: "Charge Now",
                    icon: "bolt.fill",
                    isSelected: !viewModel.scheduleForLater,
                    isDisabled: !isChargerAvailableNow
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.scheduleForLater = false
                    }
                }

                scheduleOptionButton(
                    title: "Schedule",
                    icon: "calendar.badge.clock",
                    isSelected: viewModel.scheduleForLater
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.scheduleForLater = true
                    }
                }
            }

            // Show warning if charger isn't available now
            if !isChargerAvailableNow && !viewModel.scheduleForLater {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text("This charger is not available right now. Please schedule for a later time.")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(10)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }

            if viewModel.scheduleForLater {
                VStack(alignment: .leading, spacing: 12) {
                    DatePicker(
                        "Start Time",
                        selection: $viewModel.scheduledStartTime,
                        in: Date().addingTimeInterval(15 * 60)...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .tint(.green)

                    // Show computed end time
                    HStack(spacing: 6) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("Ends at \(endTimeFormatted)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Warn if scheduled time is outside availability
                    if !charger.isAvailable(at: viewModel.scheduledStartTime) {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text("The charger may not be available at this time based on the host's schedule.")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        .padding(10)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .onAppear {
            // Auto-select "Schedule for Later" if charger isn't available now
            if !isChargerAvailableNow {
                viewModel.scheduleForLater = true
            }
        }
    }

    private func scheduleOptionButton(title: String, icon: String, isSelected: Bool, isDisabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                Text(title)
                    .font(.subheadline.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundColor(isDisabled ? .secondary : (isSelected ? .white : .primary))
            .background(isDisabled ? Color(.systemGray5) : (isSelected ? Color.green : Color(.systemGray6)))
            .cornerRadius(10)
            .opacity(isDisabled ? 0.6 : 1)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
    }

    private var endTimeFormatted: String {
        let endTime = viewModel.scheduledStartTime.addingTimeInterval(viewModel.estimatedDuration)
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: endTime)
    }

    private func loadHostData() async {
        do {
            let host = try await FirestoreService.shared.getUser(uid: charger.hostId)
            await MainActor.run {
                hostData = host
                isLoadingHost = false
            }
        } catch {
            await MainActor.run {
                isLoadingHost = false
            }
        }
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Estimated Duration")
                .font(.headline)

            Picker("Duration", selection: Binding(
                get: { viewModel.durationInHours },
                set: { viewModel.updateDuration(hours: $0) }
            )) {
                Text("1 hour").tag(1.0)
                Text("2 hours").tag(2.0)
                Text("3 hours").tag(3.0)
                Text("4 hours").tag(4.0)
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    private var creditsSummary: some View {
        VStack(spacing: 16) {
            // Credits rate display
            HStack(spacing: 12) {
                Image(systemName: "leaf.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(
                        LinearGradient(
                            colors: [Color.green, Color.green.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Green Credits Payment")
                        .font(.headline)
                    Text("\(charger.creditsPerHour) credits per hour")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            Divider()

            // Estimated total
            HStack {
                Text("Estimated Total")
                    .font(.headline)
                Spacer()
                HStack(spacing: 4) {
                    Text("\(viewModel.estimatedCredits)")
                        .font(.title2.bold())
                        .foregroundColor(.green)
                    Image(systemName: "leaf.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                }
            }

            Text("Based on \(String(format: "%.1f", viewModel.durationInHours)) hours")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

// MARK: - Spec Pill Component

struct SpecPill: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption.weight(.medium))
        }
        .foregroundColor(.primary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
    }
}

struct PaymentOptionRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : .green)
                    .frame(width: 40, height: 40)
                    .background(isSelected ? Color.green : Color.green.opacity(0.1))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
            )
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
