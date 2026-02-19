import FirebaseAuth
import FirebaseFirestore
import Combine

class AuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoadingUser = true
    
    private let auth = Auth.auth()
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    private var userListener: ListenerRegistration?
    
    init() {
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        authStateHandler = auth.addStateDidChangeListener { [weak self] _, firebaseUser in
            guard let self = self else { return }
            
            Task { @MainActor in
                self.isAuthenticated = firebaseUser != nil
                
                if let firebaseUser = firebaseUser {
                    // Set loading state before fetching
                    self.isLoadingUser = true
                    self.listenToUserData(uid: firebaseUser.uid)
                } else {
                    self.userListener?.remove()
                    self.userListener = nil
                    self.currentUser = nil
                    self.isLoadingUser = false
                }
            }
        }
    }
    
    func signUp(email: String, password: String, name: String) async throws -> User {
        let result = try await auth.createUser(withEmail: email, password: password)
        
        let user = User(
            id: result.user.uid,
            email: email,
            name: name,
            roles: [.driver],
            greenCredits: 0,
            createdAt: Timestamp()
        )
        
        // Save to Firestore
        try await FirestoreService.shared.saveUser(user)
        
        // Immediately set currentUser to avoid race condition
        await MainActor.run {
            self.currentUser = user
            self.isLoadingUser = false
        }
        
        return user
    }
    
    func signIn(email: String, password: String) async throws {
        // Set loading state before sign in
        await MainActor.run {
            self.isLoadingUser = true
        }
        try await auth.signIn(withEmail: email, password: password)
        // Auth state listener will handle the rest
    }
    
    func signOut() throws {
        try auth.signOut()
    }

    func updateUserProfile(name: String? = nil, profileImageURL: String? = nil) async throws {
        guard var user = currentUser else { return }

        if let name = name {
            user.name = name
        }

        if let profileImageURL = profileImageURL {
            user.profileImageURL = profileImageURL
        }

        try await FirestoreService.shared.updateUser(user)

        await MainActor.run {
            self.currentUser = user
        }
    }

    func refreshCurrentUser() async {
        guard let userId = currentUser?.id else { return }
        do {
            let updatedUser = try await FirestoreService.shared.getUser(uid: userId)
            await MainActor.run {
                self.currentUser = updatedUser
            }
        } catch {
            print("Error refreshing user: \(error)")
        }
    }

    /// Adds the host role to the current user if they don't already have it
    /// Called when user explicitly selects host role or registers a charger
    func addHostRole() async throws {
        guard var user = currentUser else { return }

        // Only add if not already a host
        if !user.roles.contains(.host) {
            user.roles.append(.host)
            try await FirestoreService.shared.updateUser(user)

            await MainActor.run {
                self.currentUser = user
            }
        }
    }

    private func listenToUserData(uid: String) {
        userListener?.remove()
        userListener = Firestore.firestore().collection("users").document(uid)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    Task { @MainActor in
                        self.isLoadingUser = false
                    }
                    return
                }

                guard let snapshot = snapshot, snapshot.exists,
                      let user = try? snapshot.data(as: User.self) else {
                    Task { @MainActor in
                        self.isLoadingUser = false
                    }
                    return
                }

                Task { @MainActor in
                    self.currentUser = user
                    self.isLoadingUser = false
                }
            }
    }
    
    deinit {
        if let handle = authStateHandler {
            auth.removeStateDidChangeListener(handle)
        }
        userListener?.remove()
    }
}

