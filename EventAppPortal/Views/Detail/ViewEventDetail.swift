import SwiftUI
import MapKit
import Firebase
import FirebaseFirestore

struct ViewEventDetail: View {
    var event: Event
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var tabBarManager = TabBarVisibilityManager.shared
    @EnvironmentObject private var firebaseManager: FirebaseManager
    @State private var currentPage = 0
    @State private var isDescriptionExpanded = false
    @State private var showTicket = false
    @State private var showPurchaseView = false
    @State private var hasTicket = false
    @State private var bookmarked = false
    @State private var organizerName: String = "Loading..."
    @State private var viewCount: Int = 0
    let hapticFeedback = UINotificationFeedbackGenerator()
    @AppStorage("userID") private var userID: String = ""
    @StateObject private var viewModel = RecommendedEventsViewModel()
    @State private var pageAppeared = false
    @State private var bottomBarAppeared = false
    @State private var isPurchasing = false
    @State private var purchaseError: String?
    @State private var showPurchaseError = false
    @State private var showPurchaseSuccess = false
    @State private var showRecommendedEvent = false
    @State private var showRecommendedEventDetails : Event = sampleEvent
    var hideRecommendedCards = false
    private func incrementViews() {
        let db = Firestore.firestore()
//        print("Attempting to increment views for event ID: \(event.id)")
        
        let eventRef = db.collection("events").document(event.id)
        
        // First get the current view count
        eventRef.getDocument { document, error in
            if let error = error {
//                print("Error fetching event document: \(error)")
                return
            }
            
            if let document = document {
//                print("Document exists: \(document.exists)")
//                print("Document ID: \(document.documentID)")
                if let data = document.data() {
                    print("Document data: \(data)")
                }
                
                if document.exists {
                    // Get current views as string and convert to int
                    let currentViews = Int(document.data()?["views"] as? String ?? "0") ?? 0
                    self.viewCount = currentViews
                    let newViews = currentViews + 1
//                    print("Current views: \(currentViews), New views: \(newViews)")
                    
                    // Update views as string in Firestore
                    eventRef.updateData([
                        "views": String(newViews)
                    ]) { error in
                        if let error = error {
                            print("Error updating view count: \(error)")
                        } else {
//                            print("Successfully updated view count to \(newViews)")
                            DispatchQueue.main.async {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        self.viewCount = newViews
                                    }
                                   
                                }
                            }
                        }
                    }
                } 
            }
        }
    }
    
    private func toggleBookmark() {
        guard !userID.isEmpty else { 
            print("UserID is empty")
            return 
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userID)
        
        // First check if the user document exists
        userRef.getDocument { document, error in
            if let error = error {
                print("Error checking user document: \(error)")
                return
            }
            
            if let document = document, document.exists {
                // Document exists, update the bookmarks array
                if self.bookmarked {
                    // Remove from bookmarks
                    userRef.updateData([
                        "bookmarkedEvents": FieldValue.arrayRemove([self.event.id])
                    ]) { error in
                        if let error = error {
                            print("Error removing bookmark: \(error)")
                        } else {
                            DispatchQueue.main.async {
                                self.hapticFeedback.notificationOccurred(.success)
                                self.bookmarked = false
                            }
                        }
                    }
                } else {
                    // Add to bookmarks
                    userRef.updateData([
                        "bookmarkedEvents": FieldValue.arrayUnion([self.event.id])
                    ]) { error in
                        if let error = error {
                            print("Error adding bookmark: \(error)")
                        } else {
                            DispatchQueue.main.async {
                                self.hapticFeedback.notificationOccurred(.success)
                                self.bookmarked = true
                            }
                        }
                    }
                }
            } else {
                // Document doesn't exist, create it with initial bookmarks array
                userRef.setData([
                    "bookmarkedEvents": [self.event.id]
                ], merge: true) { error in
                    if let error = error {
                        print("Error creating user document: \(error)")
                    } else {
                        DispatchQueue.main.async {
                            self.hapticFeedback.notificationOccurred(.success)
                            self.bookmarked = true
                        }
                    }
                }
            }
        }
    }
    
    private func checkIfBookmarked() {
        guard !userID.isEmpty else { 
            print("UserID is empty")
            return 
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(userID).getDocument { document, error in
            if let error = error {
                print("Error checking bookmark status: \(error)")
                return
            }
            
            if let document = document, document.exists {
                if let bookmarkedEvents = document.data()?["bookmarkedEvents"] as? [String] {
                    DispatchQueue.main.async {
                        self.bookmarked = bookmarkedEvents.contains(self.event.id)
                    }
                }
            }
        }
    }
    
    private func checkIfUserHasTicket() {
        guard !userID.isEmpty else { return }
        
        let db = Firestore.firestore()
        db.collection("events").document(event.id).getDocument { document, error in
            if let error = error {
                print("Error checking ticket status: \(error)")
                return
            }
            
            if let document = document, document.exists {
                if let participants = document.data()?["participants"] as? [String] {
                    DispatchQueue.main.async {
                        self.hasTicket = participants.contains(userID)
                    }
                }
            }
        }
    }
    
    private func purchaseTicket() {
        isPurchasing = true
        firebaseManager.purchaseTicket(eventId: event.id) { success, error in
            isPurchasing = false
            if success {
                showPurchaseSuccess = true
                hasTicket = true
                hapticFeedback.notificationOccurred(.success)
            } else {
                purchaseError = error ?? "Failed to purchase ticket"
                showPurchaseError = true
                hapticFeedback.notificationOccurred(.error)
            }
        }
    }
    
    private func checkTicketStatus() {
        guard let userId = firebaseManager.currentUser?.uid else { return }
        
        // Check if the user is in the event's participants list
        hasTicket = event.participants.contains(userId)
    }

    // MARK: - Header Section
    private var headerSection: some View {
        ZStack(alignment: .top) {
            CompactImageViewer(imageUrls: event.images, height: 400, scroll: true)
               
            
            // Back button and bookmark overlay
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                
                Spacer()
                
                Button(action: { toggleBookmark() }) {
                    Image(systemName: bookmarked ? "bookmark.fill" : "bookmark")
                        .font(.title2)
                        .foregroundColor(bookmarked ? .yellow : .white)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal)
            .padding(.top, 38)
            .safeAreaInset(edge: .top) { Color.clear.frame(height: 0) }
        }
    }

    // MARK: - Title and Views Section
    private var titleAndViewsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(event.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.primary, .primary.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .foregroundColor(.blue)
                        Text(event.location.split(separator: ",")[0])
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Image(systemName: "eye.fill")
                        .foregroundColor(.blue)
                    Text(viewCount > 1000 ? String(format: "%.1fk", Double(viewCount)/1000.0) : "\(viewCount)")
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(20)
            }
        }
    }

    // MARK: - Event Type Icons Section
    private var eventTypeIconsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 24) {
                Spacer()
                EventTypeIcon(icon: {
                    switch event.type {
                    case "Concert": return "figure.dance"
                    case "Corporate": return "building.2.fill"
                    case "Marketing": return "megaphone.fill"
                    case "Health & Wellness": return "heart.fill"
                    case "Technology": return "desktopcomputer"
                    case "Art & Culture": return "paintbrush.fill"
                    case "Charity": return "heart.circle.fill"
                    case "Literature": return "book.fill"
                    case "Lifestyle": return "leaf.fill"
                    case "Environmental": return "leaf.arrow.triangle.circlepath"
                    case "Entertainment": return "music.note.list"
                    default: return "calendar"
                    }
                }(), text: event.type)
                
                EventTypeIcon(
                    icon: "calendar",
                    text: formatDate(event.startDate)
                )
                
                EventTypeIcon(
                    icon: "person.2.fill",
                    text: "\(event.participants.count) Going"
                )
                
                EventTypeIcon(
                    icon: "dollarsign.circle.fill",
                    text: event.price == "0" ? "Free" : event.price
                )
                Spacer()
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }

    // MARK: - Description Section
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About Event")
                .font(.title3)
                .fontWeight(.bold)
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(event.description)
                        .foregroundColor(.secondary)
                        .lineLimit(isDescriptionExpanded ? nil : 3)
                        .animation(.easeInOut, value: isDescriptionExpanded)
                    
                    Button(action: {
                        withAnimation {
                            isDescriptionExpanded.toggle()
                        }
                    }) {
                        Text(isDescriptionExpanded ? "Read Less" : "Read More")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                }
               Spacer()
            } .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(12)
        }
    }

    // MARK: - Event Organizer Section
    private var eventOrganizerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Organizer")
                .font(.title3)
                .fontWeight(.bold)
            
            HStack(spacing: 16) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.blue)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.organizerName)
                        .font(.headline)
                    Text("Event Organizer")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 20) {
                    Button(action: {}) {
                        Image(systemName: "message.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                            .padding(12)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "phone.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                            .padding(12)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
            .padding()
            .background(Color.blue.opacity(0.05))
            .cornerRadius(12)
        }
    }

    // MARK: - Location Section
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Location")
                .font(.title3)
                .fontWeight(.bold)
            
            LocationMapView(coordinate: CLLocationCoordinate2D(
                latitude: event.coordinates.count >= 2 ? event.coordinates[0] : 40.7128,
                longitude: event.coordinates.count >= 2 ? event.coordinates[1] : -74.0060
            ))
            .frame(height: 200)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                    Text(event.location)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if event.coordinates.count >= 2 {
                    Link(destination: URL(string: "http://maps.apple.com/?ll=\(event.coordinates[0]),\(event.coordinates[1])")!) {
                        HStack(spacing: 4) {
                            Text("Get directions")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Image(systemName: "arrow.right")
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(20)
                    }
                }
            }
            .padding()
            .background(Color.blue.opacity(0.05))
            .cornerRadius(12)
        }
    }

    // MARK: - Recommended Events Section
    private var recommendedEventsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Similar Events")
                .font(.title3)
                .fontWeight(.bold)
            
            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                    Spacer()
                }
                .frame(height: 200)
                .padding(.bottom,120)
            } else if viewModel.error != nil {
                Text("Unable to load recommendations")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom,120)
            } else if viewModel.recommendedEvents.isEmpty {
                Text("No similar events found")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom,120)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(viewModel.recommendedEvents.filter { $0.id != event.id }.prefix(3)) { event in
                            Button {
                                showRecommendedEventDetails = event
                                showRecommendedEvent = true
                            } label: {
                                RecommendedEventCard(event: event)
                            }
                        }
                    }
                    
                }
                .padding(.bottom,120)
            }
        }
        .onAppear {
            print("Loading recommended events...")
            self.viewModel.loadRecommendedEvents()
        }
    }

    // MARK: - Bottom Bar Section
    private var bottomBarSection: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 0) {
                Divider()
                
                HStack(spacing: 20) {
                    if hasTicket {
                        Button(action: {
                            withAnimation(.spring()) {
                                showTicket = true
                            }
                        }) {
                            HStack {
                                Image(systemName: "ticket.fill")
                                Text("View Ticket")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.green)
                            .cornerRadius(25)
                        }
                    } else {
                        Button(action: {
                            showPurchaseView = true
                        }) {
                            HStack {
                                Image(systemName: "ticket.fill")
                                Text(event.price == "0" ? "Get Free Ticket" : "Buy Ticket")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(25)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .padding(.bottom, 20)
            }
            .background(Color.dynamic)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 0,
                    style: .continuous
                )
            )
        }
        .edgesIgnoringSafeArea(.bottom)
        
    }

    var body: some View {
        ZStack {
            ScrollableNavigationBar(
                title: event.type,
                isInline: false,
                showBackButton: true
            ) {
                VStack(spacing: 0) {
                    // Header section with image viewer
                    headerSection
                        .frame(height: 400)
                    
                    // Scrollable content
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            titleAndViewsSection
                            eventTypeIconsSection
                            descriptionSection
                            eventOrganizerSection
                            locationSection
                            
                            if !hideRecommendedCards {
                                recommendedEventsSection
                            }
                        }
                        .padding()
                        .padding(.bottom, hideRecommendedCards ? 120 : 0)
                    }
                }
            }
            .offset(y: showTicket ? -90 : 0)
            .animation(.spring(), value: showTicket)
            
            if showTicket {
                TicketView(event: event, isShowing: $showTicket)
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
            }
            
            bottomBarSection
        }
        .sheet(isPresented: $showPurchaseView) {
            PurchaseTicketView(event: event, isPresented: $showPurchaseView, hasTicket: $hasTicket)
        }
        .sheet(isPresented: $showRecommendedEvent) {
            ViewEventDetail(event: showRecommendedEventDetails, hideRecommendedCards: true)
                .navigationBarTitle(showRecommendedEventDetails.name)
                .toolbarBackground(Color.dynamic)
                .padding(.top, -30)
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                pageAppeared = true
                DispatchQueue.main.asyncAfter(deadline:.now() + 0.5) {
                    bottomBarAppeared = true
                }
            }
            // Increment views when the view appears
            incrementViews()
            //Record this event as an activity of the user
            self.viewModel.recordEventInteraction(event, type: .view)
            //hide tabbar
            tabBarManager.hideTab = true
            //hide tabbar again a second time
            DispatchQueue.main.asyncAfter(deadline:.now() + 1) {
                tabBarManager.hideTab = true
               
            }
            
            // Fetch organizer name from Firestore
