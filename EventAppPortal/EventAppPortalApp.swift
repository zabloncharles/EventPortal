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
    
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
            
        }
    }
}


