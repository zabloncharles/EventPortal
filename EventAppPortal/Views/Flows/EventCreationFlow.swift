//
//  EventCreationFlow.swift
//  EventAppPortal
//
//  Created by Zablon Charles on 4/12/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import CoreLocation
import MapKit
// MARK: - Event Creation Flow

struct EventCreationFlow: View {
    @ObservedObject var viewModel: CreateEventViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    @State private var showLocationSearch = false
    @State private var animateContent = false
    
    let steps = [
        "Event Name",
        "Description",
        "Event Type",
        "Date & Time",
        "Location",
        "Price",
        "Capacity",
        "Preview"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            
            
            // Content
            TabView(selection: $currentStep) {
                // Event Name
                OnboardingStepView(
                    title: "Name your event",
                    subtitle: "Give your event a catchy name that stands out",
                    icon: "pencil.line",
                    gradient: [.blue, .purple]
                ) {
                    VStack(spacing: 20) {
                        TextField("Event Name", text: $viewModel.name)
                            .textFieldStyle(.roundedBorder)
                            .font(.title3)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        
                        Button(action: { withAnimation { currentStep += 1 } }) {
                            Text("Continue")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.blue, .purple]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                        }
                        .disabled(viewModel.name.isEmpty)
                        .opacity(viewModel.name.isEmpty ? 0.6 : 1)
                    }
                    .padding()
                }
                .tag(0)
                
                // Description
                OnboardingStepView(
                    title: "Describe your event",
                    subtitle: "Help people understand what your event is about",
                    icon: "text.alignleft",
                    gradient: [.purple, .blue]
                ) {
                    VStack(spacing: 20) {
                        TextEditor(text: $viewModel.description)
                            .frame(height: 150)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        
                        NavigationButtons(
                            onBack: { withAnimation { currentStep -= 1 } },
                            onNext: { withAnimation { currentStep += 1 } },
                            isNextDisabled: viewModel.description.isEmpty
                        )
                    }
                    .padding()
                }
                .tag(1)
                
                // Event Type
                OnboardingStepView(
                    title: "What type of event?",
                    subtitle: "Select a category that best fits your event",
                    icon: "tag",
                    gradient: [.orange, .red]
                ) {
                    VStack(spacing: 20) {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                ForEach(EventType.allCases, id: \.self) { type in
                                    Button(action: {
                                        viewModel.type = type.rawValue
                                        withAnimation { currentStep += 1 }
                                    }) {
                                        VStack(spacing: 12) {
                                            Image(systemName: type.icon)
                                                .font(.system(size: 30))
                                            Text(type.rawValue)
                                                .font(.headline)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 100)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(viewModel.type == type.rawValue ? Color.blue : Color(.systemGray6))
                                        )
                                        .foregroundColor(viewModel.type == type.rawValue ? .white : .primary)
                                    }
                                }
                            }
                        }
                        
                        Button(action: { withAnimation { currentStep -= 1 } }) {
                            Text("Back")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                }
                .tag(2)
                
                // Date & Time
                OnboardingStepView(
                    title: "When is it happening?",
                    subtitle: "Set the date and time for your event",
                    icon: "calendar",
                    gradient: [.green, .blue]
                ) {
                    VStack(spacing: 20) {
                        DatePicker("Start Date", selection: $viewModel.startDate, in: Date()...)
                            .datePickerStyle(.graphical)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        
                        DatePicker("End Date", selection: $viewModel.endDate, in: viewModel.startDate...)
                            .datePickerStyle(.graphical)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        
                        NavigationButtons(
                            onBack: { withAnimation { currentStep -= 1 } },
                            onNext: { withAnimation { currentStep += 1 } }
                        )
                    }
                    .padding()
                }
                .tag(3)
                