//                let db = Firestore.firestore()
//                db.collection("users").document(event.owner).getDocument { document, error in
//                    if let document = document, document.exists {
//                        organizerName = document.data()?["name"] as? String ?? "Unknown Organizer"
//                    } else {
//                        organizerName = "Unknown Organizer"
//                    }
//                }
                
                
               
                
                // Check if event is bookmarked
                checkIfBookmarked()
                checkIfUserHasTicket()
                checkTicketStatus()
        }
        .onDisappear {
            tabBarManager.hideTab = false
        }
        
        .toolbarBackground(Color.dynamic)
        .toolbar {
            Image(systemName: bookmarked ? "bookmark.fill" : "bookmark")
                .foregroundColor(bookmarked ? .blue : .white)
                .onTapGesture {
                    toggleBookmark()
                }
                .padding(10)
                
        }
        
        .alert("Purchase Error", isPresented: $showPurchaseError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(purchaseError ?? "An error occurred")
        }
        .alert("Success", isPresented: $showPurchaseSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your ticket has been purchased successfully!")
        }
        .overlay(
            Group {
                if isPurchasing {
                    ProgressView("Purchasing ticket...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 10)
                }
            }
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

struct EventTypeIcon: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 50, height: 50)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }
}

struct TicketView: View {
    var event: Event
    @Binding var isShowing: Bool
    @State private var offset: CGFloat = UIScreen.main.bounds.height
    @GestureState private var dragOffset: CGFloat = 0
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag Indicator
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.gray.opacity(isShowing ? 0.3 : 0))
                .frame(width: 40, height: 5)
                .padding(.top, 10)
            
            // Header with close button
            HStack {
                Spacer()
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isShowing = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Event Title and Type
                    VStack(spacing: 8) {
                        Text(event.type)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .foregroundColor(.primary)
                            .clipShape(Capsule())
                        
                        Text(event.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top)
                    
                    // Main Ticket Card
                    VStack(spacing: 24) {
                        // Date and Time Section
                        HStack(spacing: 30) {
                            // Date
                            VStack(spacing: 8) {
                                Image(systemName: "calendar")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                Text(dateFormatter.string(from: event.startDate))
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                            
                            // Time
                            VStack(spacing: 8) {
                                Image(systemName: "clock")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                Text(timeFormatter.string(from: event.startDate))
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding(.vertical)
                        
                        // Location Section
                        VStack(spacing: 8) {
                            Image(systemName: "location.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                            Text(event.location)
                                .font(.headline)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical)
                        
                        // Divider
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 1)
                            .padding(.horizontal)
                        
                        // Ticket Details
                        VStack(spacing: 20) {
                            // Ticket Code
                            VStack(spacing: 8) {
                                Text("TICKET CODE")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.gray)
                                Text("EVT-\(String(event.id.prefix(8)))")
                                    .font(.system(.title3, design: .monospaced))
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                            }
                            
                            // QR Code
                            VStack(spacing: 12) {
                                Image(systemName: "qrcode")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 180, height: 180)
                                    .foregroundColor(.primary)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(16)
                                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                                
                                Text("Scan to verify ticket")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            // Additional Info
                            VStack(spacing: 16) {
                                InfoRow(title: "Price", value: event.price == "0" ? "Free" : event.price)
                                InfoRow(title: "Organizer", value: event.organizerName)
                                InfoRow(title: "Attendees", value: "\(event.participants.count)")
                            }
                            .padding()
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(16)
                        }
                    }
                    .padding(24)
                    .background(Color(.systemBackground))
                    .cornerRadius(24)
                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                }
                .padding()
            }
        }
        .background(Color.dynamic)
        .cornerRadius(20)
        .shadow(radius: 10)
        .padding()
        .offset(y: offset + dragOffset)
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    if value.translation.height > 0 {
                        state = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height > 100 {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isShowing = false
                        }
                    } else {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            offset = 0
                        }
                    }
                }
        )
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                offset = 0
            }
        }
        .onChange(of: isShowing) { newValue in
            if !newValue {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    offset = UIScreen.main.bounds.height
                }
            }
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

