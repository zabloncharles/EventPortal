import SwiftUI

struct RegistrationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var firebaseManager: FirebaseManager
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPasswordMismatch = false
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var animateFields = false
    @State private var isSuccessful = false
    
    var body: some View {
        ZStack {
            // Background
            Color.dynamic.edgesIgnoringSafeArea(.all)
            
            // Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 16) {
                        // Logo/Icon
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 80))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .purple]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .scaleEffect(animateFields ? 1 : 0.5)
                            .opacity(animateFields ? 1 : 0)
                        
                        // Title
                        Text("Create Account")
                            .font(.title)
                            .fontWeight(.bold)
                            .opacity(animateFields ? 1 : 0)
                            .offset(y: animateFields ? 0 : 20)
                        
                        // Subtitle
                        Text("Join our community of event enthusiasts")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .opacity(animateFields ? 1 : 0)
                            .offset(y: animateFields ? 0 : 20)
                    }
                    .padding(.top, 50)
                    
                    // Registration Form
                    VStack(spacing: 20) {
                        // Name Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Full Name")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.blue)
                                TextField("Enter your full name", text: $name)
                                    .textContentType(.name)
                                    .disabled(isLoading)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .opacity(animateFields ? 1 : 0)
                        .offset(y: animateFields ? 0 : 20)
                        
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.blue)
                                TextField("Enter your email", text: $email)
                                    .textContentType(.emailAddress)
                                    .autocapitalization(.none)
                                    .keyboardType(.emailAddress)
                                    .disabled(isLoading)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .opacity(animateFields ? 1 : 0)
                        .offset(y: animateFields ? 0 : 20)
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.blue)
                                SecureField("Create a password", text: $password)
                                    .textContentType(.newPassword)
                                    .disabled(isLoading)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .opacity(animateFields ? 1 : 0)
                        .offset(y: animateFields ? 0 : 20)
                        
                        // Confirm Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.blue)
                                SecureField("Confirm your password", text: $confirmPassword)
                                    .textContentType(.newPassword)
                                    .disabled(isLoading)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .opacity(animateFields ? 1 : 0)
                        .offset(y: animateFields ? 0 : 20)
                        
                        if showPasswordMismatch {
                            Text("Passwords do not match")
                                .foregroundColor(.red)
                                .font(.caption)
                                .opacity(animateFields ? 1 : 0)
                                .offset(y: animateFields ? 0 : 20)
                        }
                        
                        // Register Button
                        Button(action: register) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }
                                Text(isLoading ? "Creating Account..." : "Create Account")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .purple]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .disabled(isLoading)
                        .opacity(animateFields ? 1 : 0)
                        .offset(y: animateFields ? 0 : 20)
                        
                        // Sign In Link
                        HStack {
                            Text("Already have an account?")
                                .foregroundColor(.gray)
                            Button {
                                dismiss()
                            } label: {
                                Text("Sign In")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }
                        }
                        .font(.subheadline)
                        .opacity(animateFields ? 1 : 0)
                        .offset(y: animateFields ? 0 : 20)
                    }
                    .padding(.horizontal, 30)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    animateFields = true
                }
            }
            
            // Alerts
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            
            // Success View
            if isSuccessful {
                SuccessView(message: "Account Created!")
                    .transition(.opacity)
            }
        }
        .navigationBarItems(leading: Button("Cancel") {
            dismiss()
        })
    }
    
    private func register() {
        // Validate input
        guard !name.isEmpty else {
            alertMessage = "Please enter your name"
            showAlert = true
            return
        }
        
        guard !email.isEmpty else {
            alertMessage = "Please enter your email"
            showAlert = true
            return
        }
        
        guard !password.isEmpty else {
            alertMessage = "Please enter a password"
            showAlert = true
            return
        }
        
        guard password == confirmPassword else {
            showPasswordMismatch = true
            return
        }
        
        guard password.count >= 6 else {
            alertMessage = "Password must be at least 6 characters"
            showAlert = true
            return
        }
        
        isLoading = true
        showPasswordMismatch = false
        
        firebaseManager.signUp(email: email, name: name, password: password) { success, error in
            isLoading = false
            if success {
                // Update user profile with name
                if let user = firebaseManager.currentUser {
                    let changeRequest = user.createProfileChangeRequest()
                    changeRequest.displayName = name
                    changeRequest.commitChanges { error in
                        if let error = error {
                            print("Error updating user profile: \(error)")
                        }
                    }
                }
                isSuccessful = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            } else {
                alertMessage = error ?? "An error occurred during registration"
                showAlert = true
            }
        }
    }
}

struct SuccessView: View {
    let message: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                
                Text(message)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
    }
}

struct RegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        RegistrationView()
            .environmentObject(FirebaseManager.shared)
    }
}

