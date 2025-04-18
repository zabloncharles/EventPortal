import Foundation
import CoreLocation
import FirebaseFirestore
import PhotosUI

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

enum CreationType {
    case none
    case event
    case group
}


// Sample groups for previews
let sampleGroups = [
    EventGroup(
        id: "1",
        name: "Tech Enthusiasts NYC",
        description: "A community of tech lovers in New York City. We meet weekly to discuss the latest in technology, share knowledge, and network with fellow tech enthusiasts.",
        shortDescription: "Weekly tech meetups and discussions in NYC",
        memberCount: 156,
        imageURL: "desktopcomputer",
        location: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
        createdAt: Date(),
        createdBy: "user1",
        isPrivate: false,
        category: "Technology",
        tags: ["Programming", "AI", "Networking"],
        pendingRequests: [],
        members: ["user1", "user2", "user3"],
        admins: ["user1"]
    ),
    EventGroup(
        id: "2",
        name: "Foodies United",
        description: "Join us for culinary adventures! We explore new restaurants, share recipes, and host cooking workshops. From street food to fine dining, we celebrate all things food.",
        shortDescription: "Exploring culinary delights together",
        memberCount: 89,
        imageURL: "leaf.fill",
        location: CLLocationCoordinate2D(latitude: 40.7589, longitude: -73.9851),
        createdAt: Date().addingTimeInterval(-86400),
        createdBy: "user2",
        isPrivate: false,
        category: "Lifestyle",
        tags: ["Cooking", "Restaurants", "Recipes"],
        pendingRequests: [],
        members: ["user2", "user4", "user5"],
        admins: ["user2"]
    ),
    EventGroup(
        id: "3",
        name: "Art & Design Collective",
        description: "A vibrant community of artists and designers. We organize exhibitions, workshops, and collaborative projects. All skill levels welcome!",
        shortDescription: "Creative community for artists and designers",
        memberCount: 234,
        imageURL: "paintbrush.fill",
        location: CLLocationCoordinate2D(latitude: 40.7829, longitude: -73.9654),
        createdAt: Date().addingTimeInterval(-172800),
        createdBy: "user3",
        isPrivate: false,
        category: "Art & Culture",
        tags: ["Design", "Exhibition", "Workshop"],
        pendingRequests: [],
        members: ["user3", "user6", "user7", "user8"],
        admins: ["user3"]
    ),
    EventGroup(
        id: "4",
        name: "Fitness Warriors",
        description: "Get fit together! We organize group workouts, running sessions, and fitness challenges. Motivation and support guaranteed!",
        shortDescription: "Group workouts and fitness challenges",
        memberCount: 178,
        imageURL: "figure.dance",
        location: CLLocationCoordinate2D(latitude: 40.7549, longitude: -73.9840),
        createdAt: Date().addingTimeInterval(-259200),
        createdBy: "user4",
        isPrivate: false,
        category: "Sports",
        tags: ["Fitness", "Workout", "Running"],
        pendingRequests: [],
        members: ["user4", "user9", "user10"],
        admins: ["user4"]
    ),
    EventGroup(
        id: "5",
        name: "Music Lovers Club",
        description: "Share your passion for music! We organize concerts, jam sessions, and music appreciation meetups. All genres welcome!",
        shortDescription: "Music appreciation and jam sessions",
        memberCount: 145,
        imageURL: "music.note.list",
        location: CLLocationCoordinate2D(latitude: 40.7580, longitude: -73.9855),
        createdAt: Date().addingTimeInterval(-345600),
        createdBy: "user5",
        isPrivate: false,
        category: "Entertainment",
        tags: ["Concerts", "Jam Sessions", "Music"],
        pendingRequests: [],
        members: ["user5", "user11", "user12"],
        admins: ["user5"]
    ),
    EventGroup(
        id: "6",
        name: "Environmental Action Group",
        description: "Join us in making a difference for our planet! We organize cleanups, tree plantings, and educational events about sustainability.",
        shortDescription: "Making a difference for our planet",
        memberCount: 112,
        imageURL: "leaf.arrow.triangle.circlepath",
        location: CLLocationCoordinate2D(latitude: 40.7500, longitude: -73.9900),
        createdAt: Date().addingTimeInterval(-432000),
        createdBy: "user6",
        isPrivate: false,
        category: "Environmental",
        tags: ["Sustainability", "Cleanup", "Education"],
        pendingRequests: [],
        members: ["user6", "user13", "user14"],
        admins: ["user6"]
    ),
    EventGroup(
        id: "7",
        name: "Book Lovers Society",
        description: "A community for book enthusiasts! We discuss literature, host author meetups, and organize book swaps.",
        shortDescription: "For book enthusiasts and readers",
        memberCount: 98,
        imageURL: "book.fill",
        location: CLLocationCoordinate2D(latitude: 40.7600, longitude: -73.9800),
        createdAt: Date().addingTimeInterval(-518400),
        createdBy: "user7",
        isPrivate: false,
        category: "Literature",
        tags: ["Books", "Reading", "Authors"],
        pendingRequests: [],
        members: ["user7", "user15", "user16"],
        admins: ["user7"]
    ),
    EventGroup(
        id: "8",
        name: "Corporate Networking",
        description: "Connect with professionals from various industries. Perfect for career growth, mentorship, and business opportunities.",
        shortDescription: "Professional networking and career growth",
        memberCount: 267,
        imageURL: "building.2.fill",
        location: CLLocationCoordinate2D(latitude: 40.7450, longitude: -73.9950),
        createdAt: Date().addingTimeInterval(-604800),
        createdBy: "user8",
        isPrivate: false,
        category: "Corporate",
        tags: ["Networking", "Career", "Business"],
        pendingRequests: [],
        members: ["user8", "user17", "user18", "user19"],
        admins: ["user8"]
    ),
    EventGroup(
        id: "9",
        name: "Health & Wellness Community",
        description: "Focus on mental and physical well-being. We offer meditation sessions, wellness workshops, and support groups.",
        shortDescription: "Mental and physical well-being support",
        memberCount: 143,
        imageURL: "heart.fill",
        location: CLLocationCoordinate2D(latitude: 40.7700, longitude: -73.9750),
        createdAt: Date().addingTimeInterval(-691200),
        createdBy: "user9",
        isPrivate: false,
        category: "Health & Wellness",
        tags: ["Meditation", "Wellness", "Support"],
        pendingRequests: [],
        members: ["user9", "user20", "user21"],
        admins: ["user9"]
    ),
    EventGroup(
        id: "10",
        name: "Other Interests Group",
        description: "A diverse group for various interests that don't fit into other categories. Share your unique hobbies and discover new ones!",
        shortDescription: "For diverse and unique interests",
        memberCount: 76,
        imageURL: "calendar",
        location: CLLocationCoordinate2D(latitude: 40.7550, longitude: -73.9700),
        createdAt: Date().addingTimeInterval(-777600),
        createdBy: "user10",
        isPrivate: false,
        category: "Other",
        tags: ["Diverse", "Unique", "Hobbies"],
        pendingRequests: [],
        members: ["user10", "user22", "user23"],
        admins: ["user10"]
    )
]
