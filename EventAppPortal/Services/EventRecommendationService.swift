import Foundation
import FirebaseFirestore
import FirebaseAuth

class EventRecommendationService {
    private let db = Firestore.firestore()
    
    // Weights for different recommendation factors
    private struct RecommendationWeights {
        static let eventTypePreference: Double = 0.35
        static let locationProximity: Double = 0.25
        static let userInteractions: Double = 0.20
        static let eventPopularity: Double = 0.15
        static let timeRelevance: Double = 0.05
    }
    
    // Store user preferences
    private var userPreferences: [String: Any] = [:]
    
    // Cache for recently viewed events
    private var recentlyViewedEvents: Set<String> = []
    
    // Maximum number of recommendations to return
    private let maxRecommendations = 10
    
    // Get recommended events for the current user
    func getRecommendedEvents(completion: @escaping ([Event]?, Error?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"]))
            return
        }
        
        // First, fetch all events and apply recommendation algorithm
        self.fetchEvents { events in
            guard let events = events else {
                completion(nil, NSError(domain: "", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch events"]))
                return
            }
            
            // Score and sort events
            let scoredEvents = self.scoreEvents(events)
            let recommendedEvents = Array(scoredEvents.prefix(self.maxRecommendations))
            print("Fetched \(events.count) events, recommending \(recommendedEvents.count) events")
            
            completion(recommendedEvents.map { $0.event }, nil)
        }
    }
    
    // Fetch user preferences and interaction history
    private func fetchUserPreferences(userId: String, completion: @escaping () -> Void) {
        let userRef = self.db.collection("users").document(userId)
        
        userRef.getDocument { [weak self] (document, error) in
            guard let self = self,
                  let document = document,
                  document.exists,
                  let preferences = document.data() else {
                completion()
                return
            }
            
            self.userPreferences = preferences
            
            // Fetch recently viewed events
            userRef.collection("eventInteractions")
                .order(by: "lastViewed", descending: true)
                .limit(to: 20)
                .getDocuments { [weak self] (snapshot, error) in
                    guard let self = self else {
                        completion()
                        return
                    }
                    
                    if let documents = snapshot?.documents {
                        self.recentlyViewedEvents = Set(documents.compactMap { $0.documentID })
                    }
                    completion()
                }
        }
    }
    
    // Fetch all available events
    private func fetchEvents(completion: @escaping ([Event]?) -> Void) {
        self.db.collection("events")
            .whereField("status", isEqualTo: "active")  // Only fetch active events
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error fetching events: \(error)")
                    completion(nil)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No events found")
                    completion(nil)
                    return
                }
                
                let events = documents.compactMap { document -> Event? in
                    do {
                        let data = document.data()
                        let event = Event(id: document.documentID, data: data)
                        return event
                    } catch {
                        print("Error decoding event \(document.documentID): \(error)")
                        return nil
                    }
                }
                
                print("Successfully fetched \(events.count) events")
                completion(events)
            }
    }
    
    // Score events based on multiple factors
    private func scoreEvents(_ events: [Event]) -> [(event: Event, score: Double)] {
        let scoredEvents = events.map { event -> (event: Event, score: Double) in
            var score: Double = 0
            
            // 1. Event Type Preference (35%)
            if let preferredTypes = self.userPreferences["preferredEventTypes"] as? [String],
               preferredTypes.contains(event.type) {
                score += RecommendationWeights.eventTypePreference
            }
            
            // 2. Location Proximity (25%)
            if let userLocation = self.userPreferences["location"] as? GeoPoint,
               let eventLocation = event.geoLocation {
                let distance = self.calculateDistance(from: userLocation, to: eventLocation)
                let proximityScore = max(0, 1 - (distance / 50000)) // 50km as max relevant distance
                score += proximityScore * RecommendationWeights.locationProximity
            }
            
            // 3. User Interactions (20%)
            if self.recentlyViewedEvents.contains(event.id) {
                score += RecommendationWeights.userInteractions
            }
            
            // 4. Event Popularity (15%)
            let popularityScore = min(1.0, Double(event.participants.count) / 100.0)
            score += popularityScore * RecommendationWeights.eventPopularity
            
            // 5. Time Relevance (5%)
            let timeScore = self.calculateTimeRelevance(for: event.date)
            score += timeScore * RecommendationWeights.timeRelevance
            
            return (event, score)
        }
        
        return scoredEvents.sorted { $0.score > $1.score }
    }
    
