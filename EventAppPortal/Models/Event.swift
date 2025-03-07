import Foundation

struct Event: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let type: String
    let views: String
    let location: String
    let price: String
    let owner: String
    let startDate: Date?
    let endDate: Date?
    let images: [String]
    let participants: [String]
    let isTimed: Bool
    let createdAt: Date
    let coordinates: [String]
}

// Sample event for previews
let sampleEvent = Event(
    name: "Summer Music Festival",
    description: "A day of amazing music and entertainment. Join us for the biggest summer festival of the year. Join us for a day of fun and celebration in our annual music festival right here in new york city.",
    type: "Entertainment",
    views: "0",
    location: "Central Park, New York",
    price: "Free",
    owner: "Current User",
    startDate: Date(),
    endDate: Date().addingTimeInterval(86400),
    images: ["bg1","bg2"],
    participants: ["John", "Jane", "Mike", "Sarah"],
    isTimed: true,
    createdAt: Date(),
    coordinates: []
) 
