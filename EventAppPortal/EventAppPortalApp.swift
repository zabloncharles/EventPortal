//
//  EventAppPortalApp.swift
//  EventAppPortal
//
//  Created by Zablon Charles on 3/3/25.
//

import SwiftUI
import Firebase
import Kingfisher

@main
struct EventAppPortalApp: App {
    @EnvironmentObject private var firebaseManager: FirebaseManager
    
    init() {
        FirebaseApp.configure()
        
        // Configure Kingfisher
        let cache = ImageCache(name: "eventportal.cache")
        cache.memoryStorage.config.totalCostLimit = 300 * 1024 * 1024 // 300MB memory cache
        cache.diskStorage.config.sizeLimit = 1000 * 1024 * 1024 // 1GB disk cache
        
        KingfisherManager.shared.defaultOptions = [
            .cacheOriginalImage,
            .scaleFactor(UIScreen.main.scale),
            .backgroundDecode,
            .keepCurrentImageWhileLoading
        ]
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(FirebaseManager.shared)
        }
    }
}


