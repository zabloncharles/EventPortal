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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                Text("Create Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 30)
                
                // Registration Form
                VStack(spacing: 15) {
                    TextField("Full Name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.name)
                        .disabled(isLoading)
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .disabled(isLoading)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.newPassword)
                        .disabled(isLoading)
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.newPassword)
                        .disabled(isLoading)
                }
                .padding(.horizontal)
                
                if showPasswordMismatch {
                    Text("Passwords do not match")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                // Register Button
                Button(action: {
                    register()
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text("Create Account")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isLoading ? Color.gray : Color.blue)
                    .cornerRadius(10)
                }
                .disabled(isLoading)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            })
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .appBackground()
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
                dismiss()
            } else {
                alertMessage = error ?? "An error occurred during registration"
                showAlert = true
            }
        }
    }
}

struct RegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        RegistrationView()
    }
}

