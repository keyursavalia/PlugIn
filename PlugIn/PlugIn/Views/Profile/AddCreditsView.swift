import SwiftUI

struct AddCreditsView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    @State private var selectedPackage: CreditPackage?
    @State private var showPaymentSheet = false
    @State private var isProcessing = false

    let creditPackages: [CreditPackage] = [
        CreditPackage(credits: 10, price: 4.99, bonus: 0),
        CreditPackage(credits: 25, price: 9.99, bonus: 5, isPopular: true),
        CreditPackage(credits: 50, price: 19.99, bonus: 15),
        CreditPackage(credits: 100, price: 34.99, bonus: 35)
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.green.opacity(0.3), Color.green.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)

                            Image(systemName: "leaf.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.green)
                        }
                        .padding(.top, 20)

                        Text("Add Green Credits")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)

                        Text("Power your EV charging journey")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }

                    // Current Balance
                    HStack(spacing: 12) {
                        Image(systemName: "leaf.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Balance")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("\(authService.currentUser?.greenCredits ?? 0) Credits")
                                .font(.title3.bold())
                                .foregroundColor(.primary)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Credit Packages
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Choose a Package")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(creditPackages) { package in
                            CreditPackageCard(
                                package: package,
                                isSelected: selectedPackage?.id == package.id,
                                onSelect: {
                                    selectedPackage = package
                                }
                            )
                        }
                    }

                    // Info Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Why Buy Credits?")
                            .font(.headline)

                        VStack(spacing: 12) {
                            InfoRow(
                                icon: "bolt.fill",
                                title: "Instant Charging",
                                description: "Book chargers instantly without waiting"
                            )

                            InfoRow(
                                icon: "percent",
                                title: "Better Value",
                                description: "Get bonus credits with larger packages"
                            )

                            InfoRow(
                                icon: "lock.shield.fill",
                                title: "Secure Payment",
                                description: "Your payment information is encrypted"
                            )
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding(.horizontal)

                    Spacer(minLength: 40)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.green)
                }
            }
            .safeAreaInset(edge: .bottom) {
                purchaseButton
            }
            .sheet(isPresented: $showPaymentSheet) {
                PaymentMethodsView(
                    package: selectedPackage,
                    onPurchaseComplete: { credits in
                        addCreditsToAccount(credits)
                    }
                )
            }
        }
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        VStack(spacing: 0) {
            Divider()

            Button(action: {
                if selectedPackage != nil {
                    showPaymentSheet = true
                }
            }) {
                HStack {
                    if isProcessing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        if let package = selectedPackage {
                            Text("Purchase \(package.totalCredits) Credits for $\(String(format: "%.2f", package.price))")
                                .font(.headline)
                        } else {
                            Text("Select a Package")
                                .font(.headline)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .foregroundColor(.white)
                .background(
                    selectedPackage != nil ?
                        LinearGradient(
                            colors: [Color.green, Color.green.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [Color.gray, Color.gray],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                )
                .cornerRadius(12)
            }
            .disabled(selectedPackage == nil || isProcessing)
            .padding()
            .background(Color(.systemGroupedBackground))
        }
    }

    // MARK: - Helper Methods

    private func addCreditsToAccount(_ credits: Int) {
        guard let userId = authService.currentUser?.id else { return }

        isProcessing = true

        Task {
            do {
                // Add credits to user account
                try await FirestoreService.shared.updateUserCredits(
                    userId: userId,
                    creditsChange: credits
                )

                // Fetch updated user data to ensure real-time sync
                let updatedUser = try await FirestoreService.shared.getUser(uid: userId)

                await MainActor.run {
                    authService.currentUser = updatedUser
                    isProcessing = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                }
            }
        }
    }
}

// MARK: - Credit Package Model

struct CreditPackage: Identifiable {
    let id = UUID()
    let credits: Int
    let price: Double
    let bonus: Int
    var isPopular: Bool = false

    var totalCredits: Int {
        credits + bonus
    }

    var bonusText: String? {
        bonus > 0 ? "+\(bonus) Bonus" : nil
    }
}

// MARK: - Credit Package Card

struct CreditPackageCard: View {
    let package: CreditPackage
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 0) {
                // Popular badge
                if package.isPopular {
                    HStack {
                        Spacer()
                        Text("MOST POPULAR")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.orange)
                            .cornerRadius(8, corners: [.topLeft, .topRight])
                        Spacer()
                    }
                }

                HStack(spacing: 16) {
                    // Radio button
                    ZStack {
                        Circle()
                            .stroke(isSelected ? Color.green : Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 24, height: 24)

                        if isSelected {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 14, height: 14)
                        }
                    }

                    // Credits info
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Image(systemName: "leaf.fill")
                                    .font(.title3)
                                    .foregroundColor(.green)
                                Text("\(package.totalCredits)")
                                    .font(.title2.bold())
                                    .foregroundColor(.primary)
                                Text("Credits")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            if let bonusText = package.bonusText {
                                Text(bonusText)
                                    .font(.caption.bold())
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.orange.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }

                        if package.bonus > 0 {
                            Text("\(package.credits) + \(package.bonus) bonus credits")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    // Price
                    Text("$\(String(format: "%.2f", package.price))")
                        .font(.title3.bold())
                        .foregroundColor(.primary)
                }
                .padding()
                .background(package.isPopular ? Color.orange.opacity(0.05) : Color.white)
            }
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.green :
                        package.isPopular ? Color.orange.opacity(0.3) :
                        Color.clear,
                        lineWidth: 2
                    )
            )
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
}

