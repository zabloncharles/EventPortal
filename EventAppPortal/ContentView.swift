//
//  ContentView.swift
//  EventAppPortal
//
//  Created by Zablon Charles on 3/14/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var firebaseManager: FirebaseManager
    @AppStorage("userID") private var userID: String = ""
    @State var appeared = true
    @State var hideLoadingView = false
    var body: some View {
        ZStack {
            if firebaseManager.isAuthenticated {
               MainTabView()
                
                    .scaleEffect(!appeared ? 1 : 0.9)
            } else {
                LoginView()
                    .scaleEffect(!appeared ? 1 : 0.9)
            }
            
            //Loading screen of the logo
            if !hideLoadingView {
                ZStack {
                    Color.dynamic.edgesIgnoringSafeArea(.all)
                    LogoLoadingView()
                        .onAppear{
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
                        
                }.offset(y: !appeared ? UIScreen.main.bounds.height * 1.3 : 0)
            }
        }
        .animation(.easeInOut, value: firebaseManager.isAuthenticated)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(FirebaseManager.shared)
    }
}
