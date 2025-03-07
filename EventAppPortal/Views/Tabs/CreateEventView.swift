import SwiftUI
import MapKit

// MARK: - Models
enum EventTimingType {
    case ongoing
    case timed
}

let eventTypes: [String] = [
    "Corporate",
    "Concert",
    "Marketing",
    "Health & Wellness",
    "Technology",
    "Art & Culture",
    "Charity",
    "Literature",
    "Lifestyle",
    "Environmental",
    "Entertainment"
]

let typeSymbols: [String: String] = [
    "Concert": "figure.dance",
    "Corporate": "building.2.fill",
    "Marketing": "megaphone.fill",
    "Health & Wellness": "heart.fill",
    "Technology": "desktopcomputer",
    "Art & Culture": "paintbrush.fill",
    "Charity": "heart.circle.fill",
    "Literature": "book.fill",
    "Lifestyle": "leaf.fill",
    "Environmental": "leaf.arrow.triangle.circlepath",
    "Entertainment": "music.note.list"
]

struct CreateEventView: View {
    @State private var messages: [ChatMessage] = [
        ChatMessage(content: "Hello! Let's create your event.\nWhat would you like to name it?", isUser: false)
    ]
    @StateObject private var tabBarManager = TabBarVisibilityManager.shared
    @State private var currentInput = ""
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var currentQuestion = 0
    @State private var eventDetails = EventDetails()
    @State private var isRecording = false
    @State private var showingDatePicker = false
    @State private var selectedDate = Date()
    @State private var showingReview = false
    @State private var isTyping = false
    @State private var typingText = ""
    @State private var scrollProxy: ScrollViewProxy? = nil
    @State private var showingLocationSearch = false
    @State private var quickActionButtonTapped = false
    @State private var showingCategoryPicker = false
    
    // Add computed property for live preview event
    private var previewEvent: Event {
        Event(
            name: eventDetails.title.isEmpty ? "Your Event Name" : eventDetails.title,
            description: eventDetails.description.isEmpty ? "Add a description of your event" : eventDetails.description,
            type: eventDetails.category,
            views: "0",
            location: eventDetails.location.isEmpty ? "Set event location" : eventDetails.location,
            price: "Free",
            owner: "Current User",
            startDate: eventDetails.date,
            endDate: eventDetails.date.addingTimeInterval(7200),
            images: ["bg1"],
            participants: Array(repeating: "Participant", count: eventDetails.maxParticipants),
            isTimed: true,
            createdAt: Date(),
            coordinates: []
        )
    }

    private let questions = [
        "What's the name of your event?",
        "When will the event take place?",
        "Where will the event be held?",
        "Tell me about your event",
        "How many people can attend?",
        "What category best describes your event?"
    ]
    
    private let quickActions = [
        QuickAction(icon: "calendar", text: "Schedule Event", action: .schedule, 
                   description: "Set the date and time for your event", 
                   iconColor: .orange),
        QuickAction(icon: "mappin.and.ellipse", text: "Set Location", action: .location, 
                   description: "Choose where your event will take place", 
                   iconColor: .blue),
        QuickAction(icon: "person.2", text: "Add Participants", action: .participants, 
                   description: "Set the number of attendees for your event", 
                   iconColor: .green),
        QuickAction(icon: "tag", text: "Set Category", action: .category, 
                   description: "Classify your event type and theme", 
                   iconColor: .purple),
        QuickAction(icon: "photo", text: "Add Photos", action: .photos, 
                   description: "Add images to showcase your event", 
                   iconColor: .red),
        QuickAction(icon: "doc.text", text: "Add Description", action: .description, 
                   description: "Write details about your event", 
                   iconColor: .cyan)
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Header
                    VStack(alignment: .leading) {
                        
                        HStack {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text("Let's create your event!")
                                        .font(.title3)
                                    
                                        .foregroundStyle(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.purple, .blue]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                    )
                                    Spacer()
                                    
                                    NavigationLink(destination: QuickActionsView { action in
                                        handleQuickAction(action)
                                    }) {
                                        Image(systemName: "text.badge.plus")
                                            .font(.title2)
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                }
                                Text("Provide the name of your event.")
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            
                        }
                        
                        
                    } .fontWeight(.bold)
                        .padding(.horizontal)
                        .padding(.top,20)
                        .multilineTextAlignment(.leading)
                   
                    
                        
                        
                                
                                   
                           