struct PurchaseTicketView: View {
    var event: Event
    @Binding var isPresented: Bool
    @Binding var hasTicket: Bool
    @State private var selectedPaymentMethod = 0
    @State private var isProcessing = false
    @State private var cardNumber = ""
    @State private var cardExpiry = ""
    @State private var cardCVV = ""
    @State private var cardHolderName = ""
    @State private var isCardFlipped = false
    @State private var showError = false
    @State private var errorMessage: String?
    let hapticFeedback = UINotificationFeedbackGenerator()
    @EnvironmentObject private var firebaseManager: FirebaseManager
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Ticket Summary
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Ticket Summary")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("Event")
                                    .foregroundColor(.white)
                                Spacer()
                                Text(event.name)
                                    .foregroundColor(.gray)
                            }
                            
                            HStack {
                                Text("Date")
                                    .foregroundColor(.white)
                                Spacer()
                                Text(dateFormatter.string(from: event.startDate))
                                    .foregroundColor(.gray)
                            }
                            
                            HStack {
                                Text("Time")
                                    .foregroundColor(.white)
                                Spacer()
                                Text(timeFormatter.string(from: event.startDate))
                                    .foregroundColor(.gray)
                            }
                            
                            Divider()
                                .background(Color.gray.opacity(0.3))
                            
                            HStack {
                                Text("Total")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Spacer()
                                Text(event.price)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                    
                    // Credit Card Preview with Flip
                    if selectedPaymentMethod == 0 {
                        ZStack {
                            CreditCardView(
                                cardNumber: cardNumber,
                                cardHolderName: cardHolderName,
                                expiryDate: cardExpiry
                            )
                            .opacity(isCardFlipped ? 0 : 1)
                            .rotation3DEffect(.degrees(isCardFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                            
                            BackCardView(cvv: cardCVV)
                                .opacity(isCardFlipped ? 1 : 0)
                                .rotation3DEffect(.degrees(isCardFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
                        }
                        .animation(.easeInOut(duration: 0.5), value: isCardFlipped)
                        
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    }
                    
                    // Payment Method
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Payment Method")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Picker("Payment Method", selection: $selectedPaymentMethod) {
                            Text("Credit Card").tag(0)
                            Text("Apple Pay").tag(1)
                            Text("PayPal").tag(2)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .colorScheme(.dark)
                        .animation(.easeInOut(duration: 0.3), value: selectedPaymentMethod)
                        
                        if selectedPaymentMethod == 0 {
                            VStack(spacing: 16) {
                                TextField("Card Holder Name", text: $cardHolderName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .colorScheme(.dark)
                                    .textInputAutocapitalization(.words)
                                    .onTapGesture {
                                        withAnimation {
                                            isCardFlipped = false
                                        }
                                    }
                                
                                TextField("Card Number", text: $cardNumber)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .colorScheme(.dark)
                                    .keyboardType(.numberPad)
                                    .onChange(of: cardNumber) { newValue in
                                        // Format card number with spaces
                                        
                                        let filtered = newValue.filter { $0.isNumber }
                                        if filtered.count > 16 {
                                            cardNumber = String(filtered.prefix(16))
                                        } else {
                                            cardNumber = filtered.enumerated().map { index, char in
                                                if index > 0 && index % 4 == 0 {
                                                    return " \(char)"
                                                }
                                                return String(char)
                                            }.joined()
                                        }
                                    }
                                    .onTapGesture {
                                        withAnimation {
                                            isCardFlipped = false
                                        }
                                    }
                                
                                HStack {
                                    TextField("MM/YY", text: $cardExpiry)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .colorScheme(.dark)
                                        .keyboardType(.numberPad)
                                        .onTapGesture {
                                            withAnimation {
                                                isCardFlipped = false
                                            }
                                        }
                                        .onChange(of: cardExpiry) { newValue in
                                            let filtered = newValue.filter { $0.isNumber }
                                            if filtered.count > 4 {
                                                cardExpiry = String(filtered.prefix(4))
                                            } else if filtered.count > 2 {
                                                cardExpiry = String(filtered.prefix(2)) + "/" + String(filtered.dropFirst(2))
                                            } else {
                                                cardExpiry = filtered
                                            }
                                        }
                                    
                                    SecureField("CVV", text: $cardCVV)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .colorScheme(.dark)
                                        .keyboardType(.numberPad)
                                        .onChange(of: cardCVV) { newValue in
                                            if newValue.count > 3 {
                                                cardCVV = String(newValue.prefix(3))
                                            }
                                        }
                                    .onTapGesture {
                                        withAnimation {
                                            isCardFlipped = true
                                        }
                                    }
                                    .onSubmit {
                                        withAnimation {
                                            isCardFlipped = false
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Purchase Button
                    Button(action: {
                        isProcessing = true
                        hapticFeedback.notificationOccurred(.success)
                        
                        // Validate card details if credit card is selected
                        if selectedPaymentMethod == 0 {
                            if cardNumber.isEmpty || cardExpiry.isEmpty || cardCVV.isEmpty || cardHolderName.isEmpty {
                                errorMessage = "Please fill in all card details"
                                showError = true
                            isProcessing = false
                                hapticFeedback.notificationOccurred(.error)
                                return
                            }
                            
                            // Basic validation
                            if cardNumber.replacingOccurrences(of: " ", with: "").count != 16 {
                                errorMessage = "Invalid card number"
                                showError = true
                                isProcessing = false
                                hapticFeedback.notificationOccurred(.error)
                                return
                            }
                            
                            if cardCVV.count != 3 {
                                errorMessage = "Invalid CVV"
                                showError = true
                                isProcessing = false
                                hapticFeedback.notificationOccurred(.error)
                                return
                            }
                        }
                        
                        // Process the ticket purchase through Firebase
                        firebaseManager.purchaseTicket(eventId: event.id) { success, error in
                            DispatchQueue.main.async {
                                isProcessing = false
                                
                                if success {
                                    hapticFeedback.notificationOccurred(.success)
                            hasTicket = true
                            isPresented = false
                                } else {
                                    errorMessage = error ?? "Failed to purchase ticket"
                                    showError = true
                                    hapticFeedback.notificationOccurred(.error)
                                }
                            }
                        }
                    }) {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding(.trailing, 8)
                            }
                            Text(isProcessing ? "Processing..." : "Purchase Ticket")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .opacity(isProcessing ? 0.8 : 1)
                    }
                    .disabled(isProcessing)
                }
                .padding() .padding(.bottom,30)
            }
            .background(Color.dynamic)
            .navigationTitle("Purchase Ticket")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.dynamic)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationBarItems(trailing: Button("Cancel") {
                isPresented = false
            }
            .foregroundColor(.white))
           
        }
        .preferredColorScheme(.dark)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
    }
}

struct CreditCardView: View {
    var cardNumber: String
    var cardHolderName: String
    var expiryDate: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "creditcard.fill")
                    .font(.title)
                Spacer()
                Image(systemName: "wave.3.right")
                    .font(.title2)
            }
            .foregroundColor(.white)
            
            // Card Number
            Text(cardNumber.isEmpty ? "•••• •••• •••• ••••" : cardNumber)
                .font(.system(.title2, design: .monospaced))
                .foregroundColor(.white)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CARD HOLDER")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text(cardHolderName.isEmpty ? "YOUR NAME" : cardHolderName.uppercased())
                        .font(.callout)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("EXPIRES")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text(expiryDate.isEmpty ? "MM/YY" : expiryDate)
                        .font(.callout)
                        .foregroundColor(.white)
                }
            }
        }
        .padding(20)
        .padding(.vertical,20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

struct BackCardView: View {
    var cvv: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Black magnetic stripe
            Rectangle()
                .fill(Color.black)
                .frame(height: 50)
                .padding(.top)
            
            // CVV strip
            HStack {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("CVV")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    ZStack(alignment: .trailing) {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 60, height: 30)
                        
                        Text(cvv.isEmpty ? "•••" : cvv)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.trailing, 8)
                    }
                }
                .padding(.trailing)
            }
            
            Spacer()
        }
        .padding(20)
        .padding(.vertical,20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

struct LocationMapView: View {
    let coordinate: CLLocationCoordinate2D
    
    var body: some View {
        Map(coordinateRegion: .constant(MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )), interactionModes: [], annotationItems: [MapPin(coordinate: coordinate)]) { pin in
            MapMarker(coordinate: pin.coordinate, tint: .red)
        }
    }
}

