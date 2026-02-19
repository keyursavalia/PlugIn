import SwiftUI
import FirebaseAuth

struct AccountSettingsView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss

    @State private var name: String = ""
    @State private var email: String = ""
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var isUploadingImage = false
    @State private var isSaving = false
    @State private var showUploadError = false
    @State private var uploadErrorMessage = ""

    // Password change
    @State private var showChangePassword = false
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showPasswordError = false
    @State private var passwordErrorMessage = ""

    // Delete account
    @State private var showDeleteConfirmation = false
    @State private var deletePassword = ""
    @State private var isDeleting = false

    var body: some View {
        List {
            // Profile Section
            Section {
                HStack(spacing: 16) {
                    // Profile Image
                    ZStack(alignment: .bottomTrailing) {
                        if let profileImageURL = authService.currentUser?.profileImageURL,
                           !profileImageURL.isEmpty {
                            AsyncImage(url: URL(string: profileImageURL)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                profileInitialsView
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                        } else {
                            profileInitialsView
                        }

                        // Camera icon overlay
                        if !isUploadingImage {
                            Button(action: { showImagePicker = true }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 28, height: 28)

                                    Image(systemName: "camera.fill")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                }
                            }
                            .offset(x: -2, y: -2)
                        } else {
                            ProgressView()
                                .tint(.white)
                                .padding(6)
                                .background(Circle().fill(Color.green))
                                .offset(x: -2, y: -2)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Profile Photo")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Button(action: { showImagePicker = true }) {
                            Text(authService.currentUser?.profileImageURL != nil ? "Change Photo" : "Add Photo")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        .disabled(isUploadingImage)
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Profile")
            }

            // Personal Information
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("Full Name", text: $name)
                        .textContentType(.name)
                        .autocapitalization(.words)
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .disabled(true) // Email can't be changed easily in Firebase
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Personal Information")
            } footer: {
                Text("Email address cannot be changed")
            }

            // Security Section
            Section {
                Button(action: { showChangePassword = true }) {
                    HStack {
                        Label("Change Password", systemImage: "lock.rotation")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Security")
            }

            // Danger Zone
            Section {
                Button(action: { showDeleteConfirmation = true }) {
                    HStack {
                        Spacer()
                        Label("Delete Account", systemImage: "trash")
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
            } header: {
                Text("Danger Zone")
            } footer: {
                Text("Deleting your account will permanently remove all your data including bookings, chargers, and credits. This action cannot be undone.")
            }
        }
        .navigationTitle("Account Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: saveChanges) {
                    if isSaving {
                        ProgressView()
                            .tint(.green)
                    } else {
                        Text("Save")
                            .foregroundColor(.green)
                            .fontWeight(.semibold)
                    }
                }
                .disabled(isSaving)
            }
        }
        .onAppear {
            loadUserData()
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .sheet(isPresented: $showChangePassword) {
            ChangePasswordView(
                currentPassword: $currentPassword,
                newPassword: $newPassword,
                confirmPassword: $confirmPassword,
                onPasswordChanged: {
                    showChangePassword = false
                    currentPassword = ""
                    newPassword = ""
                    confirmPassword = ""
                }
            )
        }
        .alert("Delete Account", isPresented: $showDeleteConfirmation) {
            SecureField("Enter password to confirm", text: $deletePassword)

            Button("Cancel", role: .cancel) {
                deletePassword = ""
            }

            Button("Delete", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("Are you absolutely sure? This action cannot be undone. All your data will be permanently deleted.")
        }
        .onChange(of: selectedImage) { _, newImage in
            if let image = newImage {
                uploadProfileImage(image)
            }
        }
        .alert("Upload Failed", isPresented: $showUploadError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(uploadErrorMessage)
        }
    }

    // MARK: - Computed Properties

    private var profileInitialsView: some View {
        Circle()
            .fill(Color.green.opacity(0.2))
            .frame(width: 80, height: 80)
            .overlay(
                Text(initials)
                    .font(.title.bold())
                    .foregroundColor(.green)
            )
    }

    private var initials: String {
        guard let name = authService.currentUser?.name else { return "?" }
        let components = name.components(separatedBy: " ")
        let firstInitial = components.first?.first.map(String.init) ?? ""
        let lastInitial = components.count > 1 ? components.last?.first.map(String.init) ?? "" : ""
        return (firstInitial + lastInitial).uppercased()
    }

    private var hasChanges: Bool {
        guard let user = authService.currentUser else { return false }
        return name != user.name
    }

    // MARK: - Helper Methods

    private func loadUserData() {
        guard let user = authService.currentUser else { return }
        name = user.name
        email = user.email
    }

    private func saveChanges() {
        // If no changes, just dismiss
        if !hasChanges {
            dismiss()
            return
        }

        isSaving = true

        Task {
            do {
                try await authService.updateUserProfile(name: name)

                await MainActor.run {
                    isSaving = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                }
            }
        }
    }

    private func uploadProfileImage(_ image: UIImage) {
        guard let userId = authService.currentUser?.id else { return }

        isUploadingImage = true

        Task {
            do {
                let imageURL = try await FirebaseStorageService.shared.uploadProfileImage(
                    userId: userId,
                    image: image
                )

                try await authService.updateUserProfile(profileImageURL: imageURL)

                await MainActor.run {
                    isUploadingImage = false
                    selectedImage = nil
                }
            } catch {
                await MainActor.run {
                    isUploadingImage = false
                    selectedImage = nil
                    if "\(error)".contains("not authorized") || "\(error)".contains("Object") || "\(error)".contains("403") || "\(error)".contains("unauthorized") {
                        uploadErrorMessage = "Firebase Storage rules are not configured. Please update your Storage rules in Firebase Console to allow authenticated uploads to profile_images/."
                    } else {
                        uploadErrorMessage = "Could not upload your photo: \(error.localizedDescription)"
                    }
                    showUploadError = true
                }
            }
        }
    }

    private func deleteAccount() {
        guard !deletePassword.isEmpty,
              let email = authService.currentUser?.email else { return }

        isDeleting = true

        Task {
            do {
                // Re-authenticate user before deletion
                let credential = EmailAuthProvider.credential(withEmail: email, password: deletePassword)
                try await Auth.auth().currentUser?.reauthenticate(with: credential)

                // Delete user data from Firestore
                if let userId = authService.currentUser?.id {
                    // Delete profile image if exists
                    if authService.currentUser?.profileImageURL != nil {
                        try? await FirebaseStorageService.shared.deleteProfileImage(userId: userId)
                    }

                    // Delete chargers owned by user
                    let chargers = try await FirestoreService.shared.getChargersByHost(hostId: userId)
                    for charger in chargers {
                        if let chargerId = charger.id {
                            try await FirestoreService.shared.deleteCharger(id: chargerId)
                        }
                    }
                }

                // Delete Firebase Auth account
                try await Auth.auth().currentUser?.delete()

                await MainActor.run {
                    isDeleting = false
                    deletePassword = ""
                    // Auth state listener will handle sign out
                }
            } catch let error as NSError {
                await MainActor.run {
                    isDeleting = false
                    deletePassword = ""
                }
            }
        }
    }
}

// MARK: - Change Password View

struct ChangePasswordView: View {
    @Binding var currentPassword: String
    @Binding var newPassword: String
    @Binding var confirmPassword: String
    let onPasswordChanged: () -> Void

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    @State private var isChanging = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            List {
                Section {
                    SecureField("Current Password", text: $currentPassword)
                        .textContentType(.password)
                } header: {
                    Text("Current Password")
                }

                Section {
                    SecureField("New Password", text: $newPassword)
                        .textContentType(.newPassword)

                    SecureField("Confirm New Password", text: $confirmPassword)
                        .textContentType(.newPassword)
                } header: {
                    Text("New Password")
                } footer: {
                    Text("Password must be at least 6 characters")
                }

                if showError {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.green)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: changePassword) {
                        if isChanging {
                            ProgressView()
                                .tint(.green)
                        } else {
                            Text("Save")
                                .foregroundColor(.green)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isChanging || !isValid)
                }
            }
        }
    }

    private var isValid: Bool {
        !currentPassword.isEmpty &&
        !newPassword.isEmpty &&
        newPassword.count >= 6 &&
        newPassword == confirmPassword
    }

    private func changePassword() {
        guard let email = authService.currentUser?.email else { return }

        isChanging = true
        showError = false

        Task {
            do {
                // Re-authenticate user
                let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
                try await Auth.auth().currentUser?.reauthenticate(with: credential)

                // Update password
                try await Auth.auth().currentUser?.updatePassword(to: newPassword)

                await MainActor.run {
                    isChanging = false
                    onPasswordChanged()
                    dismiss()
                }
            } catch let error as NSError {
                await MainActor.run {
                    isChanging = false
                    showError = true

                    if error.code == AuthErrorCode.wrongPassword.rawValue {
                        errorMessage = "Current password is incorrect"
                    } else if error.code == AuthErrorCode.weakPassword.rawValue {
                        errorMessage = "New password is too weak"
                    } else {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct AccountSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AccountSettingsView()
                .environmentObject(AuthService())
        }
    }
}