                    // Quick Actions
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(quickActions, id: \.text) { action in
//                                QuickActionButton(
//                                    icon: action.icon,
//                                    text: action.text,
//                                    description: action.description,
//                                    iconColor: action.iconColor
//                                )
                                HStack {
                                    Image(systemName: action.icon)
                                    Text(action.text)
                                    
                                } .foregroundColor(action.iconColor)
                                    .padding(.vertical,10)
                                    .padding(.horizontal,10)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(10)
                                    .scaleEffect(quickActionButtonTapped ? 0.97 : 1)
                                    .onTapGesture {
                                        //animate button tap
                                        quickActionButtonTappedAnimationFunc()
                                        handleQuickAction(action.action)
                                
                                }
                            }
                        }
                        .padding(.horizontal)
                    }.padding(.top,5)
                    
                    //event at before chat bubble that update the information being inputed so the user can have a visual of what the card will look like when it's done
                    RegularEventCard(event: previewEvent)
                        .padding()
                        .frame(height: 200)
                        .padding(.top)
                    
                    
                    // Chat Messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                              
                                Spacer()
                                ForEach(messages) { message in
                                    ChatBubble(message: message)
                                        .id(message.id)
                                }
                                
                                // Typing indicator
                                if isTyping {
                                    HStack {
                                        ChatBubble(message: ChatMessage(content: typingText + "|", isUser: false))
                                            .id("typing")
                                    }
                                    .transition(.opacity)
                                }
                                
                                // Spacer at the bottom to ensure content can scroll up
                                Color.clear
                                    .frame(height: 1)
                                    .id("bottom")
                            }
                            .padding(.top)
                        }
                        .onChange(of: messages) { _ in
                            withAnimation(.spring()) {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                        .onChange(of: typingText) { _ in
                            withAnimation(.spring()) {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                        .onAppear {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                    .scrollDisabled(false)
                    .scrollDismissesKeyboard(.immediately)
                    .scrollIndicators(.hidden)
                    
                    // Message Input
                    VStack(spacing: 0) {
                        Divider()
                            .background(Color.gray.opacity(0.3))
                        
                        VStack {
                           
                                HStack(spacing: 15) {
                                    TextField("Message AI assistant", text: $currentInput)
                                        .padding(12)
                                        .padding(.leading, 5)
                                        .background(Color.gray.opacity(0.15))
                                        .cornerRadius(25)
                                        .foregroundColor(.white)
                                        .onSubmit {
                                            sendMessage()
                                        }
                                    
                                    Button(action: {
                                        sendMessage()
                                    }) {
                                        Circle()
                                            .fill(LinearGradient(gradient: Gradient(colors: [.purple, .blue]), startPoint: .topLeading, endPoint: .bottomTrailing))
                                            .frame(width: 45, height: 45)
                                            .overlay(
                                                Image(systemName: currentInput.isEmpty ? "face.dashed" : "arrow.up")
                                                    .foregroundColor(.white)
                                                    .font(.system(size: 20))
                                            )
                                    }
                                }
                                .padding()
                            
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
      
        .fullScreenCover(isPresented: $showingDatePicker) {
            DatePickerView(selectedDate: $selectedDate, isPresented: $showingDatePicker, eventDetails: eventDetails) { date in
                eventDetails.date = date
                let formatter = DateFormatter()
                formatter.dateStyle = .long
                formatter.timeStyle = .short
                let dateString = formatter.string(from: date)
                currentInput = dateString
                sendMessage()
            }
        }
        .fullScreenCover(isPresented: $showingLocationSearch) {
            LocationSearchView(isPresented: $showingLocationSearch) { location in
                eventDetails.location = location
                currentInput = location
                sendMessage()
            }
        }
        .fullScreenCover(isPresented: $showingReview) {
            EventReviewView(eventDetails: eventDetails, selectedImage: selectedImage, isPresented: $showingReview)
        }
        .fullScreenCover(isPresented: $showingCategoryPicker) {
            CategorySelectionView(isPresented: $showingCategoryPicker) { category in
                currentInput = category
                sendMessage()
            }
        }
        .onAppear {
            tabBarManager.hideTab = true
        }
        .onDisappear {
            tabBarManager.hideTab = false
        }
    }
    private func quickActionButtonTappedAnimationFunc(){
        withAnimation(.spring()) {
            quickActionButtonTapped = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring()) {
                quickActionButtonTapped = false
            }
        }
        
    }
    private func sendMessage() {
        guard !currentInput.isEmpty else { return }
        let userMessage = ChatMessage(content: currentInput, isUser: true)
        messages.append(userMessage)
        
        // Process user input and update event details
        processUserInput(currentInput)
        
        // Clear input
        currentInput = ""
    }
    
    private func processUserInput(_ input: String) {
        switch currentQuestion {
        case 0:
            eventDetails.title = input
            addAIResponse("Great name! When would you like to hold the event?", showCalendarAfter: true)
        case 1:
            eventDetails.date = parseDate(input) ?? Date()
            addAIResponse("Perfect! Where will the event be held?") { [self] in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showingLocationSearch = true
                }
            }
        case 2:
            eventDetails.location = input
            addAIResponse("Tell me more about what this event is about.")
        case 3:
            eventDetails.description = input
            addAIResponse("How many people can attend this event?")
        case 4:
            if let participants = Int(input) {
                eventDetails.maxParticipants = participants
                showingCategoryPicker = true
            } else {
                addAIResponse("Please enter a valid number of participants.")
                currentQuestion -= 1
            }
        case 5:
            eventDetails.category = input
            addAIResponse("Great! I've got all the details. Would you like to review your event or make any changes?") { [self] in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) {
                    showingReview = true
                }
            }
        default:
            handleFinalSteps(input)
        }
        currentQuestion += 1
    }
    
    private func addAIResponse(_ response: String, showCalendarAfter: Bool = false, completion: (() -> Void)? = nil) {
        isTyping = true
        typingText = ""
        
        let characters = Array(response)
        var charIndex = 0
        let typingInterval = 0.05
        let totalTypingTime = Double(characters.count) * typingInterval
        
        Timer.scheduledTimer(withTimeInterval: typingInterval, repeats: true) { timer in
            if charIndex < characters.count {
                typingText += String(characters[charIndex])
                charIndex += 1
            } else {
                timer.invalidate()
                isTyping = false
                let aiMessage = ChatMessage(content: response, isUser: false)
                messages.append(aiMessage)
                
                // Show calendar after message is complete and a small delay
                if showCalendarAfter {
                    // Add a longer delay after typing is complete
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        showingDatePicker = true
                    }
                }
                
                // Call completion handler if provided
                completion?()
            }
        }
    }
    
    private func handleQuickAction(_ action: QuickActionType) {
        switch action {
        case .schedule:
            addAIResponse("Let's schedule your event! When would you like it to take place?", showCalendarAfter: true)
        case .location:
            addAIResponse("Let's set the location for your event!") { [self] in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showingLocationSearch = true
                }
            }
        case .participants:
            addAIResponse("How many people can attend this event?")
        case .category:
            showingCategoryPicker = true
        case .photos:
            showImagePicker = true
        case .description:
            addAIResponse("Tell me more about what this event is about.")
        }
    }
    
    private func handleFinalSteps(_ input: String) {
        if input.lowercased().contains("review") {
            showingReview = true
        } else if input.lowercased().contains("submit") {
            // TODO: Handle event submission
            addAIResponse("Event has been created successfully! You can view it in the events list.")
        } else {
            addAIResponse("Would you like to review the event details or submit the event?")
        }
    }
    
    private func parseDate(_ input: String) -> Date? {
        // Add date parsing logic
        return Date()
    }
}

