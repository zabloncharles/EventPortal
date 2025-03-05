import SwiftUI
import MapKit

struct CreateEventView: View {
    @State private var messages: [ChatMessage] = []
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
    
    private let questions = [
        "What's the name of your event?",
        "When will the event take place?",
        "Where will the event be held?",
        "Tell me about your event",
        "How many people can attend?",
        "What category best describes your event?"
    ]
    
    private let quickActions = [
        QuickAction(icon: "calendar", text: "Schedule Event", action: .schedule),
        QuickAction(icon: "mappin.and.ellipse", text: "Set Location", action: .location),
        QuickAction(icon: "person.2", text: "Add Participants", action: .participants),
        QuickAction(icon: "tag", text: "Set Category", action: .category),
        QuickAction(icon: "photo", text: "Add Photos", action: .photos),
        QuickAction(icon: "doc.text", text: "Add Description", action: .description)
    ]

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Event Assistant")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        // Show settings
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding()
                .background(Color.black)
                
                // Chat Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // AI Assistant Header
                            if messages.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("AI assistant")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    Text("Hello! Let's create your event.\nWhat would you like to name it?")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.15))
                                .cornerRadius(15)
                            }
                            
                            // Quick Actions
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(quickActions, id: \.text) { action in
                                        QuickActionButton(icon: action.icon, text: action.text)
                                            .onTapGesture {
                                                handleQuickAction(action.action)
                                            }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            ForEach(messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }
                            
                            // Typing indicator
                            if isTyping {
                                HStack {
                                    ChatBubble(message: ChatMessage(content: typingText + "...", isUser: false))
                                }
                                .transition(.opacity)
                            }
                        }
                        .padding(.top)
                        .onChange(of: messages) { _ in
                            withAnimation {
                                if let lastMessage = messages.last {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                
                // Message Input
                VStack(spacing: 0) {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    HStack(spacing: 15) {
                        TextField("Message AI assistant", text: $currentInput)
                            .padding(12)
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
                                    Image(systemName: currentInput.isEmpty ? "mic.fill" : "arrow.up")
                                        .foregroundColor(.white)
                                        .font(.system(size: 20))
                                )
                        }
                    }
                    .padding()
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingDatePicker) {
            DatePickerView(selectedDate: $selectedDate, isPresented: $showingDatePicker) { date in
                eventDetails.date = date
                let formatter = DateFormatter()
                formatter.dateStyle = .long
                formatter.timeStyle = .short
                let dateString = formatter.string(from: date)
                currentInput = dateString
                sendMessage()
            }
        }
        .sheet(isPresented: $showingLocationSearch) {
            LocationSearchView(isPresented: $showingLocationSearch) { location in
                eventDetails.location = location
                currentInput = location
                sendMessage()
            }
        }
        .sheet(isPresented: $showingReview) {
            EventReviewView(eventDetails: eventDetails, selectedImage: selectedImage, isPresented: $showingReview)
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
            addAIResponse("Perfect! Where will the event be held?")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showingLocationSearch = true
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
                addAIResponse("What category best describes your event? (Social, Business, Education, etc.)")
            } else {
                addAIResponse("Please enter a valid number of participants.")
                currentQuestion -= 1
            }
        case 5:
            eventDetails.category = EventCategory(rawValue: input.lowercased()) ?? .social
            addAIResponse("Great! I've got all the details. Would you like to review your event or make any changes?")
        default:
            handleFinalSteps(input)
        }
        currentQuestion += 1
    }
    
    private func addAIResponse(_ response: String, showCalendarAfter: Bool = false) {
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showingDatePicker = true
                    }
                }
            }
        }
    }
    
    private func handleQuickAction(_ action: QuickActionType) {
        switch action {
        case .schedule:
            addAIResponse("Let's schedule your event! When would you like it to take place?", showCalendarAfter: true)
        case .location:
            addAIResponse("Let's set the location for your event!", showCalendarAfter: false)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showingLocationSearch = true
            }
        case .participants:
            addAIResponse("How many people can attend this event?")
        case .category:
            addAIResponse("What category best describes your event? Available categories are: Social, Business, Education, Sports, Cultural")
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
}

struct DatePickerView: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    var onDateSelected: (Date) -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()
                
                Button("Done") {
                    onDateSelected(selectedDate)
                    isPresented = false
                }
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
                .padding()
            }
            .navigationTitle("Select Date & Time")
            .navigationBarItems(trailing: Button("Cancel") {
                isPresented = false
            })
        }
        .preferredColorScheme(.dark)
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
    var category: EventCategory = .social
}

struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            
            Text(message.content)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(message.isUser ? Color.purple.opacity(0.8) : Color.gray.opacity(0.15))
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
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
            Text(text)
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .foregroundColor(.white)
        .frame(width: 100, height: 80)
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
}

struct CreateEventView_Previews: PreviewProvider {
    static var previews: some View {
        CreateEventView()
    }
}

struct EventReviewView: View {
    let eventDetails: EventDetails
    let selectedImage: UIImage?
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Event Image
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                    
                    // Event Details
                    VStack(alignment: .leading, spacing: 20) {
                        ReviewSection(title: "Event Name", content: eventDetails.title)
                        
                        ReviewSection(title: "Date & Time", content: formatDate(eventDetails.date))
                        
                        ReviewSection(title: "Location", content: eventDetails.location)
                        
                        ReviewSection(title: "Description", content: eventDetails.description)
                        
                        ReviewSection(title: "Maximum Participants", content: "\(eventDetails.maxParticipants)")
                        
                        ReviewSection(title: "Category", content: eventDetails.category.rawValue.capitalized)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(15)
                    
                    // Action Buttons
                    HStack(spacing: 16) {
                        Button(action: {
                            isPresented = false
                        }) {
                            Text("Make Changes")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.3))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        
                        Button(action: {
                            // TODO: Submit event
                            isPresented = false
                        }) {
                            Text("Submit Event")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.purple, .blue]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.top)
                }
                .padding()
            }
            .navigationTitle("Event Review")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Close") {
                isPresented = false
            })
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

struct ReviewSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text(content)
                .font(.body)
                .foregroundColor(.white)
        }
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
        ZStack {
            VStack {
                if !isFocused {
                    // Note: You'll need to add the LottieView and animation file
                    Image(systemName: "location.fill.viewfinder")
                        .frame(height: 200)
                        .padding(.top, 30)
                        .padding(.bottom, 10)
                        .font(.largeTitle)
                }
                
                HStack {
                    Text("Add an address for Your Event")
                        .font(.title3)
                        .padding(.bottom, 3)
                    Image(systemName: "info.circle")
                }
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.purple, .blue]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .fontWeight(.bold)
                .multilineTextAlignment(isFocused ? .leading : .center)
                .padding(.bottom, 5)
                
                Text("Provide the location details where your event will take place. This can include the venue name, street address, city, state, and zip code to ensure attendees can easily find and navigate to your event location")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(isFocused ? .leading : .center)
                    .padding(.horizontal, isFocused ? 0 : 25)
                
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
                                    VStack {
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
                .onAppear {
                    isFocused = false
                }
            }
        }
        .navigationBarHidden(showMap)
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