// MARK: - Payment Methods View

struct PaymentMethodsView: View {
    let package: CreditPackage?
    let onPurchaseComplete: (Int) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var isProcessing = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Summary
                    VStack(spacing: 16) {
                        Text("Purchase Summary")
                            .font(.headline)

                        if let package = package {
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Credits")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    HStack(spacing: 4) {
                                        Image(systemName: "leaf.fill")
                                            .foregroundColor(.green)
                                        Text("\(package.totalCredits)")
                                            .font(.headline)
                                    }
                                }

                                Divider()

                                HStack {
                                    Text("Total")
                                        .font(.headline)
                                    Spacer()
                                    Text("$\(String(format: "%.2f", package.price))")
                                        .font(.title3.bold())
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top)

                    // Demo Payment Methods
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Payment Method")
                            .font(.headline)
                            .padding(.horizontal)

                        VStack(spacing: 12) {
                            PaymentMethodRow(
                                icon: "creditcard.fill",
                                title: "Credit Card",
                                subtitle: "Visa, Mastercard, Amex"
                            )

                            PaymentMethodRow(
                                icon: "applelogo",
                                title: "Apple Pay",
                                subtitle: "Quick and secure"
                            )

                            PaymentMethodRow(
                                icon: "g.circle.fill",
                                title: "Google Pay",
                                subtitle: "Fast checkout"
                            )
                        }
                        .padding(.horizontal)
                    }

                    // Demo Note
                    VStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)

                        Text("Demo Mode")
                            .font(.headline)

                        Text("This is a demonstration. No actual payment will be processed. Credits will be added to your account instantly.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    Spacer(minLength: 40)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.green)
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    Divider()

                    Button(action: {
                        processPayment()
                    }) {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .tint(.white)
                                Text("Processing...")
                            } else {
                                Text("Complete Purchase")
                                    .font(.headline)
                            }
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
                    }
                    .disabled(isProcessing)
                    .padding()
                    .background(Color(.systemGroupedBackground))
                }
            }
        }
    }

    private func processPayment() {
        guard let package = package else { return }

        isProcessing = true

        // Simulate payment processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            onPurchaseComplete(package.totalCredits)
            dismiss()
        }
    }
}

// MARK: - Payment Method Row

struct PaymentMethodRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.green)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

// MARK: - Preview

struct AddCreditsView_Previews: PreviewProvider {
    static var previews: some View {
        AddCreditsView()
            .environmentObject(AuthService())
    }
}
