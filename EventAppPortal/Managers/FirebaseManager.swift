class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    private let db = Firestore.firestore()
    
    // MARK: - Event Management
    
    func fetchEvents() async throws -> [Event] {
        print("Starting to fetch events from Firebase")
        let snapshot = try await db.collection("events")
            .whereField("status", isEqualTo: "active")
            .getDocuments()
        
        print("Found \(snapshot.documents.count) documents")
        
        let events = snapshot.documents.compactMap { document -> Event? in
            do {
                let data = document.data()
                let event = Event(
                    id: document.documentID,
                    name: data["name"] as? String ?? "",
                    description: data["description"] as? String ?? "",
                    type: data["type"] as? String ?? "",
                    location: data["location"] as? String ?? "",
                    startDate: (data["startDate"] as? Timestamp)?.dateValue() ?? Date(),
                    endDate: (data["endDate"] as? Timestamp)?.dateValue() ?? Date(),
                    price: data["price"] as? String ?? "0",
                    imageURL: data["imageURL"] as? String ?? "",
                    participants: data["participants"] as? [String] ?? [],
                    isTimedEvent: data["isTimedEvent"] as? Bool ?? false,
                    status: data["status"] as? String ?? "active"
                )
                return event
            } catch {
                print("Error parsing event data: \(error)")
                return nil
            }
        }
        
        print("Successfully parsed \(events.count) events")
        return events
    }
    
    func fetchEventsByType(_ type: String) async throws -> [Event] {
        print("Fetching events of type: \(type)")
        let snapshot = try await db.collection("events")
            .whereField("status", isEqualTo: "active")
            .whereField("type", isEqualTo: type)
            .getDocuments()
        
        let events = snapshot.documents.compactMap { document -> Event? in
            do {
                let data = document.data()
                let event = Event(
                    id: document.documentID,
                    name: data["name"] as? String ?? "",
                    description: data["description"] as? String ?? "",
                    type: data["type"] as? String ?? "",
                    location: data["location"] as? String ?? "",
                    startDate: (data["startDate"] as? Timestamp)?.dateValue() ?? Date(),
                    endDate: (data["endDate"] as? Timestamp)?.dateValue() ?? Date(),
                    price: data["price"] as? String ?? "0",
                    imageURL: data["imageURL"] as? String ?? "",
                    participants: data["participants"] as? [String] ?? [],
                    isTimedEvent: data["isTimedEvent"] as? Bool ?? false,
                    status: data["status"] as? String ?? "active"
                )
                print("Successfully parsed event: \(event.name)")
                return event
            } catch {
                print("Error parsing event document: \(error)")
                return nil
            }
        }
        
        print("Found \(events.count) events of type \(type)")
        return events
    }
    
    func fetchEventsByLocation(_ location: String) async throws -> [Event] {
        let snapshot = try await db.collection("events")
            .whereField("status", isEqualTo: "active")
            .whereField("location", isEqualTo: location)
            .getDocuments()
        
        return snapshot.documents.compactMap { document -> Event? in
            let data = document.data()
            return Event(
                id: document.documentID,
                name: data["name"] as? String ?? "",
                description: data["description"] as? String ?? "",
                type: data["type"] as? String ?? "",
                location: data["location"] as? String ?? "",
                startDate: (data["startDate"] as? Timestamp)?.dateValue() ?? Date(),
                endDate: (data["endDate"] as? Timestamp)?.dateValue() ?? Date(),
                price: data["price"] as? String ?? "0",
                imageURL: data["imageURL"] as? String ?? "",
                participants: data["participants"] as? [String] ?? [],
                isTimedEvent: data["isTimedEvent"] as? Bool ?? false,
                status: data["status"] as? String ?? "active"
            )
        }
    }
    
    func fetchEventsByDateRange(startDate: Date, endDate: Date) async throws -> [Event] {
        let snapshot = try await db.collection("events")
            .whereField("status", isEqualTo: "active")
            .whereField("startDate", isGreaterThanOrEqualTo: startDate)
            .whereField("endDate", isLessThanOrEqualTo: endDate)
            .getDocuments()
        
        return snapshot.documents.compactMap { document -> Event? in
            let data = document.data()
            return Event(
                id: document.documentID,
                name: data["name"] as? String ?? "",
                description: data["description"] as? String ?? "",
                type: data["type"] as? String ?? "",
                location: data["location"] as? String ?? "",
                startDate: (data["startDate"] as? Timestamp)?.dateValue() ?? Date(),
                endDate: (data["endDate"] as? Timestamp)?.dateValue() ?? Date(),
                price: data["price"] as? String ?? "0",
                imageURL: data["imageURL"] as? String ?? "",
                participants: data["participants"] as? [String] ?? [],
                isTimedEvent: data["isTimedEvent"] as? Bool ?? false,
                status: data["status"] as? String ?? "active"
            )
        }
    }
    
    func fetchEventsByPriceRange(minPrice: Double, maxPrice: Double) async throws -> [Event] {
        let snapshot = try await db.collection("events")
            .whereField("status", isEqualTo: "active")
            .whereField("price", isGreaterThanOrEqualTo: minPrice)
            .whereField("price", isLessThanOrEqualTo: maxPrice)
            .getDocuments()
        
        return snapshot.documents.compactMap { document -> Event? in
            let data = document.data()
            return Event(
                id: document.documentID,
                name: data["name"] as? String ?? "",
                description: data["description"] as? String ?? "",
                type: data["type"] as? String ?? "",
                location: data["location"] as? String ?? "",
                startDate: (data["startDate"] as? Timestamp)?.dateValue() ?? Date(),
                endDate: (data["endDate"] as? Timestamp)?.dateValue() ?? Date(),
                price: data["price"] as? String ?? "0",
                imageURL: data["imageURL"] as? String ?? "",
                participants: data["participants"] as? [String] ?? [],
                isTimedEvent: data["isTimedEvent"] as? Bool ?? false,
                status: data["status"] as? String ?? "active"
            )
        }
    }
    
    func fetchEventsByParticipants(minParticipants: Int) async throws -> [Event] {
        let snapshot = try await db.collection("events")
            .whereField("status", isEqualTo: "active")
            .whereField("participants", isGreaterThanOrEqualTo: minParticipants)
            .getDocuments()
        
        return snapshot.documents.compactMap { document -> Event? in
            let data = document.data()
            return Event(
                id: document.documentID,
                name: data["name"] as? String ?? "",
                description: data["description"] as? String ?? "",
                type: data["type"] as? String ?? "",
                location: data["location"] as? String ?? "",
                startDate: (data["startDate"] as? Timestamp)?.dateValue() ?? Date(),
                endDate: (data["endDate"] as? Timestamp)?.dateValue() ?? Date(),
                price: data["price"] as? String ?? "0",
                imageURL: data["imageURL"] as? String ?? "",
                participants: data["participants"] as? [String] ?? [],
                isTimedEvent: data["isTimedEvent"] as? Bool ?? false,
                status: data["status"] as? String ?? "active"
            )
        }
    }
    
    func fetchDiscoverEvents() async throws -> [Event] {
        print("Starting to fetch discover events from Firebase")
        let snapshot = try await db.collection("events")
            .whereField("status", isEqualTo: "active")
            .getDocuments()
        
        print("Found \(snapshot.documents.count) documents")
        
        let events = snapshot.documents.compactMap { document -> Event? in
            do {
                let data = document.data()
                let event = Event(
                    id: document.documentID,
                    name: data["name"] as? String ?? "",
                    description: data["description"] as? String ?? "",
                    type: data["type"] as? String ?? "",
                    location: data["location"] as? String ?? "",
                    startDate: (data["startDate"] as? Timestamp)?.dateValue() ?? Date(),
                    endDate: (data["endDate"] as? Timestamp)?.dateValue() ?? Date(),
                    price: data["price"] as? String ?? "0",
                    imageURL: data["imageURL"] as? String ?? "",
                    participants: data["participants"] as? [String] ?? [],
                    isTimedEvent: data["isTimedEvent"] as? Bool ?? false,
                    status: data["status"] as? String ?? "active"
                )
                return event
            } catch {
                print("Error parsing event data: \(error)")
                return nil
            }
        }
        
        print("Successfully parsed \(events.count) discover events")
        return events
    }
    
    // MARK: - Event Filtering
    
    func applyEventFilters(filters: EventFilters, events: [Event]) -> [Event] {
        print("Applying filters to \(events.count) events")
        var filteredEvents = events
        
        // Apply type filter
        if filters.selectedType != "All" {
            filteredEvents = filteredEvents.filter { $0.type == filters.selectedType }
            print("After type filter: \(filteredEvents.count) events")
        }
        
        // Apply location filter
        if filters.selectedLocation != "All" {
            filteredEvents = filteredEvents.filter { $0.location == filters.selectedLocation }
            print("After location filter: \(filteredEvents.count) events")
        }
        
        // Apply price range filter
        filteredEvents = filteredEvents.filter { event in
            let price = Double(event.price.replacingOccurrences(of: "$", with: "")) ?? 0
            return price >= filters.priceRange.lowerBound && price <= filters.priceRange.upperBound
        }
        print("After price filter: \(filteredEvents.count) events")
        
        // Apply date range filter
        filteredEvents = filteredEvents.filter { event in
            event.startDate >= filters.startDate && event.startDate <= filters.endDate
        }
        print("After date filter: \(filteredEvents.count) events")
        
        // Apply timed events filter
        if filters.showTimedEventsOnly {
            filteredEvents = filteredEvents.filter { $0.isTimedEvent }
            print("After timed events filter: \(filteredEvents.count) events")
        }
        
        // Apply participants filter
        if filters.minParticipants > 0 {
            filteredEvents = filteredEvents.filter { $0.participants.count >= filters.minParticipants }
            print("After participants filter: \(filteredEvents.count) events")
        }
        
        print("Final filtered events count: \(filteredEvents.count)")
        return filteredEvents
    }
} 