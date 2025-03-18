import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @AppStorage("signedIn") var signedIn: Bool = false
    @State var email = ""
    @State var password = ""
    @State var isFocused = false
    @State var showAlert = false
    @State var alertMessage = "Something went wrong."
    @State var isLoading = false
    @State var isSuccessful = false
    @State var isPressed = false
    @State var viewState = CGSize.zero
    
    func login() {
        self.hideKeyboard()
        self.isFocused = false
        self.isLoading = true
        
        Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
            DispatchQueue.main.async {
                if let error = error {
                    self.alertMessage = error.localizedDescription
                    self.showAlert = true
                    self.isLoading = false
                } else {
                    self.isSuccessful = true
                    UserDefaults.standard.set(true, forKey: "isLogged")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.signedIn = true
                        self.isLoading = false
                        self.email = ""
                        self.password = ""
                        self.isSuccessful = false
                    }
                }
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
                    .blurredBackground()
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
                            .font(.subheadline)
                            .padding(.leading)
                            .frame(height: 44)
                            .onTapGesture {
                                self.isFocused = true
                            }
                    }
                }
                .frame(height: 136)
                .frame(maxWidth: 712)
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 20)
                .padding(.horizontal)
                .offset(y: 490)
                
                HStack {
                    Text("Forgot password?")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Button(action: {
                        self.login()
                    }) {
                        Text(isLoading ? "Loading.." : "Log in")
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
            .onTapGesture {
                self.isFocused = false
                self.hideKeyboard()
            }
            
            if isLoading {
                LoadingView()
            }
            
            if isSuccessful {
                SuccessView()
            }
        }
    }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .edgesIgnoringSafeArea(.all)
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(2)
        }
    }
}

struct SuccessView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .edgesIgnoringSafeArea(.all)
            
            Image(systemName: "checkmark")
                .foregroundColor(.white)
                .font(.system(size: 98, weight: .bold))
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}

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
                    .offset(y: -textOffset)
                    .mask(
                        Text("Bring moments to life.\n— your way.")
                            .font(.system(size: geometry.size.width / 10, weight: .bold))
                            .onAppear {
                                withAnimation(.easeOut(duration: 2)) {
                                    textOffset = -geometry.size.height / 2 + 50
                                }
                            }
                    )
                    
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, .red, Color.purple]),
                        startPoint: .leading,
                        endPoint: .bottomTrailing
                    )
                    .offset(y: textOffset)
                    .mask(
                        Text("Bring moments to life.\n— your way.")
                            .font(.system(size: geometry.size.width / 10, weight: .bold))
                            .onAppear {
                                withAnimation(.easeOut(duration: 2)) {
                                    textOffset = -geometry.size.height / 2 + 50
                                }
                            }
                    )
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
                
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.clear, Color.white, Color.purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 5
                    )
                    .frame(width: 300, height: 300)
                    .rotationEffect(.degrees(rotation))
                    .animation(
                        Animation.linear.speed(0.2).repeatForever(autoreverses: false),
                        value: rotation
                    )
                    .onChange(of: animateLoading) { load in
                        rotation = 360 * 1
                    }
            },
            alignment: .center
        )
        .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
        .scaleEffect(isDragging ? 0.9 : 1)
        .animation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.8), value: isDragging)
        .rotation3DEffect(Angle(degrees: 5), axis: (x: viewState.width, y: viewState.height, z: 0))
        .padding(10)
        .gesture(
            DragGesture()
                .onChanged { value in
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