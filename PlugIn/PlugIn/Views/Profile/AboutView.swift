import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
                VStack(spacing: 32) {
                    // Hero Section
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.green.opacity(0.3), Color.green.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)

                            Image(systemName: "leaf.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                        }
                        .padding(.top, 20)

                        VStack(spacing: 8) {
                            Text("Plug In")
                                .font(.system(size: 42, weight: .bold))
                                .foregroundColor(.primary)

                            Text("Share chargers. Drive green.")
                                .font(.title3)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }

                        Text("Version 1.0.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }

                    // Mission Statement
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Our Mission")
                            .font(.title2.bold())
                            .foregroundColor(.primary)

                        Text("Plug In is a peer-to-peer EV charger sharing marketplace connecting drivers who need to charge with hosts who want to share their private chargers. Together, we're building a sustainable future, one charge at a time.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)

                    // How It Works
                    VStack(alignment: .leading, spacing: 20) {
                        Text("How It Works")
                            .font(.title2.bold())
                            .foregroundColor(.primary)

                        HowItWorksStep(
                            number: "1",
                            title: "Find Chargers",
                            description: "Browse available EV chargers near you on our interactive map"
                        )

                        HowItWorksStep(
                            number: "2",
                            title: "Book & Pay",
                            description: "Request charging time and pay securely with Green Credits"
                        )

                        HowItWorksStep(
                            number: "3",
                            title: "Charge & Earn",
                            description: "Drivers charge their EVs, hosts earn rewards for sharing"
                        )
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)

                    // Benefits
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Why Plug In?")
                            .font(.title2.bold())
                            .foregroundColor(.primary)

                        BenefitRow(
                            icon: "leaf.fill",
                            title: "Sustainable",
                            description: "Support the EV revolution and reduce carbon emissions"
                        )

                        BenefitRow(
                            icon: "dollarsign.circle.fill",
                            title: "Earn Rewards",
                            description: "Hosts earn Green Credits for sharing their chargers"
                        )

                        BenefitRow(
                            icon: "network",
                            title: "Community",
                            description: "Join a growing network of EV enthusiasts"
                        )

                        BenefitRow(
                            icon: "sparkles",
                            title: "Convenient",
                            description: "Access chargers in neighborhoods, not just public stations"
                        )
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)

                    // Footer
                    VStack(spacing: 8) {
                        Text("Made with 💚 for a greener future")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("© 2024 Plug In. All rights reserved.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 32)
                }
                .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("About Plug In")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - How It Works Step

struct HowItWorksStep: View {
    let number: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.green, Color.green.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Text(number)
                    .font(.title3.bold())
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
            }
        }
    }
}

// MARK: - Preview

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
