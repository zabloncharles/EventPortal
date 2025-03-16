//
//  EventAppPortalApp.swift
//  EventAppPortal
//
//  Created by Zablon Charles on 3/3/25.
//

import SwiftUI
import Firebase

@main
struct EventAppPortalApp: App {
    @EnvironmentObject private var firebaseManager: FirebaseManager
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(FirebaseManager.shared)
        }
    }
}


