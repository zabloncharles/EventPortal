import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var firebaseManager: FirebaseManager
    @State private var isShowingRegistration = false
    @State private var showAlert = false
    @State private var showForgotPassword = false
    @State var email = ""
    @State var password = ""
    @State var isFocused = false
    @State private var alertMessage = "Something went wrong."
    @State var isLoading = false
    @State var isSuccessful = false
    @State private var animateFields = false
    @State private var animateGradient = false
    
    private func login() {
        self.hideKeyboard()
        self.isFocused = false
        self.isLoading = true
        
        guard !email.isEmpty && !password.isEmpty else {
            alertMessage = "Please fill in all fields"
            showAlert = true
            self.isLoading = false
            return
        }
        
        isLoading = true
        firebaseManager.signIn(email: email, password: password) { success, error in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                isLoading = false
            }
            self.isSuccessful = true
            if !success {
                alertMessage = error ?? "An error occurred"
                showAlert = true
            }
        }
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
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
                        Image("transparent-icon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height:150)
                           
                            .scaleEffect(animateFields ? 1 : 0.5)
                            .opacity(animateFields ? 1 : 0)
                        
                        // Title
                        Text("Welcome Back")
                            .font(.title)
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .purple]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .fontWeight(.bold)
                            .opacity(animateFields ? 1 : 0)
                            .offset(y: animateFields ? 0 : 20)
                        
                        // Subtitle
                        Text("Sign in to continue")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .opacity(animateFields ? 1 : 0)
                            .offset(y: animateFields ? 0 : 20)
                    }
                    .padding(.top, 50)
                    
                    // Login Form
                    VStack(spacing: 20) {
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
                                SecureField("Enter your password", text: $password)
                                    .textContentType(.password)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .opacity(animateFields ? 1 : 0)
                        .offset(y: animateFields ? 0 : 20)
                        
                        // Forgot Password
                        Button {
                            showForgotPassword = true
                        } label: {
                            Text("Forgot Password?")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .opacity(animateFields ? 1 : 0)
                        .offset(y: animateFields ? 0 : 20)
                        
                        // Login Button
                        Button(action: login) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }
                                Text(isLoading ? "Signing in..." : "Sign In")
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
                        
                        // Sign Up Link
                        HStack {
                            Text("Don't have an account?")
                                .foregroundColor(.gray)
                            Button {
                                isShowingRegistration = true
                            } label: {
                                Text("Sign Up")
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
                .padding(.horizontal)
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
            .alert("Reset Password", isPresented: $showForgotPassword) {
                TextField("Enter your email", text: $email)
                Button("Cancel", role: .cancel) { }
                Button("Reset") {
                    resetPassword()
                }
            } message: {
                Text("Enter your email address and we'll send you a link to reset your password.")
            }
            .sheet(isPresented: $isShowingRegistration) {
                RegistrationView()
            }
            
            // Success View
            if isSuccessful {
                SuccessView(message: "Welcome Back!")
                    .transition(.opacity)
            }
        }
        .navigationBarItems(leading: Button("Cancel") {
            dismiss()
        })
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
            .environmentObject(FirebaseManager.shared)
    }
}

// Keep your existing CoverView implementation as is
struct CoverView: View {
    @State var show = false
    @State var viewState = CGSize.zero
    @State var isDragging = false
    @State private var textOffset: CGFloat = 100
    @State private var rotation: Double = 0
    var animateLoading = false
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [Color.red, Color.white]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .offset(y: -textOffset) // Apply offset to text
                    .mask (Text("Bring moments to life.\n— your way.")
                        .font(.system(size: geometry.size.width / 10, weight: .bold))
                           
                           
                        .onAppear {
                            withAnimation(.easeOut(duration: 2)) {
                                textOffset = -geometry.size.height / 2 + 50 // Final position
                            }
                        })
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, .red, Color.purple]),
                        startPoint: .leading,
                        endPoint: .bottomTrailing
                    )
                    .offset(y: textOffset) // Apply offset to text
                    .mask (Text("Bring moments to life.\n— your way.")
                        .font(.system(size: geometry.size.width / 10, weight: .bold))
                        
                            
                        .onAppear {
                            withAnimation(.easeOut(duration: 2)) {
                                textOffset = -geometry.size.height / 2 + 50 // Final position
                            }
                        })
                    
                }
            }
            .frame(maxWidth: 375, maxHeight: 100)
            .padding(.horizontal, 16)
            .offset(x: viewState.width/15, y: viewState.height/15)
            
            Text("Discover, create, and manage events effortlessly with our app.")
                .font(.subheadline)
                .foregroundColor(.primary)
                .frame(width: 250)
                .offset(x: viewState.width/20, y: viewState.height/20)
            
            Spacer()
        }
        .multilineTextAlignment(.center)
        .padding(.top, 100)
        .frame(height: 477)
        .frame(maxWidth: .infinity)
        
            .background(
                ZStack {
                    Image("bg6")
                        .resizable()
                        .scaledToFill()
                    .offset(x: viewState.width/25, y: viewState.height/25)
                    
                    // Rotating circle stroke around the image
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.clear, Color.white, Color.purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 5
                        )
                        .frame(width: 300, height: 300) // Adjust size to fit your image
                        .rotationEffect(.degrees(rotation)) // Rotate the stroke
                        .animation(
                            Animation.linear.speed(0.2).repeatForever(autoreverses: false), value: rotation // Repeat indefinitely without reversing
                        )
                        .onChange(of: animateLoading, perform: { load in
                            // Rotate 6 times when the view appears
                            rotation = 360 * 1
                        })
                }
                , alignment: .center
        )
            
            .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
            .scaleEffect(isDragging ? 0.9 : 1)
            .animation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.8), value: isDragging)
            .rotation3DEffect(Angle(degrees: 5), axis: (x: viewState.width, y: viewState.height, z: 0))
            .padding(10).gesture(
                DragGesture().onChanged { value in
                    self.viewState = value.translation
                    self.isDragging = true
                }
                .onEnded { value in
                    self.viewState = .zero
                    self.isDragging = false
                }
        )
    }
}
