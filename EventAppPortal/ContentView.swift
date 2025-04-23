//
//  ContentView.swift
//  EventAppPortal
//
//  Created by Zablon Charles on 3/14/25.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject private var firebaseManager: FirebaseManager
    @AppStorage("userID") private var userID: String = ""
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @State var appeared = true
    @State var hideLoadingView = false
    
    var body: some View {
        ZStack {
            if !hideLoadingView {
                // Loading screen
                ZStack {
                    Color.dynamic.edgesIgnoringSafeArea(.all)
                    LogoLoadingView()
                        .onAppear {
                            // Check if user is already logged in
                            if let user = Auth.auth().currentUser {
                                userID = user.uid
                                isLoggedIn = true
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                withAnimation(.spring()) {
                                    appeared = false
                                }
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
                                withAnimation {
                                    hideLoadingView = true
                                }
                            }
                        }
                }
                .offset(y: !appeared ? UIScreen.main.bounds.height * 1.3 : 0)
            } else {
                // Main content
                Group {
                    if isLoggedIn,
                       let currentUser = firebaseManager.currentUser,
                       !currentUser.uid.isEmpty,
                       let email = currentUser.email,
                       !email.isEmpty {
                        MainTabView()
                            .scaleEffect(!appeared ? 1 : 0.9)
                    } else {
                        LoginView()
                            .scaleEffect(!appeared ? 1 : 0.9)
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: firebaseManager.currentUser != nil)
        .onChange(of: firebaseManager.currentUser) { newUser in
            if let user = newUser {
                userID = user.uid
                isLoggedIn = true
            } else {
                userID = ""
                isLoggedIn = false
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(FirebaseManager.shared)
            .preferredColorScheme(.dark)
    }
}
