import Foundation

struct Event: Identifiable, Codable {
    var id: String = UUID().uuidString
    let name: String
    let description: String
    let type: String
    let views: String
    let location: String
    let price: String
    let owner: String
    let organizerName: String
    let shareContactInfo: Bool
    let startDate: Date
    let endDate: Date
    let images: [String]
    let participants: [String]
    let maxParticipants: Int
    let isTimed: Bool
    let createdAt: Date
    let coordinates: [Double]
    var status: String = "active"
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, type, views
        case location, price, owner, startDate, endDate
        case images, participants, isTimed, createdAt
        case coordinates, status, organizerName, shareContactInfo
        case maxParticipants
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "name": name,
            "description": description,
            "type": type,
            "views": views,
            "location": location,
            "price": price,
            "owner": owner,
            "organizerName": organizerName,
            "shareContactInfo": shareContactInfo,
            "startDate": startDate,
            "endDate": endDate,
            "images": images,
            "participants": participants,
            "maxParticipants": maxParticipants,
            "isTimed": isTimed,
            "createdAt": createdAt,
            "coordinates": coordinates,
            "status": status
        ]
    }
}

// Sample events for previews
let sampleEvents = [
    Event(
        name: "Summer Music Festival-",
        description: "A day of amazing music and entertainment. Join us for the biggest summer festival of the year. Join us for a day of fun and celebration in our annual music festival right here in new york city.",
        type: "Entertainment",
        views: "0",
        location: "Central Park, New York",
        price: "Free",
        owner: "Current User",
        organizerName: "Event Productions Inc",
        shareContactInfo: true,
        startDate: Date(),
        endDate: Date().addingTimeInterval(86400),
        images: ["bg1","bg2"],
        participants: ["John", "Jane", "Mike", "Sarah"],
        maxParticipants: 100,
        isTimed: true,
        createdAt: Date(),
        coordinates: []
    ),
    Event(
        name: "Tech Innovation Summit",
        description: "Join industry leaders and innovators for a two-day summit exploring the latest in AI, blockchain, and emerging technologies. Network with professionals and gain insights into future tech trends.",
        type: "Technology",
        views: "156",
        location: "Silicon Valley Convention Center",
        price: "$299",
        owner: "TechCorp Events",
        organizerName: "TechCorp Events",
        shareContactInfo: false,
        startDate: Date().addingTimeInterval(604800), // One week from now
        endDate: Date().addingTimeInterval(604800 + 172800), // Two days duration
        images: ["bg3","bg4"],
        participants: ["Alex", "Emma", "David", "Lisa", "Tom"],
        maxParticipants: 200,
        isTimed: true,
        createdAt: Date().addingTimeInterval(-86400),
        coordinates: []
    ),
    Event(
        name: "Wellness Retreat",
        description: "Escape to a peaceful sanctuary for a weekend of mindfulness, yoga, and holistic healing. Expert-led sessions on meditation, nutrition, and personal growth.",
        type: "Health",
        views: "89",
        location: "Mountain View Resort, Colorado",
        price: "$499",
        owner: "Mindful Living Co",
        organizerName: "Mindful Living Co",
        shareContactInfo: true,
        startDate: Date().addingTimeInterval(1209600), // Two weeks from now
        endDate: Date().addingTimeInterval(1209600 + 172800),
        images: ["bg5","bg1"],
        participants: ["Sophie", "James", "Maria", "Robert"],
        maxParticipants: 50,
        isTimed: true,
        createdAt: Date().addingTimeInterval(-172800),
        coordinates: []
    ),
    Event(
        name: "Food & Wine Festival",
        description: "Savor exquisite cuisines and premium wines from around the world. Meet celebrity chefs, enjoy cooking demonstrations, and experience gourmet food pairings.",
        type: "Culinary",
        views: "234",
        location: "Napa Valley, California",
        price: "$150",
        owner: "Gourmet Events International",
        organizerName: "Gourmet Events International",
        shareContactInfo: true,
        startDate: Date().addingTimeInterval(1814400), // Three weeks from now
        endDate: Date().addingTimeInterval(1814400 + 172800),
        images: ["bg2","bg4"],
        participants: ["Gordon", "Julia", "Pierre", "Isabella", "Marco", "Chen"],
        maxParticipants: 300,
        isTimed: true,
        createdAt: Date().addingTimeInterval(-259200),
        coordinates: []
    ),
    Event(
        name: "Art Gallery Opening",
        description: "Be among the first to experience this stunning exhibition of contemporary art. Features works from emerging artists and established masters. Wine and hors d'oeuvres served.",
        type: "Art",
        views: "67",
        location: "Modern Art Museum, Chicago",
        price: "$75",
        owner: "Chicago Arts Foundation",
        organizerName: "Chicago Arts Foundation",
        shareContactInfo: false,
        startDate: Date().addingTimeInterval(432000), // Five days from now
        endDate: Date().addingTimeInterval(432000 + 14400), // 4-hour event
        images: ["bg3","bg5"],
        participants: ["Vincent", "Frida", "Pablo", "Georgia"],
        maxParticipants: 150,
        isTimed: true,
        createdAt: Date().addingTimeInterval(-432000),
        coordinates: []
    ),
    Event(
        name: "Startup Networking Night",
        description: "Connect with fellow entrepreneurs, investors, and industry experts. Perfect opportunity for pitching ideas, finding co-founders, or securing investments.",
        type: "Business",
        views: "178",
        location: "Innovation Hub, Boston",
        price: "$50",
        owner: "Startup Boston",
        organizerName: "Startup Boston",
        shareContactInfo: true,
        startDate: Date().addingTimeInterval(345600), // Four days from now
        endDate: Date().addingTimeInterval(345600 + 10800), // 3-hour event
        images: ["bg4","bg1"],
        participants: ["Steve", "Mark", "Elon", "Sheryl", "Jeff"],
        maxParticipants: 100,
        isTimed: true,
        createdAt: Date().addingTimeInterval(-518400),
        coordinates: []
    )
]

//// Sample event for previews
//let sampleEvent = Event(
//    name: "Summer Music Festival",
//    description: "A day of amazing music and entertainment. Join us for the biggest summer festival of the year. Join us for a day of fun and celebration in our annual music festival right here in new york city.",
//    type: "Entertainment",
//    views: "0",
//    location: "Central Park, New York",
//    price: "Free",
//    owner: "Current User",
//    startDate: Date(),
//    endDate: Date().addingTimeInterval(86400),
//    images: ["bg1","bg2"],
//    participants: ["John", "Jane", "Mike", "Sarah"],
//    isTimed: true,
//    createdAt: Date(),
//    coordinates: []
//) 

