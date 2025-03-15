import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var firebaseManager: FirebaseManager
    @State private var email = ""
    @State private var password = ""
    @State private var isShowingRegistration = false
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showForgotPassword = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Logo and Welcome Text
                VStack(spacing: 15) {
                    Image(systemName: "calendar.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.blue)
                    
                    Text("Welcome Back!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Sign in to continue")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 50)
                
                // Login Form
                VStack(spacing: 15) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .disabled(isLoading)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.password)
                        .disabled(isLoading)
                        
                    // Forgot Password Button
                    HStack {
                        Spacer()
                        Button("Forgot Password?") {
                            showForgotPassword = true
                        }
                        .font(.footnote)
                        .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                
                // Login Button
                Button(action: {
                    login()
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text("Sign In")
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
                
                // Register Link
                Button(action: {
                    isShowingRegistration = true
                }) {
                    Text("Don't have an account? Sign Up")
                        .foregroundColor(.blue)
                }
                
                Spacer()
            }
            .padding()
            .sheet(isPresented: $isShowingRegistration) {
                RegistrationView()
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert("Reset Password", isPresented: $showForgotPassword) {
                TextField("Enter your email", text: $email)
                Button("Cancel", role: .cancel) { }
                Button("Reset") {
                    resetPassword()
                }
            } message: {
                Text("Enter your email address and we'll send you a link to reset your password.")
            }
        }
        .appBackground()
    }
    
    private func login() {
        guard !email.isEmpty && !password.isEmpty else {
            alertMessage = "Please fill in all fields"
            showAlert = true
            return
        }
        
        isLoading = true
        firebaseManager.signIn(email: email, password: password) { success, error in
            isLoading = false
            if !success {
                alertMessage = error ?? "An error occurred"
                showAlert = true
            }
        }
    }
    
    private func resetPassword() {
        guard !email.isEmpty else {
            alertMessage = "Please enter your email address"
            showAlert = true
            return
        }
        
        firebaseManager.resetPassword(email: email) { success, error in
            if success {
                alertMessage = "Password reset email sent. Please check your inbox."
            } else {
                alertMessage = error ?? "Failed to send reset email"
            }
            showAlert = true
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
} 