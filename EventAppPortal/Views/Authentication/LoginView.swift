import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @EnvironmentObject private var firebaseManager: FirebaseManager
    @State private var isShowingRegistration = false
    @State private var showAlert = false
    @State private var showForgotPassword = false
    @State var email = "John@gmail.com"
    @State var password = "123john"
    @State var isFocused = false
    @State private var alertMessage = "Something went wrong."
    @State var isLoading = false
    @State var isSuccessful = false
    @State var isPressed = false
    @State var viewState = CGSize.zero
    
    
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
//            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                self.email = ""
//                self.password = ""
//            }
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
            Color.clear.edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    self.hideKeyboard()
                }
            
            ZStack(alignment: .top) {
                Color.clear
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                
                    .onTapGesture {
                        self.hideKeyboard()
                    }
                    .edgesIgnoringSafeArea(.bottom)
                
                CoverView(animateLoading: isLoading)
                
                VStack {
                    HStack {
                        Image(systemName: "person.crop.circle.fill")
                            .foregroundColor(Color.invert)
                            .frame(width: 44, height: 44)
                            .background(Color.dynamic)
                            .clipShape(RoundedRectangle(cornerRadius: 60, style: .continuous))
                            .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 5)
                            .padding(.leading)
                        
                        TextField("Your Email".uppercased(), text: $email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .font(.subheadline)
                            .padding(.leading)
                            .frame(height: 44)
                            .onTapGesture {
                                self.isFocused = true
                            }
                    }
                    
                    Divider().padding(.leading, 80)
                    
                    
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(Color.invert)
                            .frame(width: 44, height: 44)
                            .background(Color.dynamic)
                            .clipShape(RoundedRectangle(cornerRadius: 60, style: .continuous))
                            .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 5)
                            .padding(.leading)
                        
                        SecureField("Password".uppercased(), text: $password)
                            .keyboardType(.default)
                            .textContentType(.password)
                            .font(.subheadline)
                            .padding(.leading)
                            .frame(height: 44)
                            .onTapGesture {
                                self.isFocused = true
                            }
                    }
                    
                    Button {
                        //show registration view
                        isShowingRegistration = true
                    } label: {
                        Text("Don't have an account? Sign Up")
                            .foregroundColor(.blue)
                            .padding(.top,20)
                    }
                    
                    
                    
                }
                
                
                .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 20)
                .padding(.horizontal)
                .offset(y: 510)
                
                
                
                
                
                HStack {
                    Button {
                        //show forgot password view
                        showForgotPassword = true
                    } label: {
                        Text("Forgot password?")
                            .font(.subheadline)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        self.login()
                    }) {
                        Text(isLoading ? "Loggin In.." : "Log in")
                            .foregroundColor(.white)
                    }
                    .padding(12)
                    .padding(.horizontal, 30)
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: Color(#colorLiteral(red: 0, green: 0.7529411765, blue: 1, alpha: 1)).opacity(0.3), radius: 20, x: 0, y: 20)
                    .alert(isPresented: $showAlert) {
                        Alert(title: Text("Error"), message: Text(self.alertMessage), dismissButton: .default(Text("OK")))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding()
            }
            .offset(y: isFocused ? -300 : 0)
            .animation(isFocused ? .easeInOut : nil, value: isFocused)
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
            .onTapGesture {
                self.isFocused = false
                self.hideKeyboard()
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