                // Location
                OnboardingStepView(
                    title: "Where is it happening?",
                    subtitle: "Choose a location for your event",
                    icon: "mappin.and.ellipse",
                    gradient: [.red, .orange]
                ) {
                    VStack(spacing: 20) {
                        Button(action: { showLocationSearch = true }) {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.blue)
                                Text(viewModel.location?.address ?? "Select Location")
                                    .foregroundColor(viewModel.location == nil ? .gray : .primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        
                        if let location = viewModel.location {
                            Map(coordinateRegion: .constant(MKCoordinateRegion(
                                center: CLLocationCoordinate2D(
                                    latitude: location.coordinates[0],
                                    longitude: location.coordinates[1]
                                ),
                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                            )))
                            .frame(height: 200)
                            .cornerRadius(12)
                        }
                        
                        NavigationButtons(
                            onBack: { withAnimation { currentStep -= 1 } },
                            onNext: { withAnimation { currentStep += 1 } },
                            isNextDisabled: viewModel.location == nil
                        )
                    }
                    .padding()
                }
                .tag(4)
                
                // Price
                OnboardingStepView(
                    title: "Set the price",
                    subtitle: "Is this a paid event?",
                    icon: "dollarsign.circle",
                    gradient: [.green, .blue]
                ) {
                    VStack(spacing: 20) {
                        Toggle("This is a paid event", isOn: Binding(
                            get: { Double(viewModel.price) ?? 0 > 0 },
                            set: { if !$0 { viewModel.price = "0" } }
                        ))
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        if Double(viewModel.price) ?? 0 > 0 {
                            HStack {
                                Text("$")
                                    .foregroundColor(.gray)
                                TextField("0.00", text: $viewModel.price)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 34, weight: .bold))
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        
                        NavigationButtons(
                            onBack: { withAnimation { currentStep -= 1 } },
                            onNext: { withAnimation { currentStep += 1 } }
                        )
                    }
                    .padding()
                }
                .tag(5)
                
                // Capacity
                OnboardingStepView(
                    title: "Set capacity",
                    subtitle: "How many people can attend?",
                    icon: "person.3",
                    gradient: [.purple, .red]
                ) {
                    VStack(spacing: 20) {
                        Picker("Maximum Participants", selection: $viewModel.maxParticipants) {
                            ForEach(["10", "25", "50", "100", "250", "500", "1000"], id: \.self) { number in
                                Text("\(number) people").tag(number)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 150)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        Toggle("Make this a private event", isOn: $viewModel.isPrivate)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        
                        NavigationButtons(
                            onBack: { withAnimation { currentStep -= 1 } },
                            onNext: { withAnimation { currentStep += 1 } }
                        )
                    }
                    .padding()
                }
                .tag(6)
                
                // Preview
                PreviewView(
                    viewModel: viewModel,
                    onBack: { withAnimation { currentStep -= 1 } },
                    onCreateEvent: {
                        Task {
                            do {
                                try await viewModel.createEvent()
                                dismiss()
                            } catch {
                                print("Error creating event: \(error)")
                            }
                        }
                    }
                )
                .tag(7)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentStep)
            
            // Progress Bar
            ProgressStepsView(steps: steps, currentStep: currentStep)
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showLocationSearch) {
            LocationSearchView(isPresented: $showLocationSearch) { address, coordinates in
                viewModel.setLocation(address: address, coordinates: coordinates)
            }
        }
    }
}

struct NavigationButtons: View {
    let onBack: () -> Void
    let onNext: () -> Void
    var isNextDisabled: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: onBack) {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .font(.headline)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            Button(action: onNext) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
            .disabled(isNextDisabled)
            .opacity(isNextDisabled ? 0.6 : 1)
        }
    }
}

enum EventType: String, CaseIterable {
    case Technology = "Technology"
    case Sports = "Sports"
    case Art = "Art & Culture"
    case Music = "Music"
    case Food = "Food"
    case Travel = "Travel"
    case Environmental = "Environmental"
    case Literature = "Literature"
    case Corporate = "Corporate"
    case Health = "Health & Wellness"
    case Other = "Other"
    
    var icon: String {
        switch self {
        case .Technology: return "laptopcomputer"
        case .Sports: return "sportscourt.fill"
        case .Art: return "paintbrush.fill"
        case .Music: return "music.note"
        case .Food: return "fork.knife"
        case .Travel: return "airplane"
        case .Environmental: return "leaf.fill"
        case .Literature: return "book.fill"
        case .Corporate: return "building.2.fill"
        case .Health: return "heart.fill"
        case .Other: return "questionmark.circle.fill"
        }
    }
}

// MARK: - Onboarding Step View
struct OnboardingStepView<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradient: [Color]
    let content: () -> Content
    @State private var animateIcon = false
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 16) {
                    // Icon
                    Image(systemName: icon)
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: gradient),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(animateIcon ? 1 : 0.5)
                        .opacity(animateIcon ? 1 : 0)
                    
                    // Title
                    Text(title)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .opacity(animateIcon ? 1 : 0)
                        .offset(y: animateIcon ? 0 : 20)
                    
                    // Subtitle
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .opacity(animateIcon ? 1 : 0)
                        .offset(y: animateIcon ? 0 : 20)
                }
                .padding(.top, 40)
                
                // Content
                content()
                    .opacity(animateIcon ? 1 : 0)
                    .offset(y: animateIcon ? 0 : 20)
            }
            .padding()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateIcon = true
            }
        }
    }
}

