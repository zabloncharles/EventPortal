import SwiftUI
import MapKit
import PhotosUI
import FirebaseStorage
import Photos

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

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
    @State private var messages: [ChatMessage] = []
    @StateObject private var tabBarManager = TabBarVisibilityManager.shared
    @EnvironmentObject private var firebaseManager: FirebaseManager
    @State private var currentInput = ""
    @State private var animatedPlaceholder = ""
    @State private var isTypingPlaceholder = true
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
    @State private var placeholderTimer: Timer?
    @State private var shouldAnimatePlaceholder = true
    @State private var clearMessages = false
    @Environment(\.dismiss) private var dismiss
    @State private var selectedImages: [UIImage] = []
    @State private var selectedImageItems: [PhotosPickerItem] = []
    @State private var uploadedImageURLs: [String] = []
    @State private var isUploadingImages = false
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    // Add computed property for live preview event
    private var previewEvent: Event {
        let ownerName: String = {
            if let user = firebaseManager.currentUser {
                return user.displayName ?? user.email ?? "Anonymous"
            }
            return "Anonymous"
        }()
        
        return Event(
            name: eventDetails.title,
            description: eventDetails.description,
            type: eventDetails.category,
            views: "0",
            location: eventDetails.location,
            price: "Free",
            owner: ownerName,
            startDate: eventDetails.date,
            endDate: eventDetails.date.addingTimeInterval(7200),
            images: eventDetails.images.isEmpty ? ["bg1"] : eventDetails.images,
            participants: Array(repeating: "Participant", count: eventDetails.maxParticipants),
            isTimed: true,
            createdAt: Date(),
            coordinates: eventDetails.coordinates,
            status: "active"
        )
    }

    private let questions = [
        "What would you like to call your event?",
        "When were you planning to have this event?",
        "Where will the event be held?",
        "What is this event about?",
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

    private let placeholderText = "My event is called..."

    var body: some View {
        NavigationView {
            ZStack {
                Color.dynamic.edgesIgnoringSafeArea(.all)
                
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
                    }
                    .simultaneousGesture(DragGesture().onChanged { _ in
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    })
                    .padding(.top,5)
                    
//                    //event at before chat bubble that update the information being inputed so the user can have a visual of what the card will look like when it's done
//                    RegularEventCard(event: previewEvent)
//                        .padding()
//                        .frame(height: 200)
//                        .padding(.top)
                    
                    
                    // Image Preview Section
                    if !selectedImages.isEmpty {
                        selectedImagesPreview
                        .padding(.top)
                    }
                    
                    if isUploadingImages {
                        ProgressView("Uploading images...")
                            .padding()
                    }
                    
                    // Chat Messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                              
                               
                                ForEach(messages) { message in
                                    ChatBubble(message: message)
                                        .id(message.id)
                                }
                                
                                // Typing indicator
                                if isTyping {
                                    HStack {
                                        TypingBubbleView()
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
                        .simultaneousGesture(DragGesture().onChanged { _ in
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        })
                        .onChange(of: messages) { _ in
                            generateHapticFeedback()
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        .onChange(of: currentQuestion) { _ in
                            generateHapticFeedback()
                            withAnimation(.spring()) {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                        .onChange(of: clearMessages) { _ in
                            generateHapticFeedback()
                            dismiss()
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
                        if showImagePicker {
                            PhotosPicker(
                                selection: $selectedImageItems,
                                maxSelectionCount: 3,
                                matching: .images
                            ) {
                                HStack {
                                    Image(systemName: "photo.stack")
                                    Text("\(selectedImages.count)/3 Images")
                                }
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                            }
                            .onChange(of: selectedImageItems) { newItems in
                                Task {
                                    selectedImages = []
                                    for item in newItems {
                                        if let data = try? await item.loadTransferable(type: Data.self),
                                           let image = UIImage(data: data) {
                                            selectedImages.append(image)
                                        }
                                    }
                                    
                                    if !selectedImages.isEmpty {
                                        // Proceed directly to review
                                        handleFinalSteps("")
                                        showImagePicker = false // Hide the picker after selection
                                    }
                                }
                            }
                            .padding(.bottom)
                        }
                        
                        Divider()
                            .background(Color.gray.opacity(0.2))
                        
                        VStack {
                                HStack(spacing: 15) {
                                TextField(animatedPlaceholder, text: $currentInput)
                                        .padding(12)
                                        .padding(.leading, 5)
                                        .background(Color.gray.opacity(0.15))
                                        .cornerRadius(25)
                                    .onAppear {
                                        animatePlaceholder()
                                    }
                                        .onSubmit {
                                            sendMessage()
                                        }
                                    
                                    Button(action: {
                                        sendMessage()
                                    }) {
                                        Circle()
                                        .fill(LinearGradient(gradient: Gradient(colors: [currentInput.isEmpty ? .gray : .purple, .blue]), startPoint: .topLeading, endPoint: .bottomTrailing))
                                            .frame(width: 45, height: 45)
                                        .animation(.easeInOut, value:currentInput.isEmpty)
                                            .overlay(
                                            ZStack {
                                                Image(systemName: currentInput.isEmpty ? "arrow.up" : "arrow.up")
                                                    .foregroundColor(.white)
                                                    .font(.system(size: 20))
                                            }
                                            )
                                    }
                                }
                                .padding()
                        }
                    }
                }
            }
        }
        
      
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
            .environmentObject(firebaseManager)
        }
        .fullScreenCover(isPresented: $showingLocationSearch) {
            LocationSearchView(isPresented: $showingLocationSearch) { location, coordinates in
                eventDetails.location = location
                eventDetails.coordinates = coordinates
                currentInput = location
                sendMessage()
            }
        }
        .fullScreenCover(isPresented: $showingReview) {
            EventReviewView(eventDetails: eventDetails, selectedImage: selectedImage, isPresented: $showingReview, clearMessages: $clearMessages)
        }
        .fullScreenCover(isPresented: $showingCategoryPicker) {
            CategorySelectionView(isPresented: $showingCategoryPicker) { category in
                currentInput = category
                sendMessage()
            }
        }
        .onAppear {
            tabBarManager.hideTab = true
            animatePlaceholder()
            // Add initial question with typing animation
            addAIResponse("Hello! Let's create your event.\nWhat would you like to name it?")
        }
        .onDisappear {
            tabBarManager.hideTab = false
            placeholderTimer?.invalidate()
            placeholderTimer = nil
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
        shouldAnimatePlaceholder = false // Stop the animation once user starts interacting
        
        switch currentQuestion {
        case 0:
                eventDetails.title = input.split(separator: " ")
                    .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
                    .joined(separator: " ")
            addAIResponse("Great name! When are you planning to hold this event?", showCalendarAfter: true)
            animatedPlaceholder = "e.g., Tomorrow at 3 PM, Next Friday at 2 PM"
        case 1:
            eventDetails.date = parseDate(input) ?? Date()
            animatedPlaceholder = "e.g., Central Park, 123 Main Street"
            addAIResponse("Perfect! Where will the event be held?") { [self] in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) {
                    showingLocationSearch = true
                }
            }
        case 2:
            eventDetails.location = input
            addAIResponse("What is it about?")
            animatedPlaceholder = "e.g., A music festival featuring local artists"
        case 3:
            eventDetails.description = input
            addAIResponse("How many people can attend this event?")
            animatedPlaceholder = "e.g., 50, 100, 250 (enter a number)"
        case 4:
            if let participants = Int(input) {
                eventDetails.maxParticipants = participants
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) {
                showingCategoryPicker = true
                }
                animatedPlaceholder = "Choose from available categories"
            } else {
                addAIResponse("Please enter a valid number of participants.")
                animatedPlaceholder = "Please enter a number (e.g., 50)"
                currentQuestion -= 1
            }
        case 5:
            eventDetails.category = input
            addAIResponse("Great! Now let's add some photos to showcase your event.") { [self] in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation {
                        showImagePicker = true
                    }
                }
            }
            animatedPlaceholder = "Select photos to continue"
            // After photos are selected, handleFinalSteps will be called automatically
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
            if eventDetails.date == Date() {
                currentQuestion = 1
            addAIResponse("Let's schedule your event! When would you like it to take place?", showCalendarAfter: true)
            } else {
                showingDatePicker = true
            }
        case .location:
            if eventDetails.location.isEmpty {
                currentQuestion = 2
            addAIResponse("Let's set the location for your event!") { [self] in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showingLocationSearch = true
                }
                }
            } else {
                showingLocationSearch = true
            }
        case .participants:
            if eventDetails.maxParticipants == 0 {
                currentQuestion = 4
            addAIResponse("How many people can attend this event?")
                animatedPlaceholder = "e.g., 50, 100, 250 (enter a number)"
            } else {
                let userMessage = ChatMessage(content: "\(eventDetails.maxParticipants)", isUser: true)
                messages.append(userMessage)
                processUserInput("\(eventDetails.maxParticipants)")
            }
        case .category:
            if eventDetails.category == eventTypes[0] {
                currentQuestion = 5
            }
            showingCategoryPicker = true
        case .photos:
            withAnimation {
            showImagePicker = true
                addAIResponse("Select up to 3 images for your event")
            }
        case .description:
            if eventDetails.description.isEmpty {
                currentQuestion = 3
            addAIResponse("Tell me more about what this event is about.")
                animatedPlaceholder = "e.g., A music festival featuring local artists"
            } else {
                let userMessage = ChatMessage(content: eventDetails.description, isUser: true)
                messages.append(userMessage)
                processUserInput(eventDetails.description)
        }
        }
        shouldAnimatePlaceholder = false
    }
    
    private func handleFinalSteps(_ input: String) {
        // If there are images, upload them first
        if !selectedImages.isEmpty {
            Task {
                // Upload images first if there are any
                let imageUrls = await uploadImagesToFirebase()
                eventDetails.images = imageUrls
                
                // Show the review view after images are uploaded
                DispatchQueue.main.async {
            showingReview = true
                }
            }
        } else {
            // If no images, just show the review view
            showingReview = true
        }
    }
    
    private func parseDate(_ input: String) -> Date? {
        // Add date parsing logic
        return Date()
    }
    
    private func animatePlaceholder() {
        guard shouldAnimatePlaceholder else { return }
        
        // Cancel any existing timer
        placeholderTimer?.invalidate()
        placeholderTimer = nil
        
        var currentIndex = 0
        var isDeleting = false
        
        placeholderTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { timer in
            if !isDeleting {
                // Typing
                if currentIndex < placeholderText.count {
                    let index = placeholderText.index(placeholderText.startIndex, offsetBy: currentIndex)
                    animatedPlaceholder += String(placeholderText[index])
                    currentIndex += 1
                } else {
                    // Finished typing, wait before deleting
                    timer.invalidate()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        isDeleting = true
                        self.startDeletion()
                    }
                }
            }
        }
    }
    
    private func startDeletion() {
        guard shouldAnimatePlaceholder else { return }
        
        placeholderTimer?.invalidate()
        placeholderTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if !animatedPlaceholder.isEmpty {
                animatedPlaceholder.removeLast()
            } else {
                // Finished deleting, wait before restarting
                timer.invalidate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.animatePlaceholder()
                }
            }
        }
    }
    
    private func generateHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
    
    private func uploadImagesToFirebase() async -> [String] {
        var imageUrls: [String] = []
        let storage = Storage.storage()
        let storageRef = storage.reference(forURL: "gs://eventportal-37f4b.firebasestorage.app")
        
        for (index, image) in selectedImages.enumerated() {
            guard let imageData = image.jpegData(compressionQuality: 0.5) else { continue }
            
            let imageName = "\(UUID().uuidString)_\(index).jpg"
            let imageRef = storageRef.child("event_images/\(imageName)")
            
            do {
                let _ = try await imageRef.putDataAsync(imageData)
                let downloadURL = try await imageRef.downloadURL()
                imageUrls.append(downloadURL.absoluteString)
            } catch {
                print("Error uploading image: \(error)")
            }
        }
        
        return imageUrls
    }
    
    private func createEvent() {
        isLoading = true
        
        Task {
            // Upload images first if there are any
            let imageUrls = selectedImages.isEmpty ? ["bg1"] : await uploadImagesToFirebase()
            
            let event = Event(
                name: eventDetails.title,
                description: eventDetails.description,
                type: eventDetails.category,
                views: "0",
                location: eventDetails.location,
                price: "Free",
                owner: firebaseManager.currentUser?.uid ?? "",
                startDate: eventDetails.date,
                endDate: eventDetails.date.addingTimeInterval(7200),
                images: imageUrls,
                participants: Array(repeating: "Participant", count: eventDetails.maxParticipants),
                isTimed: true,
                createdAt: Date(),
                coordinates: eventDetails.coordinates,
                status: "active"
            )
            
            firebaseManager.createEvent(event: event) { success, error in
                isLoading = false
                if success {
                    withAnimation {
                        showSuccess = true
                    }
                } else {
                    errorMessage = error ?? "Failed to create event"
                    showError = true
                }
            }
        }
    }
    
    private var imagePickerButton: some View {
        PhotosPicker(
            selection: $selectedImageItems,
            maxSelectionCount: 3,
            matching: .images
        ) {
            HStack {
                Image(systemName: "photo.stack")
                Text("\(selectedImages.count)/3 Images")
            }
            .foregroundColor(.white)
            .padding()
            .background(Color.blue)
            .cornerRadius(10)
        }
        .onChange(of: selectedImageItems) { newItems in
            Task {
                selectedImages = []
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImages.append(image)
                    }
                }
                
                if !selectedImages.isEmpty {
                    await uploadImagesToFirebase()
                }
            }
        }
    }
    
    private var selectedImagesPreview: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(0..<selectedImages.count, id: \.self) { index in
                    Image(uiImage: selectedImages[index])
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            Button(action: {
                                selectedImages.remove(at: index)
                                selectedImageItems.remove(at: index)
                                if let url = uploadedImageURLs[safe: index] {
                                    uploadedImageURLs.remove(at: index)
                                    eventDetails.images.remove(at: index)
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                                    .background(Color.black.opacity(0.7))
                                    .clipShape(Circle())
                            }
                            .padding(5),
                            alignment: .topTrailing
                        )
                }
            }
            .padding(.horizontal)
        }
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
    let onDateSelected: (Date) -> Void
    @EnvironmentObject private var firebaseManager: FirebaseManager
    
    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators:false) {
                    ZStack {
                        Color.dynamic.edgesIgnoringSafeArea(.all)
                        
                        VStack(alignment: .center, spacing: 20) {
                            VStack(alignment: .center) {
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
                            }
                            .fontWeight(.bold)
                                .padding(.horizontal)
                                .padding(.top,20)
                            
                            DatePicker("Select Date", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(GraphicalDatePickerStyle())
                                .padding(.horizontal,10)
                                .padding(.vertical,5)
                                .background(.gray.opacity(0.00))
                                .cornerRadius(19)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 19)
                                        .stroke(Color.blue.opacity(0.50), lineWidth: 1)
                                )
                                .padding(.horizontal)
                            
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
                                .onTapGesture {
                                onDateSelected(selectedDate)
                                isPresented = false
                                }
                            .padding()
                            .id("bottom")
                        }
                    }
                    .navigationTitle("Select Date")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarBackground(Color.dynamic)
                    .navigationBarItems(trailing: Button("Cancel") {
                        isPresented = false
                    })
                    .padding(.bottom,20)
                }
            }
        }
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
    var coordinates: [Double] = []
    var images: [String] = []
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
            ZStack {
                Color.dynamic
                    .edgesIgnoringSafeArea(.all)
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
            .toolbarBackground(Color.dynamic)
            .background(Color.dynamic.edgesIgnoringSafeArea(.all))
        }
        }
        
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