enum QuickActionType {
    case schedule, location, participants, category, photos, description
}

struct QuickAction {
    let icon: String
    let text: String
    let action: QuickActionType
    let description: String
    let iconColor: Color
}

struct DatePickerView: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    let eventDetails: EventDetails
    var onDateSelected: (Date) -> Void
    @State private var previewEvent: Event
    
    init(selectedDate: Binding<Date>, isPresented: Binding<Bool>, eventDetails: EventDetails, onDateSelected: @escaping (Date) -> Void) {
        self._selectedDate = selectedDate
        self._isPresented = isPresented
        self.eventDetails = eventDetails
        self.onDateSelected = onDateSelected
        
        // Create a temporary formatter for initialization
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        let dateString = formatter.string(from: selectedDate.wrappedValue)
        
        // Initialize the preview event
        let initialEvent = Event(
            name: eventDetails.title.isEmpty ? "New Event" : eventDetails.title,
            description: eventDetails.description.isEmpty ? "Event has no description yet!" : eventDetails.description,
            type: eventDetails.category,
            views: "0",
            location: eventDetails.location.isEmpty ? "Location TBD" : eventDetails.location,
            price: "Free",
            owner: "Current User",
            startDate: selectedDate.wrappedValue,
            endDate: selectedDate.wrappedValue.addingTimeInterval(7200),
            images: ["bg1"],
            participants: Array(repeating: "Participant", count: eventDetails.maxParticipants),
            isTimed: true,
            createdAt: Date(),
            coordinates: []
        )
        self._previewEvent = State(initialValue: initialEvent)
    }
    
    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators:false) {
                    ZStack {
                        Color.dynamic.edgesIgnoringSafeArea(.all)
                        
                        VStack(alignment: .leading, spacing: 20) {
                            VStack(alignment: .leading) {
                             
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Select a date and time")
                                                .font(.title3)
                                             
                                        .foregroundStyle(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.purple, .blue]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        Text("Provide the date and time that the event take place")
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                   
                                }
                               
                                
                            } .fontWeight(.bold)
                                .padding(.horizontal)
                                .padding(.top,20)
                                .multilineTextAlignment(.leading)
                            
                          
                                
                           
                            
                            DatePicker("Select Date", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(GraphicalDatePickerStyle())
                                .padding()
                                .background(.gray.opacity(0.10))
                                .cornerRadius(19)
                                .padding()
                                .onChange(of: selectedDate) { newValue in
                                    previewEvent = Event(
                                        name: eventDetails.title.isEmpty ? "New Event" : eventDetails.title,
                                        description: eventDetails.description.isEmpty ? "Event has no description yet!" : eventDetails.description,
                                        type: eventDetails.category,
                                        views: "0",
                                        location: eventDetails.location.isEmpty ? "Location TBD" : eventDetails.location,
                                        price: "Free",
                                        owner: "Current User",
                                        startDate: newValue,
                                        endDate: newValue.addingTimeInterval(7200),
                                        images: ["bg1"],
                                        participants: Array(repeating: "Participant", count: eventDetails.maxParticipants),
                                        isTimed: true,
                                        createdAt: Date(),
                                        coordinates: []
                                    )
                                    
                                    withAnimation(.spring()) {
                                        proxy.scrollTo("bottom", anchor: .bottom)
                                    }
                                }
                            
                            Text("Done")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.purple, .blue]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .onTapGesture(perform: {
                                onDateSelected(selectedDate)
                                isPresented = false
                            })
                            .padding()
                            .id("bottom")
                        }
                    }.navigationTitle("Select Date")
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarItems(trailing: Button("Cancel") {
                        isPresented = false
                    }).padding(.bottom,20)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let content: String
    let isUser: Bool
    
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id && lhs.content == rhs.content && lhs.isUser == rhs.isUser
    }
}

