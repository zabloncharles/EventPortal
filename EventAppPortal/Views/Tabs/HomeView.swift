import SwiftUI
import Firebase
import FirebaseFirestore

struct HomeView: View {
    @State private var searchText = ""
    @State private var pageAppeared = false
    @State private var startPoint: UnitPoint = .leading
    @State private var endPoint: UnitPoint = .trailing
    
    // Firebase state
    @State private var popularEvents: [Event] = []
    @State private var nearbyEvents: [Event] = []
    @State private var recommendedEvents: [Event] = []
    @State private var isLoadingPopular = true
    @State private var isLoadingNearby = true
    @State private var isLoadingRecommended = true
    @State private var errorMessage: String?
    @EnvironmentObject private var firebaseManager: FirebaseManager
    
    private var isLoading: Bool {
        isLoadingPopular || isLoadingNearby || isLoadingRecommended
    }
    
    // Fetch events from Firestore
    private func fetchEvents() {
        let db = Firestore.firestore()
        
        // Reset loading states
        isLoadingPopular = true
        isLoadingNearby = true
        isLoadingRecommended = true
        errorMessage = nil
        
        // Fetch popular events (sorted by views)
        db.collection("events")
            .whereField("status", isEqualTo: "active")
            .order(by: "views", descending: true)
            .limit(to: 10)
            .getDocuments { snapshot, error in
                isLoadingPopular = false
                if let error = error {
                    print("Error fetching popular events: \(error.localizedDescription)")
                    errorMessage = "Failed to load popular events"
                    return
                }
                
                popularEvents = snapshot?.documents.compactMap { document -> Event? in
                    let data = document.data()
                    guard let name = data["name"] as? String,
                          let description = data["description"] as? String,
                          let type = data["type"] as? String,
                          let location = data["location"] as? String,
                          let price = data["price"] as? String,
                          let owner = data["owner"] as? String,
                          let startDate = (data["startDate"] as? Timestamp)?.dateValue(),
                          let endDate = (data["endDate"] as? Timestamp)?.dateValue(),
                          let images = data["images"] as? [String],
                          let isTimed = data["isTimed"] as? Bool,
                          let coordinates = data["coordinates"] as? [Double]
                    else { return nil }
                    
                    let maxParticipants = data["maxParticipants"] as? Int ?? 0
                    let participants = Array(repeating: "Participant", count: maxParticipants)
                    
                    return Event(
                        name: name,
                        description: description,
                        type: type,
                        views: data["views"] as? String ?? "0",
                        location: location,
                        price: price,
                        owner: owner,
                        startDate: startDate,
                        endDate: endDate,
                        images: images,
                        participants: participants,
                        isTimed: isTimed,
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                        coordinates: coordinates
                    )
                } ?? []
            }
        
        // Fetch nearby events
        db.collection("events")
            .whereField("status", isEqualTo: "active")
            .order(by: "startDate")
            .limit(to: 5)
            .getDocuments { snapshot, error in
                isLoadingNearby = false
                if let error = error {
                    print("Error fetching nearby events: \(error.localizedDescription)")
                    errorMessage = "Failed to load nearby events"
                    return
                }
                
                nearbyEvents = snapshot?.documents.compactMap { document -> Event? in
                    let data = document.data()
                    guard let name = data["name"] as? String,
                          let description = data["description"] as? String,
                          let type = data["type"] as? String,
                          let location = data["location"] as? String,
                          let price = data["price"] as? String,
                          let owner = data["owner"] as? String,
                          let startDate = (data["startDate"] as? Timestamp)?.dateValue(),
                          let endDate = (data["endDate"] as? Timestamp)?.dateValue(),
                          let images = data["images"] as? [String],
                          let isTimed = data["isTimed"] as? Bool,
                          let coordinates = data["coordinates"] as? [Double]
                    else { return nil }
                    
                    let maxParticipants = data["maxParticipants"] as? Int ?? 0
                    let participants = Array(repeating: "Participant", count: maxParticipants)
                    
                    return Event(
                        name: name,
                        description: description,
                        type: type,
                        views: data["views"] as? String ?? "0",
                        location: location,
                        price: price,
                        owner: owner,
                        startDate: startDate,
                        endDate: endDate,
                        images: images,
                        participants: participants,
                        isTimed: isTimed,
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                        coordinates: coordinates
                    )
                }
                .filter { $0.startDate > Date() }
                .sorted { $0.startDate < $1.startDate } ?? []
            }
        
        // Fetch recommended events
        db.collection("events")
            .whereField("status", isEqualTo: "active")
            .limit(to: 10)
            .getDocuments { snapshot, error in
                isLoadingRecommended = false
                if let error = error {
                    print("Error fetching recommended events: \(error.localizedDescription)")
                    errorMessage = "Failed to load recommended events"
                    return
                }
                
                recommendedEvents = snapshot?.documents.compactMap { document -> Event? in
                    let data = document.data()
                    guard let name = data["name"] as? String,
                          let description = data["description"] as? String,
                          let type = data["type"] as? String,
                          let location = data["location"] as? String,
                          let price = data["price"] as? String,
                          let owner = data["owner"] as? String,
                          let startDate = (data["startDate"] as? Timestamp)?.dateValue(),
                          let endDate = (data["endDate"] as? Timestamp)?.dateValue(),
                          let images = data["images"] as? [String],
                          let isTimed = data["isTimed"] as? Bool,
                          let coordinates = data["coordinates"] as? [Double]
                    else { return nil }
                    
                    let maxParticipants = data["maxParticipants"] as? Int ?? 0
                    let participants = Array(repeating: "Participant", count: maxParticipants)
                    
                    return Event(
                        name: name,
                        description: description,
                        type: type,
                        views: data["views"] as? String ?? "0",
                        location: location,
                        price: price,
                        owner: owner,
                        startDate: startDate,
                        endDate: endDate,
                        images: images,
                        participants: participants,
                        isTimed: isTimed,
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                        coordinates: coordinates
                    )
                } ?? []
            }
    }
    