struct MapPin: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

struct ViewEventDetail_Previews: PreviewProvider {
    static var previews: some View {
        ViewEventDetail(event: sampleEvents[0])
            .environmentObject(FirebaseManager.shared)
    }
}

struct RecommendedEventCard: View {
    var event: Event
    let colors: [Color] = [.red, .blue, .green, .orange]
    
    var body: some View {
        VStack(alignment: .leading) {
            // Event Image
            CompactImageViewer(imageUrls: event.images, height: 160 , scroll:false)
                .overlay(
                    VStack {
                        HStack {
                            Spacer()
                            Text(event.type)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                            .foregroundStyle(.linearGradient(colors: [.pink, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .padding(.horizontal,5)
                            .padding(.vertical,2)
                            .background(LinearGradient(colors: [.dynamic.opacity(0.60)], startPoint: .bottom, endPoint: .top))
                            .cornerRadius(15)
                        }
                        Spacer()
                    }.padding()
                )
                .padding(.bottom,-20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Mar 20")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(event.name)
                    .font(.headline)
                    .foregroundStyle(.linearGradient(colors: [colors.randomElement() ?? .blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .lineLimit(1)
                
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.gray)
                    Text("New York")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 12)
            .padding(.top, 12)
            .background(Color.dynamic)
            
        }
       
        .cornerRadius(16)
        .frame(width: 200)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// Private card view for recommended events
private struct RecommendedEventCardView: View {
    let event: Event
    
    var body: some View {
        NavigationLink(destination: ViewEventDetail(event: self.event)) {
            VStack(alignment: .leading, spacing: 8) {
                // Event Image
                if let firstImage = self.event.images.first {
                    AsyncImage(url: URL(string: firstImage)) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .foregroundColor(.gray.opacity(0.2))
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(width: 240, height: 135)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    // Event Type
                    Text(self.event.type)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                    
                    // Event Name
                    Text(self.event.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    // Date and Location
                    HStack(spacing: 8) {
                        // Date
                        Label(self.event.startDate.formatted(date: .abbreviated, time: .shortened),
                              systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Participants
                        Label("\(self.event.participants.count)",
                              systemImage: "person.2")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 8)
            }
            .frame(width: 240)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
} 
