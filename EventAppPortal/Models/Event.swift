import Foundation

struct Event: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let location: String
    let startDate: Date?
    let endDate: Date?
    let images: [String]
    let participants: [String]
}

// Sample event for previews
let sampleEvent = Event(
    name: "Summer Music Festival",
    description: "A day of amazing music and entertainment. Join us for the biggest summer festival of the year.",
    location: "Central Park, New York",
    startDate: Date(),
    endDate: Date().addingTimeInterval(86400),
    images: ["bg1"],
    participants: ["John", "Jane", "Mike", "Sarah"]
) 