    // Calculate distance between two points
    private func calculateDistance(from point1: GeoPoint, to point2: GeoPoint) -> Double {
        // Simple Haversine formula for distance calculation
        let lat1 = point1.latitude * .pi / 180
        let lon1 = point1.longitude * .pi / 180
        let lat2 = point2.latitude * .pi / 180
        let lon2 = point2.longitude * .pi / 180
        
        let dlat = lat2 - lat1
        let dlon = lon2 - lon1
        
        let a = sin(dlat/2) * sin(dlat/2) +
                cos(lat1) * cos(lat2) *
                sin(dlon/2) * sin(dlon/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        
        // Return distance in kilometers
        return 6371 * c
    }
    
    // Calculate time relevance score
    private func calculateTimeRelevance(for eventDate: Date) -> Double {
        let now = Date()
        let timeInterval = eventDate.timeIntervalSince(now)
        
        // Events happening too soon (less than 24 hours) or too far in the future (more than 30 days)
        // get lower scores
        if timeInterval < 86400 { // 24 hours in seconds
            return 0.5
        } else if timeInterval > 2592000 { // 30 days in seconds
            return 0.3
        } else {
            // Normalize score between 0.6 and 1.0 for events between 1 and 30 days away
            return 0.6 + 0.4 * (1 - (timeInterval - 86400) / (2592000 - 86400))
        }
    }
    
    // Update user preferences after interaction with an event
    func updateUserInteraction(eventId: String, interactionType: EventInteractionType) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let userRef = self.db.collection("users").document(userId)
        let interaction: [String: Any] = [
            "eventId": eventId,
            "type": interactionType.rawValue,
            "timestamp": FieldValue.serverTimestamp(),
            "lastViewed": FieldValue.serverTimestamp()
        ]
        
        userRef.collection("eventInteractions").document(eventId).setData(interaction, merge: true)
    }
}

// Enum to track different types of user interactions with events
enum EventInteractionType: String {
    case view = "view"
    case like = "like"
    case share = "share"
    case register = "register"
}

// Extension to update Event model if needed
extension Event {
    var geoLocation: GeoPoint? {
        guard coordinates.count >= 2 else { return nil }
        return GeoPoint(latitude: coordinates[0], longitude: coordinates[1])
    }
    
    var attendeeCount: Int? {
        return participants.count
    }
    
    var date: Date {
        return startDate
    }
    
    init(id: String, data: [String: Any]) {
        self.id = id
        self.name = data["name"] as? String ?? ""
        self.description = data["description"] as? String ?? ""
        self.type = data["type"] as? String ?? ""
        self.views = data["views"] as? String ?? "0"
        self.location = data["location"] as? String ?? ""
        self.price = data["price"] as? String ?? ""
        self.owner = data["owner"] as? String ?? ""
        self.organizerName = data["organizerName"] as? String ?? ""
        self.shareContactInfo = data["shareContactInfo"] as? Bool ?? false
        self.startDate = (data["startDate"] as? Timestamp)?.dateValue() ?? Date()
        self.endDate = (data["endDate"] as? Timestamp)?.dateValue() ?? Date()
        self.images = data["images"] as? [String] ?? []
        self.participants = data["participants"] as? [String] ?? []
        self.maxParticipants = data["maxParticipants"] as? Int ?? 100
        self.isTimed = data["isTimed"] as? Bool ?? false
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        self.coordinates = data["coordinates"] as? [Double] ?? []
        self.status = data["status"] as? String ?? "active"
    }
} 