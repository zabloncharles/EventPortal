//
//  EventAppPortalApp.swift
//  EventAppPortal
//
//  Created by Zablon Charles on 3/3/25.
//

import SwiftUI

@main
struct EventAppPortalApp: App {
    @AppStorage("isAuthenticated") var isAuthenticated = false
  
    
    var body: some Scene {
        WindowGroup {
            if isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
    }
}