//struct CreateEventView_Previews: PreviewProvider {
//    static var previews: some View {
//        Group {
//            // Main CreateEventView preview
//            CreateEventView()
//                .environmentObject(FirebaseManager.preview)
//            
//            // LocationSearchView preview
//            LocationSearchView(isPresented: .constant(true)) { location, coordinates in
//                print("Selected location: \(location), coordinates: \(coordinates)")
//            }
//            
//            // DatePickerView preview
//            DatePickerView(
//                selectedDate: .constant(Date()),
//                isPresented: .constant(true),
//                eventDetails: EventDetails(description: "Team sync-up"),
//                onDateSelected: { selectedDate in
//                    print("Selected date: \(selectedDate)")
//                }
//            )
//            .environmentObject(FirebaseManager.preview)
//            
//            // EventReviewView preview
//            EventReviewView(
//                eventDetails: EventDetails(
//                    title: "Sample Event",
//                    date: Date(),
//                    location: "123 Main St, San Francisco",
//                    description: "This is a sample event description",
//                    maxParticipants: 50,
//                    category: "Entertainment"
//                ),
//                selectedImage: nil,
//                isPresented: .constant(true)
//            )
//            .environmentObject(FirebaseManager.preview)
//        }
//    }
//}

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
                .font(.system(size: isLarge ? 40 : 16, weight: isLarge ? .bold : .medium))
               
        }
        
        .padding(.vertical, 8)
    }
}