// MARK: - Location View
struct LocationView: View {
    @ObservedObject var viewModel: CreateEventViewModel
    @Binding var showLocationSearch: Bool
    let onBack: () -> Void
    let onNext: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Location Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Where is your event?")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Select a location for your event")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                // Location Selection Button
                Button(action: {
                    showLocationSearch = true
                }) {
                    VStack(spacing: 12) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        
                        if let location = viewModel.location {
                            Text(location.address)
                                .font(.headline)
                                .multilineTextAlignment(.center)
                        } else {
                            Text("Select Location")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        
                        Text("Tap to search for a location")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // Map Preview (if location is selected)
                if let location = viewModel.location {
                    Map(coordinateRegion: .constant(MKCoordinateRegion(
                        center: CLLocationCoordinate2D(
                            latitude: location.coordinates[0],
                            longitude: location.coordinates[1]
                        ),
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )))
                    .frame(height: 200)
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Navigation Buttons
                HStack {
                    Button(action: onBack) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    
                    Button(action: onNext) {
                        HStack {
                            Text("Next")
                            Image(systemName: "chevron.right")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.location != nil ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(viewModel.location == nil)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

// Add this before CreateEventViewModel class
struct EventLocation {
    let address: String
    let coordinates: [Double]
}

class CreateEventViewModel: ObservableObject {
    @Published var name = ""
    @Published var description = ""
    @Published var type = "Conference"
    @Published var startDate = Date()
    @Published var endDate = Date().addingTimeInterval(3600) // 1 hour later
    @Published var location: EventLocation?
    @Published var price = ""
    @Published var maxParticipants = ""
    @Published var isPrivate = false
    @Published var selectedImages: [UIImage] = []
    @Published var showImagePicker = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var eventCreated = false
    @Published var createdEventId: String?
    
    let eventTypes = [
        "Conference", "Workshop", "Seminar", "Networking", "Exhibition",
        "Concert", "Festival", "Sports", "Charity", "Other"
    ]
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage().reference()
    private let geocoder = CLGeocoder()
    
    func setLocation(address: String, coordinates: [Double]) {
        self.location = EventLocation(address: address, coordinates: coordinates)
    }
    
    func createEvent() async throws {
        // Validate required fields
        guard !name.isEmpty else {
            errorMessage = "Please enter an event name"
            showError = true
            throw EventCreationError.invalidName
        }
        
        guard let location = location else {
            errorMessage = "Please select a location for the event"
            showError = true
            throw EventCreationError.missingLocation
        }
        
        guard !maxParticipants.isEmpty, let maxParticipantsInt = Int(maxParticipants), maxParticipantsInt > 0 else {
            errorMessage = "Please enter a valid number of maximum participants"
            showError = true
            throw EventCreationError.invalidParticipants
        }
        
        isLoading = true
        
        // Get current user ID
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "You must be logged in to create an event"
            showError = true
            isLoading = false
            throw EventCreationError.notAuthenticated
        }
        
        // Create event data
        let eventData: [String: Any] = [
            "name": self.name,
            "description": self.description,
            "type": self.type,
            "views": "0",
            "location": location.address,
            "price": self.price,
            "owner": userId,
            "organizerName": "Event Organizer", // This could be fetched from user profile
            "shareContactInfo": true,
            "startDate": Timestamp(date: self.startDate),
            "endDate": Timestamp(date: self.endDate),
            "images": [],
            "participants": [userId], // Creator is the first participant
            "maxParticipants": maxParticipantsInt,
            "isTimed": true,
            "createdAt": Timestamp(date: Date()),
            "latitude": location.coordinates[0],
            "longitude": location.coordinates[1],
            "status": "active"
        ]
        
        do {
            // Add event to Firestore
            let docRef = self.db.collection("events").document()
            try await docRef.setData(eventData)
            
            let eventId = docRef.documentID
            
            // If there are images, upload them
            if !self.selectedImages.isEmpty {
                try await uploadEventImages(images: self.selectedImages, eventId: eventId)
            }
            
            DispatchQueue.main.async {
                self.createdEventId = eventId
                self.eventCreated = true
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to create event: \(error.localizedDescription)"
                self.showError = true
                self.isLoading = false
            }
            throw error
        }
    }
    
    private func uploadEventImages(images: [UIImage], eventId: String) async throws {
        var imageUrls: [String] = []
        
        for (index, image) in images.enumerated() {
            guard let imageData = image.jpegData(compressionQuality: 0.7) else {
                continue
            }
            
            let imageRef = storage.child("event_images/\(eventId)_\(index).jpg")
            
            do {
                _ = try await imageRef.putData(imageData)
                let downloadURL = try await imageRef.downloadURL()
                imageUrls.append(downloadURL.absoluteString)
            } catch {
                throw EventCreationError.imageUploadFailed(error)
            }
        }
        
        // Update event with image URLs
        try await self.db.collection("events").document(eventId).updateData([
            "images": imageUrls
        ])
    }
    
    enum EventCreationError: Error {
        case invalidName
        case missingLocation
        case invalidParticipants
        case notAuthenticated
        case imageUploadFailed(Error)
    }
    
    func resetForm() {
        name = ""
        description = ""
        type = "Conference"
        startDate = Date()
        endDate = Date().addingTimeInterval(3600)
        location = nil
        price = ""
        maxParticipants = ""
        isPrivate = false
        selectedImages = []
        errorMessage = nil
        showError = false
        eventCreated = false
        createdEventId = nil
    }
}


