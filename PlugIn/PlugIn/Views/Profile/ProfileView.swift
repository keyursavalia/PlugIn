import SwiftUI
import Combine

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showSignOutAlert = false
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var isUploadingImage = false
    @State private var showAddCredits = false
    @State private var showUploadError = false
    @State private var uploadErrorMessage = ""

    var body: some View {
        NavigationView {
            List {
                // User Info Section
                Section {
                    VStack(spacing: 16) {
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
                                Text(authService.currentUser?.name ?? "User")
                                    .font(.title2.bold())
                                    .foregroundColor(.primary)

                                Button(action: { showImagePicker = true }) {
                                    Text(authService.currentUser?.profileImageURL != nil ? "Change Photo" : "Add Photo")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                                .disabled(isUploadingImage)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Credits Section
                Section(header: Text("Green Credits")) {
                    HStack {
                        Image(systemName: "leaf.fill")
                            .foregroundColor(.green)
                        Text("Balance")
                        Spacer()
                        Text("\(authService.currentUser?.greenCredits ?? 0)")
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                    
                    Button(action: { showAddCredits = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Credits")
                        }
                    }
                }
                
                // Settings Section
                Section(header: Text("Settings")) {
                    NavigationLink(destination: AccountSettingsView()) {
                        Label("Account", systemImage: "person.circle")
                    }

                    NavigationLink(destination: PrivacySettingsView()) {
                        Label("Privacy", systemImage: "lock.shield")
                    }

                    NavigationLink(destination: PastRequestsView()) {
                        Label("Past Requests", systemImage: "clock.arrow.circlepath")
                    }
                }

                // About Section
                Section(header: Text("About")) {
                    NavigationLink(destination: AboutView()) {
                        Label("About Plug In", systemImage: "info.circle")
                    }
                }

                // Sign Out Section
                Section {
                    Button(action: { showSignOutAlert = true }) {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
            .sheet(isPresented: $showAddCredits) {
                AddCreditsView()
                    .environmentObject(authService)
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
    }

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
    
    private func signOut() {
        do {
            try authService.signOut()
        } catch {
            print("Error signing out: \(error)")
        }
    }

    private func uploadProfileImage(_ image: UIImage) {
        guard let userId = authService.currentUser?.id else { return }

        isUploadingImage = true

        Task {
            do {
                // Upload image to Firebase Storage
                let imageURL = try await FirebaseStorageService.shared.uploadProfileImage(
                    userId: userId,
                    image: image
                )

                // Update user profile with image URL
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
}