    private func EmptyStateView(title: String, message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private func SectionLoadingView() -> some View {
        HStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Spacer()
        }
        .padding()
    }
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 30) {
                    VStack {
                        HStack {
                            Text("LinkedUp Event Expectations.")
                                .font(.title)
                                .fontWeight(.bold)
                                .padding(.top, 20)
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.invert, .yellow, Color.invert]),
                                        startPoint: startPoint,
                                        endPoint: endPoint
                                    )
                                )
                                .onAppear {
                                    withAnimation(
                                        .linear(duration: 2)
                                    ) {
                                        startPoint = .trailing
                                        endPoint = .leading
                                    }
                                }
                            
                            Spacer()
                            
                            NavigationLink(destination: CreateEventView()) {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .medium))
                                    .frame(width: 36, height: 36)
                                    .background(Color.dynamic)
                                    .cornerRadius(60)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 60)
                                            .stroke(Color.gray, lineWidth: 1)
                                    )
                            }
                            
                            NavigationLink(destination: MyEventsView()) {
                                Image(systemName: "calendar")
                                    .renderingMode(.original)
                                    .font(.system(size: 16, weight: .medium))
                                    .frame(width: 36, height: 36)
                                    .background(Color.dynamic)
                                    .cornerRadius(60)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 60)
                                            .stroke(Color.gray, lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.horizontal)
                        
                        ZStack {
                            Rectangle()
                                .fill(.ultraThinMaterial)
                                .blur(radius: 570)
                            
                            VStack {
                                HStack {
                                    TextField("Search event, party...", text: $searchText)
                                        .padding()
                                        .background(Color(.systemGray6))
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.dynamic, lineWidth: 2)
                                        )
                                }
                                .padding(10)
                                .padding(.top, 0)
                                
                                if searchText.isEmpty {
                                    ForEach(["Community Cleanup", "Yoga Workshop", "Charity Gala"], id: \.self) { eventName in
                                        NavigationLink(destination: ViewEventDetail(event: sampleEvent)) {
                                            VStack {
                                                Divider()
                                                HStack {
                                                    Image(systemName: eventName == "Community Cleanup" ? "arrow.clockwise" :
                                                            eventName == "Yoga Workshop" ? "heart.fill" : "heart")
                                                    Text(eventName)
                                                        .font(.callout)
                                                        .foregroundColor(.primary)
                                                    Spacer()
                                                }
                                                .padding(.vertical, 7)
                                                .padding(.horizontal, 10)
                                                .cornerRadius(9)
                                                .padding(.horizontal)
                                            }
                                            .animation(.spring(), value: searchText.isEmpty)
                                        }
                                    }
                                }
                            }
                            .cornerRadius(20)
                        }
                        .padding(.horizontal)
                    }
                    .offset(y: !pageAppeared ? -UIScreen.main.bounds.height * 0.5 : 0)
                    
                    
                    
                    VStack {
                        // Popular Events Section
                        VStack(alignment: .leading, spacing: 20) {
                            HStack(alignment: .bottom) {
                                VStack(alignment: .leading) {
                                    Text("Popular events")
                                        .font(.headline)
                                    Text("View & join popular events!")
                                        .font(.callout)
                                }
                                Spacer()
                                VStack(alignment: .center) {
                                    Image(systemName: "flame")
                                }
                            }.padding(.horizontal)
                            
                            if isLoadingPopular {
                                SectionLoadingView()
                            } else if popularEvents.isEmpty {
                                EmptyStateView(
                                    title: "No Popular Events",
                                    message: "Be the first to create an exciting event!"
                                )
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: 16) {
                                        ForEach(popularEvents) { event in
                                            NavigationLink(destination: ViewEventDetail(event: event)) {
                                                PopularEventCard(event: event)
                                                    .frame(width: 280)
                                            }
                                        }
                                    }.padding(.leading)
                                        .padding(.trailing, 10)
                                }
                            }
                        }
                        
                        
                        // Plans Near You Section
                        VStack(alignment: .leading) {
                            HStack(alignment: .bottom) {
                                VStack(alignment: .leading) {
                                    Text("Plans near you")
                                        .font(.headline)
                                    Text("View and join plans near your area!")
                                        .font(.callout)
                                }
                                .padding(.top, 30)
                                Spacer()
                                VStack(alignment: .center) {
                                    Image(systemName: "figure.dance")
                                }
                            }
                            
                            if isLoadingNearby {
                                SectionLoadingView()
                            } else if nearbyEvents.isEmpty {
                                EmptyStateView(
                                    title: "No Nearby Events",
                                    message: "There are no upcoming events in your area yet."
                                )
                            } else {
                                ScrollView(.vertical, showsIndicators: false) {
                                    LazyVStack(spacing: 16) {
                                        ForEach(nearbyEvents) { event in
                                            NavigationLink(destination: ViewEventDetail(event: event)) {
                                                RegularEventCard(event: event, showdescription: false)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                        
                        // Recommended Events
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Recommended Events")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Spacer()
                                VStack(alignment: .center) {
                                    Image(systemName: "figure.dance")
                                }
                            }.padding(.horizontal)
                            
                            if isLoadingRecommended {
                                SectionLoadingView()
                            } else if recommendedEvents.isEmpty {
                                EmptyStateView(
                                    title: "No Recommendations",
                                    message: "Check back later for personalized event recommendations!"
                                )
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(recommendedEvents) { event in
                                            NavigationLink(destination: ViewEventDetail(event: event)) {
                                                RecommendedEventCard(event: event)
                                            }
                                        }
                                    }
                                }.padding(.leading)
                            }
                        }.padding(.bottom, 70)
                        
                        Spacer()
                    }
                    .offset(y: !pageAppeared ? UIScreen.main.bounds.height * 0.5 : 0)
                }
                .padding(.bottom)
            }
            .background(Color.dynamic)
            .navigationBarHidden(true)
            .onAppear {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                    pageAppeared = true
                }
                fetchEvents()
            }
            .refreshable {
                fetchEvents()
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
}

