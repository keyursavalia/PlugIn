import SwiftUI

struct HostDashboardView: View {
    @StateObject private var viewModel = HostDashboardViewModel()
    @StateObject private var requestViewModel = RequestViewModel()
    @EnvironmentObject var coordinator: AppCoordinator
    @EnvironmentObject var authService: AuthService
    @State private var chargerToDelete: Charger?
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("HOST MODE")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Dashboard")
                            .font(.largeTitle.bold())
                    }
                    Spacer()
                    
                    // Notification bell
                    ZStack(alignment: .topTrailing) {
                        Button(action: {
                            coordinator.presentSheet(.requestsList)
                        }) {
                            Image(systemName: requestViewModel.incomingRequests.isEmpty ? "bell" : "bell.fill")
                                .font(.title2)
                                .foregroundColor(requestViewModel.incomingRequests.isEmpty ? .primary : .orange)
                        }

                        if !requestViewModel.incomingRequests.isEmpty {
                            ZStack {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 18, height: 18)

                                Text("\(requestViewModel.incomingRequests.count)")
                                    .font(.caption2.bold())
                                    .foregroundColor(.white)
                            }
                            .offset(x: 8, y: -8)
                        }
                    }
                }
                
                // Incoming Requests Alert
                if !requestViewModel.incomingRequests.isEmpty {
                    incomingRequestsAlert
                }

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                } else if viewModel.chargers.isEmpty {
                    emptyStateView
                } else {
                    // List of charger cards
                    VStack(spacing: 16) {
                        ForEach(viewModel.chargers) { charger in
                            ChargerCard(
                                charger: charger,
                                onToggleAvailability: {
                                    Task { await viewModel.toggleAvailability(for: charger) }
                                },
                                onEdit: {
                                    coordinator.presentSheet(.editCharger(charger))
                                },
                                onDelete: {
                                    chargerToDelete = charger
                                    showDeleteConfirmation = true
                                }
                            )
                        }
                    }
                    
                    // Add another charger button
                    Button(action: { coordinator.presentSheet(.addCharger) }) {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                            Text("Add Another Charger")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .foregroundColor(.green)
                        .background(Color.green.opacity(0.15))
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            if let hostId = authService.currentUser?.id {
                viewModel.ensureListening(hostId: hostId)
                requestViewModel.ensureListening(hostId: hostId)
            }
        }
        .onChange(of: coordinator.presentedSheet) { _, newValue in
            if newValue == nil {
                if let hostId = authService.currentUser?.id {
                    viewModel.ensureListening(hostId: hostId)
                    requestViewModel.ensureListening(hostId: hostId)
                }
            }
        }
        .alert("Delete Charger", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                chargerToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let charger = chargerToDelete {
                    Task { await viewModel.deleteCharger(charger) }
                }
                chargerToDelete = nil
            }
        } message: {
            Text("Are you sure you want to remove this charger? This cannot be undone.")
        }
    }
    
    // MARK: - Incoming Requests Alert
    private var incomingRequestsAlert: some View {
        Button(action: {
            if let request = requestViewModel.incomingRequests.first {
                coordinator.presentSheet(.incomingRequest(request))
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("New Booking Request!")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("\(requestViewModel.incomingRequests.count) pending request\(requestViewModel.incomingRequests.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.orange.opacity(0.15), Color.orange.opacity(0.05)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.orange, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 24) {
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
                
                Image(systemName: "leaf.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 12) {
                Text("Make a Difference")
                    .font(.system(size: 28, weight: .bold))
                
                Text("Share your charger with EV drivers and help reduce carbon emissions together")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            VStack(spacing: 16) {
                BenefitRow(
                    icon: "dollarsign.circle.fill",
                    title: "Earn Credits",
                    description: "Turn idle charging time into rewards"
                )
                
                BenefitRow(
                    icon: "leaf.circle.fill",
                    title: "Help the Planet",
                    description: "Support the EV community & sustainability"
                )
                
                BenefitRow(
                    icon: "chart.line.uptrend.xyaxis.circle.fill",
                    title: "Full Control",
                    description: "Set your own rates and availability"
                )
            }
            .padding(.horizontal)

            Button(action: { coordinator.presentSheet(.addCharger) }) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                    Text("Share Your Charger")
                        .font(.system(size: 17, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .foregroundColor(.white)
                .background(
                    LinearGradient(
                        colors: [Color.green, Color.green.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal)
            
            Text("It only takes 2 minutes to get started")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.top, 20)
        .padding(.bottom, 40)
    }
}

// MARK: - Benefit Row Component
struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.green)
                .frame(width: 44, height: 44)
                .background(Color.green.opacity(0.1))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