struct EventDetails {
    var title = ""
    var date = Date()
    var location = ""
    var description = ""
    var maxParticipants = 0
    var category: String = eventTypes[0]
}

struct CategorySelectionView: View {
    @Binding var isPresented: Bool
    let onCategorySelected: (String) -> Void
    
    let typeColors: [String: Color] = [
        "Concert": .purple,
        "Corporate": .blue,
        "Marketing": .orange,
        "Health & Wellness": .red,
        "Technology": .cyan,
        "Art & Culture": .pink,
        "Charity": .red,
        "Literature": .brown,
        "Lifestyle": .green,
        "Environmental": .green,
        "Entertainment": .purple
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Select Event Category")
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple, .blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .fontWeight(.bold)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    Text("Choose a category that best describes your event")
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 15) {
                        ForEach(eventTypes, id: \.self) { type in
                            Button(action: {
                                onCategorySelected(type)
                                isPresented = false
                            }) {
                                HStack {
                                    Image(systemName: typeSymbols[type] ?? "questionmark")
                                        .font(.system(size: 16))
                                    Text(type)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                }
                                .foregroundColor(typeColors[type] ?? .white)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(typeColors[type] ?? .white, lineWidth: 1)
                                        .opacity(0.3)
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationBarItems(trailing: Button("Cancel") {
                isPresented = false
            })
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.black.edgesIgnoringSafeArea(.all))
        }
        .preferredColorScheme(.dark)
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            
            Text(message.content)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(message.isUser ? Color.blue.opacity(0.8) : Color.gray.opacity(0.09))
                .foregroundColor(.white)
                .cornerRadius(20)
                .padding(.horizontal, 16)
            
            if !message.isUser { Spacer() }
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let text: String
    let description: String
    let iconColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(iconColor)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(text)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.systemGray6).opacity(0.2))
        .cornerRadius(16)
    }
}

