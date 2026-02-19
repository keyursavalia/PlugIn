import SwiftUI

struct StatusBadge: View {
    let status: ChargerStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status.color)
                .frame(width: 6, height: 6)
            Text(status.rawValue.capitalized)
                .font(.caption.weight(.medium))
        }
        .foregroundColor(status.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.1))
        .cornerRadius(6)
    }
}

