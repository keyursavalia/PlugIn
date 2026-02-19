import SwiftUI
import CoreLocation

struct PrivacySettingsView: View {
    @StateObject private var locationService = LocationService()
    @State private var showLocationAlert = false

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "location.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                            .frame(width: 40, height: 40)
                            .background(Color.green.opacity(0.1))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Location Services")
                                .font(.headline)

                            Text(locationStatusText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Toggle("", isOn: locationBinding)
                            .labelsHidden()
                    }

                    if locationService.authorizationStatus == .denied || locationService.authorizationStatus == .restricted {
                        Text("To enable location services, please go to Settings > Plug In > Location")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.top, 8)
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Permissions")
            } footer: {
                Text("Location access helps you find nearby chargers and allows hosts to see drivers approaching their location.")
            }

            Section {
                VStack(alignment: .leading, spacing: 16) {
                    InfoRow(
                        icon: "map",
                        title: "Find Chargers",
                        description: "See nearby charging stations on the map"
                    )

                    InfoRow(
                        icon: "location.circle",
                        title: "Precise Location",
                        description: "Help drivers navigate to your charger's exact location"
                    )

                    InfoRow(
                        icon: "arrow.triangle.turn.up.right.diamond",
                        title: "Real-Time Updates",
                        description: "Get accurate distances and arrival times"
                    )
                }
                .padding(.vertical, 8)
            } header: {
                Text("Why We Need Location")
            }
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Open Settings", isPresented: $showLocationAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("Location access is currently disabled. Would you like to open Settings to enable it?")
        }
    }

    // MARK: - Computed Properties

    private var locationStatusText: String {
        switch locationService.authorizationStatus {
        case .notDetermined:
            return "Not configured"
        case .authorizedWhenInUse, .authorizedAlways:
            return "Enabled"
        case .denied:
            return "Disabled - Open Settings to enable"
        case .restricted:
            return "Restricted"
        @unknown default:
            return "Unknown"
        }
    }

    private var locationBinding: Binding<Bool> {
        Binding(
            get: {
                locationService.authorizationStatus == .authorizedWhenInUse ||
                locationService.authorizationStatus == .authorizedAlways
            },
            set: { newValue in
                handleLocationToggle(enabled: newValue)
            }
        )
    }

    // MARK: - Helper Methods

    private func handleLocationToggle(enabled: Bool) {
        let currentStatus = locationService.authorizationStatus

        if enabled {
            // User wants to enable location
            if currentStatus == .notDetermined {
                // Request permission
                locationService.requestPermission()
            } else if currentStatus == .denied || currentStatus == .restricted {
                // Already denied - need to open Settings
                showLocationAlert = true
            }
        } else {
            // User wants to disable location
            // Can only be done through Settings
            showLocationAlert = true
        }
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.green)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
            }
        }
    }
}

// MARK: - Preview

struct PrivacySettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PrivacySettingsView()
        }
    }
}