struct SimpleQuickActionButton: View {
    let icon: String
    let text: String
    let iconColor: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(text)
        }
        .foregroundColor(iconColor)
        .padding(.vertical, 10)
        .padding(.horizontal, 10)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .scaleEffect(isPressed ? 0.97 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onTapGesture {
            // Animate button tap
            withAnimation {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
            }
            action()
        }
    }
}

struct CreateEventView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CreateEventView()
            
            // Preview for EventReviewView
            EventReviewView(
                eventDetails: EventDetails(
                    title: "Sample Event",
                    date: Date(),
                    location: "123 Main St, San Francisco",
                    description: "This is a sample event description",
                    maxParticipants: 50,
                    category: "Entertainment"
                ),
                selectedImage: nil,
                isPresented: .constant(true)
            ) .preferredColorScheme(.dark)
        }
       
    }
}

struct ReviewSection: View {
    let title: String
    let content: String
    let isLarge: Bool
    
    init(title: String, content: String, isLarge: Bool = false) {
        self.title = title
        self.content = content
        self.isLarge = isLarge
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.gray)
            Text(content)
                .font(.system(size: isLarge ? 40 : 18, weight: isLarge ? .bold : .medium))
                .foregroundColor(.black)
        }
        
        .padding(.vertical, 8)
    }
}

struct EventReviewView: View {
    let eventDetails: EventDetails
    let selectedImage: UIImage?
    @Binding var isPresented: Bool
    @State private var isLoading = false
    @State private var showSuccess = false
    
    // Add computed property for preview event
    private var previewEvent: Event {
        Event(
            name: eventDetails.title,
            description: eventDetails.description,
            type: eventDetails.category,
            views: "0",
            location: eventDetails.location,
            price: "Free",
            owner: "Current User",
            startDate: eventDetails.date,
            endDate: eventDetails.date.addingTimeInterval(7200),
            images: ["bg1"],
            participants: Array(repeating: "Participant", count: eventDetails.maxParticipants),
            isTimed: true,
            createdAt: Date(),
            coordinates: []
        )
    }
    
