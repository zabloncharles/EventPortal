//
//  ContentView.swift
//  EventAppPortal
//
//  Created by Zablon Charles on 3/14/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var firebaseManager: FirebaseManager
    
    var body: some View {
        Group {
            if firebaseManager.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
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