struct PopularEventCard: View {
    var event: Event = sampleEvent
    let colors: [Color] = [.red, .blue, .green, .orange]
    
    var body: some View {
        VStack {
            ZStack {
                LinearGradient(colors: [.black, .clear], startPoint: .bottomLeading, endPoint: .topTrailing)
                
                ZStack {
                    VStack(alignment: .leading) {
                        HStack {
                            if event.endDate == nil {
                                Text("Ongoing")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("Event")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                            } else {
                                Text(returnMonthOrDay(from: event.startDate ?? Date(), getDayNumber: false).capitalized)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Text(returnMonthOrDay(from: event.startDate ?? Date(), getDayNumber: true))
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.top, 10)
                        Spacer()
                        
                        HStack(alignment: .bottom) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(event.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.clear)
                                    .overlay(
                                        LinearGradient(
                                            gradient: Gradient(colors: [colors.randomElement() ?? .blue, .purple]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                        .mask(
                                            Text(event.name)
                                                .font(.title2)
                                                .fontWeight(.bold)
                                        )
                                    )
                                Text(event.location.components(separatedBy: ",")[0])
                            }
                            .multilineTextAlignment(.leading)
                            Spacer()
                            VStack {
                                ZStack {
                                    ForEach(0..<colors.count, id: \.self) { index in
                                        Circle()
                                            .fill(colors[index])
                                            .frame(width: 15, height: 15)
                                            .offset(x: CGFloat(index * 10 - 0))
                                    }
                                }
                                Text("\(event.participants.count) \(event.participants.count > 1 ? "Participants" : "Participant")")
                                    .font(.footnote)
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    }
                    .padding()
                }
            }
            .background(
                Image(event.images[0])
                    .resizable()
                    .scaledToFill()
            )
            .cornerRadius(20)
        }
    }
    
    func returnMonthOrDay(from date: Date, getDayNumber: Bool) -> String {
        let calendar = Calendar.current
        if getDayNumber {
            let day = calendar.component(.day, from: date)
            return "\(day)"
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM"
            return dateFormatter.string(from: date)
        }
    }
}

struct RegularEventCard: View {
    var event: Event = sampleEvent
    var showdescription = true
    let colors: [Color] = [.red, .blue, .green, .orange]
    
    var body: some View {
        VStack {
            ZStack {
                LinearGradient(colors: [.black, .black.opacity(0.40), .black.opacity(0.60)], startPoint: .bottomLeading, endPoint: .topTrailing)
                
                ZStack {
                    VStack(alignment: .leading) {
                        HStack {
                            if event.endDate == nil {
                                Text("Ongoing")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("Event")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                            } else {
                                Text(returnMonthOrDay(from: event.startDate ?? Date(), getDayNumber: false).capitalized)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Text(returnMonthOrDay(from: event.startDate ?? Date(), getDayNumber: true))
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.top, 10)
                        
                        Spacer()
                        HStack(alignment: .bottom) {
                            Spacer()
                            VStack(alignment: .leading, spacing: 3) {
                                    Text(event.description.split(separator: ".")[0] + ".")
                                        .font(.callout)
                                        .foregroundColor(.white)
                                        .padding(.leading)
                                        .lineLimit(2)
                                    .opacity(showdescription ? 1 : 0)
                                
                            }.multilineTextAlignment(.trailing)
                        }
                        HStack(alignment: .bottom) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(event.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.clear)
                                    .overlay(
                                        LinearGradient(
                                            gradient: Gradient(colors: [colors.randomElement() ?? .blue, .purple]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                        .mask(
                                            Text(event.name)
                                                .font(.title2)
                                                .fontWeight(.bold)
                                        )
                                    )
                                Text(event.location.components(separatedBy: ",")[0])
                            }.multilineTextAlignment(.leading)
                            Spacer()
                            VStack {
                                ZStack {
                                    ForEach(0..<colors.count, id: \.self) { index in
                                        Circle()
                                            .fill(colors[index])
                                            .frame(width: 15, height: 15)
                                            .offset(x: CGFloat(index * 10 - 0))
                                    }
                                }
                                Text("\(event.participants.count) \(event.participants.count > 1 ? "Participants" : "Participant")")
                                    .font(.footnote)
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    }
                    .padding()
                }
            }
            .background(
                Image(event.images[0])
                    .resizable()
                    .scaledToFill()
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.dynamic.opacity(0.20), lineWidth: 1)
            )
            .cornerRadius(20)
        }.frame(height: 200)
        
    }
    
    func returnMonthOrDay(from date: Date, getDayNumber: Bool) -> String {
        let calendar = Calendar.current
        if getDayNumber {
            let day = calendar.component(.day, from: date)
            return "\(day)"
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM"
            return dateFormatter.string(from: date)
        }
    }
}


struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
} 