    // Add computed property for map region
    private var region: MKCoordinateRegion {
        // Try to parse coordinates from location string
        let components = eventDetails.location.components(separatedBy: ", ")
        if components.count >= 2 {
            let lastTwoComponents = Array(components.suffix(2))
            if let lat = Double(lastTwoComponents[0]),
               let lon = Double(lastTwoComponents[1]) {
                return MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            }
        }
        // Default to San Francisco if no valid coordinates
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }
    
    private func formatTimeOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background Map
                Map(coordinateRegion: .constant(region),
                    annotationItems: [MapPin(coordinate: region.center)]) { pin in
                    MapMarker(coordinate: pin.coordinate, tint: .blue)
                }
                .edgesIgnoringSafeArea(.all)
                .blur(radius: 5)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Event Details Card
                        VStack(spacing: 0) {
                            // Header with Logo and Category
                            VStack(spacing: 16) {
                                Image(systemName: typeSymbols[eventDetails.category] ?? "calendar")
                                    .font(.system(size: 40))
                                    .frame(width: 80, height: 80)
                                    .background(Circle().fill(Color.blue))
                                
                                Text(eventDetails.title)
                                    .font(.title2)
                                
                                Text(eventDetails.category)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color.dynamic)
                            
                            // Time Section
                            HStack(spacing: 40) {
                                VStack(alignment: .center) {
                                    Text(formatTimeOnly(eventDetails.date))
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundColor(.black)
                                    Text("Start")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Image(systemName: "arrow.right")
                                    .font(.title2)
                                    .foregroundColor(Color.invert)
                                
                                VStack(alignment: .center) {
                                    Text(formatTimeOnly(eventDetails.date.addingTimeInterval(7200)))
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundColor(Color.invert)
                                    Text("End")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color.dynamic)
                            
                            Divider().background(Color.gray.opacity(0.3))
                            
                            // Location and Details Grid
                            VStack(alignment: .leading) {
                                HStack {
                                    ReviewSection(title: "Location", content: eventDetails.location)
                                    Spacer()
                                    ReviewSection(title: "Participants", content: "\(eventDetails.maxParticipants)")
                                }
                                HStack {
                                    ReviewSection(title: "Description", content: eventDetails.description)
                                        .lineLimit(2)
                                    
                                }
                                
                            }
                            .padding()
                            .background(Color.dynamic)
                            
                            Divider().background(Color.gray.opacity(0.3))
                            
                            
                            if !showSuccess {
                                // Additional Options
                                VStack(alignment: .center, spacing: 16) {
                                  
                                    
                                    HStack {
                                        
                                        Text("Location Details")
                                        Image(systemName: "map")
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                         
                                    }
                                    
                                    HStack {
                                        
                                        Text("Event Details")
                                        Image(systemName: "doc.text")
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                    }
                                }
                                .foregroundColor(Color.invert)
                                .padding()
                                .background(Color.dynamic)
                                .transition(.move(edge: .top).combined(with: .opacity))
                            } else {
                           
                               // Success View Overlay
                                VStack(spacing: 25) {
                                    // Animated success checkmark
                                    ZStack {
                                        
                                        
                                        Circle()
                                            .trim(from: 0, to: 1)
                                            .stroke(Color.green, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                            .frame(width: 50, height: 50)
                                            .rotationEffect(.degrees(-90))
                                            .animation(.easeOut(duration: 1), value: showSuccess)
                                        
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 30, weight: .bold))
                                            .foregroundColor(.green)
                                            .scaleEffect(showSuccess ? 1 : 0)
                                            .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.4), value: showSuccess)
                                    }
                                    
                                    VStack(spacing: 12) {
                                        Text("Event Created!")
                                            .font(.title)
                                            .fontWeight(.bold)
                                        
                                        Text("Your event has been successfully created")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                            .multilineTextAlignment(.center)
                                    }
                                    .offset(y: showSuccess ? 0 : 20)
                                    .opacity(showSuccess ? 1 : 0)
                                    .animation(.easeOut(duration: 0.6).delay(0.2), value: showSuccess)
                                    
                                    // Confetti effect or additional animation could be added here
                                }
                                .padding(.horizontal, 40)
                                .padding()
                                .background(Color.dynamic)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                            
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .shadow(radius: 10)
                        
                       

                        // Action Button
                        Button(action: {
                            // Dismiss after showing success
                            if showSuccess {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                    withAnimation {
                                        isPresented = false
                                    }
                                    return
                                }
                            }
                            withAnimation {
                                isLoading = true
                            }
                            
                            // Simulate network request
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation(.spring()) {
                                    isLoading = false
                                    showSuccess = true
                                }
                                
                               
                            }
                        }) {
                            HStack(spacing: 15) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 20, weight: .semibold))
                                    Text(showSuccess ? "Close" : "Create Event")
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [isLoading ? .gray : .purple, isLoading ? .gray.opacity(0.8) : .blue]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .shadow(color: isLoading ? .clear : .purple.opacity(0.3),
                                    radius: 10, x: 0, y: 5)
                            .opacity(isLoading ? 0.8 : 1)
                            .scaleEffect(isLoading ? 0.98 : 1)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isLoading)
                        }
                        .disabled(isLoading || showSuccess)
                        .padding(.top)
                        .padding(.horizontal, 20)
                    }
                    .padding()
                }
            }
            .navigationTitle("Event Pass")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Close") {
                isPresented = false
            })
        }
        .preferredColorScheme(.light)
    }
}

