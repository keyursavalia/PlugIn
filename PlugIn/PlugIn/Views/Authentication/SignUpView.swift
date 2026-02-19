import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authService: AuthService
    @State private var isSignUpMode = true
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && password.count >= 6
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Logo
            Image(systemName: "bolt.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Plug-In")
                .font(.system(size: 32, weight: .bold))
            
            Text(isSignUpMode ? "Share chargers. Drive green." : "Welcome back!")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Form
            VStack(spacing: 16) {
                if isSignUpMode {
                    CustomTextField(
                        title: "Name",
                        placeholder: "Enter your name",
                        text: $name
                    )
                }
                
                CustomTextField(
                    title: "Email",
                    placeholder: "Enter your email",
                    text: $email,
                    keyboardType: .emailAddress
                )
                
                CustomTextField(
                    title: "Password",
                    placeholder: "Min. 6 characters",
                    text: $password,
                    isSecure: true
                )
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                PrimaryButton(
                    title: isSignUpMode ? "Create Account" : "Sign In",
                    action: {
                        Task {
                            if isSignUpMode {
                                await signUp()
                            } else {
                                await signIn()
                            }
                        }
                    },
                    isLoading: isLoading,
                    isDisabled: !isFormValid
                )
            }
            
            Spacer()
            
            HStack {
                Text(isSignUpMode ? "Already have an account?" : "Don't have an account?")
                    .foregroundColor(.secondary)
                Button(isSignUpMode ? "Sign In" : "Sign Up") {
                    isSignUpMode.toggle()
                    errorMessage = nil
                }
                .foregroundColor(.blue)
            }
            .font(.subheadline)
        }
        .padding(24)
    }
    
    private func signUp() async {
        guard isFormValid else {
            errorMessage = "Please fill all fields"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await authService.signUp(
                email: email,
                password: password,
                name: name.isEmpty ? "User" : name
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func signIn() async {
        guard !email.isEmpty && !password.isEmpty else {
            errorMessage = "Please enter email and password"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
