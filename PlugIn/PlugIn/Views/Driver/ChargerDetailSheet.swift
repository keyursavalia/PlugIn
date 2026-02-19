import SwiftUI

struct ChargerDetailSheet: View {
    let charger: Charger
    let distance: String?
    let onRequestCharge: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Info cards - uniform styling
            VStack(spacing: 16) {
                // Charger specs row
                HStack(spacing: 12) {
                    InfoPill(icon: charger.type.icon, label: charger.type.rawValue, color: .green)
                    InfoPill(icon: "cable.connector", label: charger.connectorType.rawValue, color: .blue)
                    InfoPill(icon: "bolt.fill", label: "\(String(format: "%.1f", charger.maxSpeed)) kW", color: .orange)
                }
                
                // Location row
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(charger.address)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                        if let distance = distance {
                            Text("\(distance) away")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                }
                .padding(16)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Price row
                HStack(spacing: 12) {
                    Image(systemName: "leaf.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(
                            LinearGradient(
                                colors: [Color.green, Color.green.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Text("\(charger.creditsPerHour)")
                                .font(.title2.bold())
                                .foregroundColor(.green)
                            Text("credits/hour")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Text("Green Credits Payment")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(16)
                .background(Color.green.opacity(0.05))
                .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 20)
            
            // Request Charge button
            PrimaryButton(title: "Request Charge") {
                onRequestCharge()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }
}

// MARK: - Info Pill Component
private struct InfoPill: View {
    let icon: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(color.opacity(0.15))
        .cornerRadius(10)
    }
}