struct LocationSearchView: View {
    @Binding var isPresented: Bool
    @StateObject private var completer = SearchCompleter()
    @State private var searchText = ""
    @State private var showMap = false
    @State private var confirmed = false
    @FocusState private var isFocused: Bool
    
    let onLocationSelected: (String) -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.dynamic
                    .edgesIgnoringSafeArea(.all)
                VStack {
                    if !isFocused {
                        LottieView(filename:"locationbubble", loop: true)
                            .frame(height: 200)
                            .padding(.top, 30)
                            .padding(.bottom, 10)
                            .overlay {
                                Image(systemName: "location.fill.viewfinder")
                                    .font(.largeTitle)
                                    .foregroundColor(.white)
                            }
                    }
                    
                   
                    VStack(alignment: isFocused ? .leading : .center) {
                        Text("Add an address for Your Event")
                                .font(.title3)
                                .padding(.bottom, 3)
                        
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple, .blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .fontWeight(.bold)
                        .multilineTextAlignment(isFocused ? .leading : .center)
                        .padding(.bottom, isFocused ? 0 : 5)
                    .padding(.top,20)
                        
                        Text("Provide the location details where your event will take place. This can include the venue name, street address, city, state, and zip code to ensure attendees can easily find and navigate to your event location")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(isFocused ? .leading : .center)
                            .padding(.horizontal, isFocused ? 0 : 25)
                    }
                    
                    
                    
                    TextField("Enter Address", text: $searchText)
                        .focused($isFocused)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white, lineWidth: 1)
                        )
                        .padding()
                        .onChange(of: searchText) { newValue in
                            completer.search(text: newValue)
                        }
                    
                    if !completer.searchResults.isEmpty {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 12) {
                                ForEach(completer.searchResults.prefix(3), id: \.self) { result in
                                    Button(action: {
                                        searchLocation(result)
                                    }) {
                                        VStack(alignment: .center) {
                                            Divider()
                                            Text(result.title + ", " + result.subtitle)
                                                .font(.callout)
                                                .foregroundColor(.primary)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                    }
                                    .padding(.vertical, 7)
                                    .padding(.horizontal, 10)
                                    .cornerRadius(9)
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, isFocused ? 25 : 0)
                .animation(.spring(), value: isFocused)
                
                if showMap {
                    Rectangle()
                        .fill(Color.black.opacity(0.85))
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack {
                        Text(confirmed ? "You have chosen \(completer.selectedAddress)" : "Please confirm the location of the event on the map below.")
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Divider()
                        
                        if let region = completer.region {
                            Map(coordinateRegion: .constant(region),
                                annotationItems: [MapPin(coordinate: region.center)]) { pin in
                                MapMarker(coordinate: pin.coordinate, tint: .blue)
                            }
                            .frame(height: 500)
                        }
                        
                        Divider()
                        
                        if !confirmed {
                            HStack {
                                Button("Back") {
                                    withAnimation(.spring()) {
                                        showMap = false
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.3))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                
                                Button("Confirm") {
                                    confirmed = true
                                    onLocationSelected(completer.selectedAddress)
                                    isPresented = false
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.purple, .blue]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                    .background(Color.dynamic)
                    
                   
                    .onAppear {
                        isFocused = false
                    }
                }
            }.navigationTitle("Select Location")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(trailing: Button("Cancel") {
                    isPresented = false
                })
        }
      
    }
    
    private func searchLocation(_ result: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = result.title + ", " + result.subtitle
        
        MKLocalSearch(request: searchRequest).start { response, error in
            guard let mapItem = response?.mapItems.first else { return }
            
            if let coordinate = mapItem.placemark.location?.coordinate {
                completer.region = MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
                
                // Update the selected address with coordinates
                let coordinates = "\(coordinate.latitude), \(coordinate.longitude)"
                completer.selectedAddress = [
                    mapItem.name,
                    mapItem.placemark.locality,
                    coordinates
                ].compactMap { $0 }.joined(separator: ", ")
            }
            
            withAnimation(.spring()) {
                showMap = true
            }
        }
    }
}

class SearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    private let searchCompleter = MKLocalSearchCompleter()
    @Published var searchResults: [MKLocalSearchCompletion] = []
    @Published var error: Error?
    @Published var region: MKCoordinateRegion?
    @Published var selectedAddress: String = ""
    
    override init() {
        super.init()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.address, .pointOfInterest]
    }
    
    func search(text: String) {
        if text.isEmpty {
            searchResults = []
            return
        }
        searchCompleter.queryFragment = text
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.searchResults = completer.results
            self.error = nil
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.searchResults = []
            self.error = error
        }
    }
}

