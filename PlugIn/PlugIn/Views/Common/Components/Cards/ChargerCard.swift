import SwiftUI

struct ChargerCard: View {
    let charger: Charger
    let onToggleAvailability: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    private var isAvailable: Bool {
        charger.status == .available
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header: status + actions
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(isAvailable ? Color.green : Color.gray)
                        .frame(width: 10, height: 10)
                    Text(isAvailable ? "Available" : "Offline")
                        .font(.subheadline.weight(.semibold))
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { isAvailable },
                    set: { _ in onToggleAvailability() }
                ))
                .labelsHidden()
            }
            
            // Location
            HStack(spacing: 8) {
                Image(systemName: "mappin.circle.fill")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(charger.address)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                Spacer()
            }
            
            // Info row: output, connector, rate (Task 12: Show only credits)
            HStack(spacing: 16) {
                Label("\(String(format: "%.1f", charger.maxSpeed)) kW", systemImage: "bolt.fill")
                Label(charger.connectorType.rawValue, systemImage: "cable.connector")
                Label("\(charger.creditsPerHour) credits/hr", systemImage: "leaf.fill")
                Spacer()
            }
            .font(.caption)
            .foregroundColor(.secondary)

            // Stats row (Task 8: Remove rating, Task 9: Dynamic bookings)
            HStack(spacing: 20) {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                        .foregroundColor(.green)
                    Text("\(charger.totalBookings) bookings")
                        .font(.caption2)
                }
                HStack(spacing: 4) {
                    Image(systemName: "leaf.fill")
                        .font(.caption2)
                        .foregroundColor(.green)
                    Text("\(charger.totalBookings * charger.creditsPerHour) credits earned")
                        .font(.caption2)
                }
                Spacer()
            }
            .foregroundColor(.secondary)
            
            // Actions (Task 11: Green theme buttons)
            HStack(spacing: 12) {
                Button(action: onEdit) {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                        Text("Edit")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.green)
                }

                Spacer()

                Button(action: onDelete) {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                        Text("Delete")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}