struct EventReviewView: View {
    let eventDetails: EventDetails
    let selectedImage: UIImage?
    @Binding var isPresented: Bool
    @Binding var clearMessages: Bool
    @State private var isLoading = false
    @State private var showSuccess = false
    @EnvironmentObject private var firebaseManager: FirebaseManager
    @State private var errorMessage: String?
    @State private var showError = false
    
    private func createEvent() {
        isLoading = true
        
        Task {
            do {
                let event = Event(
                    name: eventDetails.title,
                    description: eventDetails.description,
                    type: eventDetails.category,
                    views: "0",
                    location: eventDetails.location,
                    price: "Free",
                    owner: firebaseManager.currentUser?.uid ?? "",
                    startDate: eventDetails.date,
                    endDate: eventDetails.date.addingTimeInterval(7200),
                    images: eventDetails.images.isEmpty ? ["bg1"] : eventDetails.images,
                    participants: Array(repeating: "Participant", count: eventDetails.maxParticipants),
                    isTimed: true,
                    createdAt: Date(),
                    coordinates: eventDetails.coordinates,
                    status: "active"
                )
                
                firebaseManager.createEvent(event: event) { success, error in
                    isLoading = false
                    if success {
                        withAnimation {
                            showSuccess = true
                        }
                    } else {
                        errorMessage = error ?? "Failed to create event"
                        showError = true
                    }
                }
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    // Update the computed property for preview event
    private var previewEvent: Event {
        let ownerName: String = {
            if let user = firebaseManager.currentUser {
                return user.displayName ?? user.email ?? "Anonymous"
            }
            return "Anonymous"
        }()
        
        return Event(
            name: eventDetails.title,
            description: eventDetails.description,
            type: eventDetails.category,
            views: "0",
            location: eventDetails.location,
            price: "Free",
            owner: ownerName,
            startDate: eventDetails.date,
            endDate: eventDetails.date.addingTimeInterval(7200),
            images: eventDetails.images.isEmpty ? ["bg1"] : eventDetails.images,
            participants: Array(repeating: "Participant", count: eventDetails.maxParticipants),
            isTimed: true,
            createdAt: Date(),
            coordinates: eventDetails.coordinates,
            status: "active"
        )
    }
    
    // Update the map region to use actual coordinates if available
    private var region: MKCoordinateRegion {
        if eventDetails.coordinates.count >= 2 {
                return MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: eventDetails.coordinates[0],
                    longitude: eventDetails.coordinates[1]
                ),
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
        }
        // Default to San Francisco if no valid coordinates
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }
    
    private func formatTimeOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private func formatDateOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
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
                            VStack(spacing: 10) {
                                Image(systemName: typeSymbols[eventDetails.category] ?? "calendar")
                                    .font(.system(size: 40))
                                    .frame(width: 80, height: 80)
                                   // .background(Circle().fill(Color.blue))
                                
                                Text(eventDetails.title)
                                    .font(.title2)
                                    .bold()
                                    .foregroundStyle(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.purple,Color.invert, .blue]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                
                                Text(eventDetails.category)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color.dynamic)
                            
                            // Time Section
                            HStack(spacing: 40) {
                                VStack(alignment: .center, spacing: 5) {
                                    Text(formatTimeOnly(eventDetails.date))
                                        .font(.system(size: 20, weight: .bold))
                                        .padding(.horizontal,10)
                                        .background(Color.gray.opacity(0.07))
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(.white, lineWidth: 1)
                                                .opacity(0.1)
                                        )
                                        
                                    Text(formatDateOnly(eventDetails.date))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Image(systemName: "arrow.right")
                                    .font(.title2)
                                
                                
                                VStack(alignment: .center, spacing: 5) {
                                    Text(formatTimeOnly(eventDetails.date.addingTimeInterval(7200)))
                                        .font(.system(size: 20, weight: .bold))
                                        .padding(.horizontal,10)
                                        .background(Color.gray.opacity(0.07))
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(.white, lineWidth: 1)
                                                .opacity(0.1)
                                        )
                                    
                                    Text(formatDateOnly(eventDetails.date.addingTimeInterval(7200)))
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
                                        ReviewSection(title: "Event", content: "Ongoing")
                                            .lineLimit(2)
                                        Spacer()
                                         
                                    }
                                    
                                    HStack {
                                        ReviewSection(title: "Owner", content: {
                                            if let user = firebaseManager.currentUser {
                                                return user.displayName ?? user.email ?? "Anonymous"
                                            }
                                            return "Anonymous"
                                        }())
                                            .lineLimit(2)
                                        Spacer()
                                        
                                    }
                                }
                                .foregroundColor(Color.invert)
                                .padding()
                                .background(Color.dynamic)
                                .transition(.move(edge: .top).combined(with: .opacity))
                            } else {
                           
                               // Success View Overlay
                                VStack(spacing: 20) {
                                    // Animated success checkmark
                                    ZStack {
                                        
                                        
                                        
                                        
                                        Image(systemName: "checkmark.circle")
                                            .font(.system(size: 50, weight: .regular))
                                            
                                            .foregroundStyle(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [Color.purple,Color.invert, .blue]),
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
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
                                            .padding(.bottom,10)
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
                      
                        
                       

                        // Action Button
                        Button(action: {
                            if showSuccess {
                                clearMessages = true
                                        isPresented = false
                                
                                
                            } else {
                                createEvent()
                            }
                        }) {
                            HStack(spacing: showSuccess ? 5 : 15) {
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
                            .cornerRadius(19)
                            .shadow(color: isLoading ? .clear : .purple.opacity(0.3),
                                    radius: 10, x: 0, y: 5)
                            .opacity(isLoading ? 0.8 : 1)
                            .scaleEffect(isLoading ? 0.98 : 1)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isLoading)
                        }
                        .disabled(isLoading)
                        .padding(.top)
                        .padding(.horizontal, 20)
                    }
                    .padding()
                }
            }
            .navigationTitle("Event Pass")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.dynamic)
            .navigationBarItems(trailing: Button(showSuccess ? "" : "Edit") {
                isPresented = false
                
            })
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
        }
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
    
    let onLocationSelected: (String, [Double]) -> Void
    
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
                        
                        Text("This can include the venue name, street address, city, state, and zip code to ensure attendees can easily find and navigate to your event location")
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
                            LazyVStack(alignment: .center, spacing: 12) {
                                ForEach(completer.searchResults.prefix(3), id: \.self) { result in
                                    Button(action: {
                                        searchLocation(result)
                                    }) {
                                        VStack(alignment: .center) {
                                            Divider()
                                            Text(result.title + ", " + result.subtitle)
                                                .font(.callout)
                                                .foregroundColor(.primary)
                                            
                                        }
                                    }
                                    .padding(.vertical, 7)
                                    .padding(.horizontal, 10)
                                    .cornerRadius(9)
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .simultaneousGesture(DragGesture().onChanged { _ in
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        })
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, isFocused ? 25 : 0)
                .animation(.spring(), value: isFocused)
                
                if showMap {
                    
                    
                    VStack {
                        Text("Please confirm the location of the event on the map below.")
                           
                            .multilineTextAlignment(.center)
                        
                        Divider()
                        
                        if let region = completer.region {
                            Map(coordinateRegion: .constant(region),
                                annotationItems: [MapPin(coordinate: region.center)]) { pin in
                                MapMarker(coordinate: pin.coordinate, tint: .red)
                            }
                            .frame(height: 500)
                            .cornerRadius(12)
                        }
                        
                        
                        
                        if !confirmed {
                            HStack {
                              
                                
                                Button("Confirm") {
                                    confirmed = true
                                    // Split location and coordinates
                                    let locationComponents = completer.selectedAddress.components(separatedBy: " | ")
                                    let address = locationComponents[0]
                                    let coordinates = locationComponents[1].components(separatedBy: ", ")
                                        .compactMap { Double($0) }
                                    onLocationSelected(address, coordinates)
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
                            .padding(.top,10)
                            
                            HStack{
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
                            }.padding(.top,5)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.dynamic)
                    
                   
                    .onAppear {
                        isFocused = false
                    }
                }
            }.navigationTitle("Select Location")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(Color.dynamic)
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
                
                // Create location string with address and coordinates separated
                let address = [
                    mapItem.name,
                    mapItem.placemark.locality
                ].compactMap { $0 }.joined(separator: ", ")
                
                // Store address and coordinates separately with a delimiter
                completer.selectedAddress = "\(address) | \(coordinate.latitude), \(coordinate.longitude)"
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
        .toolbarBackground(Color.dynamic)
        .background(Color.dynamic.edgesIgnoringSafeArea(.all))
        .simultaneousGesture(DragGesture().onChanged { _ in
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        })
    }
}

struct TypingBubbleView: View {
    @State private var firstDotOpacity: Double = 0.3
    @State private var secondDotOpacity: Double = 0.3
    @State private var thirdDotOpacity: Double = 0.3
    @State private var animationTimer: Timer?
    
    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            Text("Typing")
                .foregroundColor(.gray)
            
            // Three animated dots
            HStack(alignment: .center, spacing: 4) {
                Circle()
                    .frame(width: 4, height: 4)
                    .opacity(firstDotOpacity)
                Circle()
                    .frame(width: 4, height: 4)
                    .opacity(secondDotOpacity)
                Circle()
                    .frame(width: 4, height: 4)
                    .opacity(thirdDotOpacity)
            }
            .foregroundColor(.gray)
        }
        .frame(height: 30)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.09))
        .cornerRadius(16)
        .transition(.asymmetric(
            insertion: .opacity,
            removal: .opacity
        ))
        .padding(.horizontal, 16)
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
    }
    
    private func startAnimation() {
        // Reset opacities
        firstDotOpacity = 0.3
        secondDotOpacity = 0.3
        thirdDotOpacity = 0.3
        
        // Create and start the timer
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                // First dot animation
                firstDotOpacity = firstDotOpacity == 1.0 ? 0.3 : 1.0
                
                // Delay second dot
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        secondDotOpacity = secondDotOpacity == 1.0 ? 0.3 : 1.0
                    }
                }
                
                // Delay third dot
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        thirdDotOpacity = thirdDotOpacity == 1.0 ? 0.3 : 1.0
                    }
                }
            }
        }
    }
    
    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
}

extension UIImpactFeedbackGenerator {
    static func tabSelection() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
}






