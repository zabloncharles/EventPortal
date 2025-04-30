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
    @State var showLogo = true
    
    var body: some View {
        ZStack {
           
                // Loading screen
             
                    Color.dynamic.edgesIgnoringSafeArea(.all)
                    
                    // Main content
                    Group {
                        if isLoggedIn,
                           let currentUser = firebaseManager.currentUser,
                           !currentUser.uid.isEmpty,
                           let email = currentUser.email,
                           !email.isEmpty {
                            MainTabView(showLogo: $showLogo)
                                
                        } else {
                            LoginView()
                                
                        }
                    }
                    .transition(.opacity)
                    //Show the app logo
            if showLogo {
                LogoLoadingView()
            }
                   
                  
            
        }
        .animation(.easeInOut, value: firebaseManager.currentUser != nil)
        .onAppear {
            // Check if user is already logged in
            if let user = Auth.auth().currentUser {
                userID = user.uid
                isLoggedIn = true
            }
            
            
//            DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
//                withAnimation {
//                    showLogo = false
//                }
//            }
        }
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