struct QuickActionsView: View {
    let onActionSelected: (QuickActionType) -> Void
    @Environment(\.dismiss) private var dismiss
    
    private let quickActions = [
        QuickAction(icon: "calendar", text: "Schedule", action: .schedule, 
                   description: "Set the date and time for your event", 
                   iconColor: .orange),
        QuickAction(icon: "mappin.and.ellipse", text: "Location", action: .location, 
                   description: "Choose where your event will take place", 
                   iconColor: .blue),
        QuickAction(icon: "person.2", text: "Participants", action: .participants, 
                   description: "Set the number of attendees for your event", 
                   iconColor: .green),
        QuickAction(icon: "tag", text: "Category", action: .category, 
                   description: "Classify your event type and theme", 
                   iconColor: .purple),
        QuickAction(icon: "photo", text: "Photos", action: .photos, 
                   description: "Add images to showcase your event", 
                   iconColor: .red),
        QuickAction(icon: "doc.text", text: "Description", action: .description, 
                   description: "Write details about your event", 
                   iconColor: .cyan)
    ]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: [
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(quickActions, id: \.text) { action in
                    QuickActionButton(
                        icon: action.icon,
                        text: action.text,
                        description: action.description,
                        iconColor: action.iconColor
                    )
                    .onTapGesture {
                        onActionSelected(action.action)
                        dismiss()
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Quick Actions")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}


