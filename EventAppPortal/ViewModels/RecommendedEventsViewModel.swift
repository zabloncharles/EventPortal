import Foundation
import SwiftUI
import FirebaseFirestore

@MainActor
class RecommendedEventsViewModel: ObservableObject {
    @Published var recommendedEvents: [Event] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let recommendationService = EventRecommendationService()
    
    func loadRecommendedEvents() {
        self.isLoading = true
        self.error = nil
        
        Task { [weak self] in
            guard let self = self else { return }
            do {
                try await self.withTimeout(seconds: 10) {
                    await self.getRecommendations()
                }
            } catch {
                self.error = error.localizedDescription
            }
            self.isLoading = false
        }
    }
    
    private func getRecommendations() async {
        await withCheckedContinuation { [weak self] continuation in
            self?.recommendationService.getRecommendedEvents { events, error in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                if let error = error {
                    self.error = error.localizedDescription
                } else if let events = events {
                    self.recommendedEvents = events
                }
                continuation.resume()
            }
        }
    }
    
    func recordEventInteraction(_ event: Event, type: EventInteractionType) {
        self.recommendationService.updateUserInteraction(eventId: event.id, interactionType: type)
    }
    
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Operation timed out"])
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
} 