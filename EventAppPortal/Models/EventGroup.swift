import Foundation
import CoreLocation
import FirebaseFirestore

struct EventGroup: Identifiable, Equatable {
    var id: String
    var name: String
    var description: String
    var shortDescription: String
    var memberCount: Int
    var imageURL: String
    var location: CLLocationCoordinate2D
    var createdAt: Date
    var createdBy: String
    var isPrivate: Bool
    var category: String
    var tags: [String]
    var pendingRequests: [String] // User IDs of pending join requests
    var members: [String] // User IDs of current members
    var admins: [String] // User IDs of group admins
    
    static func == (lhs: EventGroup, rhs: EventGroup) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Convert Firestore document to EventGroup model
    static func fromFirestore(_ document: DocumentSnapshot) -> EventGroup? {
        guard let data = document.data() else { return nil }
        
        let id = document.documentID
        let name = data["name"] as? String ?? ""
        let description = data["description"] as? String ?? ""
        let shortDescription = data["shortDescription"] as? String ?? ""
        let memberCount = data["memberCount"] as? Int ?? 0
        let imageURL = data["imageURL"] as? String ?? ""
        
        // Location
        let latitude = data["latitude"] as? Double ?? 0
        let longitude = data["longitude"] as? Double ?? 0
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        // Dates
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        
        // Other properties
        let createdBy = data["createdBy"] as? String ?? ""
        let isPrivate = data["isPrivate"] as? Bool ?? false
        let category = data["category"] as? String ?? ""
        let tags = data["tags"] as? [String] ?? []
        let pendingRequests = data["pendingRequests"] as? [String] ?? []
        let members = data["members"] as? [String] ?? []
        let admins = data["admins"] as? [String] ?? []
        
        return EventGroup(
            id: id,
            name: name,
            description: description,
            shortDescription: shortDescription,
            memberCount: memberCount,
            imageURL: imageURL,
            location: location,
            createdAt: createdAt,
            createdBy: createdBy,
            isPrivate: isPrivate,
            category: category,
            tags: tags,
            pendingRequests: pendingRequests,
            members: members,
            admins: admins
        )
    }
    
    // Convert EventGroup model to Firestore data
    func toFirestore() -> [String: Any] {
        return [
            "name": name,
            "description": description,
            "shortDescription": shortDescription,
            "memberCount": memberCount,
            "imageURL": imageURL,
            "latitude": location.latitude,
            "longitude": location.longitude,
            "createdAt": Timestamp(date: createdAt),
            "createdBy": createdBy,
            "isPrivate": isPrivate,
            "category": category,
            "tags": tags,
            "pendingRequests": pendingRequests,
            "members": members,
            "admins": admins
        ]
    }
} 