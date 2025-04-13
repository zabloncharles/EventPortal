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
    @State private var currentStep = 0
    @State private var showLocationSearch = false
    @State private var animateContent = false
    let steps = ["Basic Info", "Date & Time", "Location & Details", "Preview"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress Steps with animation
            ProgressStepsView(steps: steps, currentStep: currentStep)
                .padding(.horizontal)
                .transition(.slide)
            
            // Content
            TabView(selection: $currentStep) {
                // MARK: - Basic Info Step
                OnboardingStepView(
                    title: "Let's Create Your Event",
                    subtitle: "Start by giving your event a name and telling people what it's about",
                    icon: "star.circle.fill",
                    gradient: [.blue, .purple]
                ) {
                    BasicInfoView(viewModel: viewModel) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            currentStep = 1
                        }
                    }
                }
                .tag(0)
                
                // MARK: - Date & Time Step
                OnboardingStepView(
                    title: "When is Your Event?",
                    subtitle: "Set the date and time for your event",
                    icon: "calendar.circle.fill",
                    gradient: [.orange, .red]
                ) {
                    DateTimeView(viewModel: viewModel,
                               onBack: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            currentStep = 0
                        }
                    },
                               onNext: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            currentStep = 2
                        }
                    })
                }
                .tag(1)
                
                // MARK: - Location & Details Step
                OnboardingStepView(
                    title: "Where is Your Event?",
                    subtitle: "Choose a location and add important details",
                    icon: "mappin.circle.fill",
                    gradient: [.green, .blue]
                ) {
                    LocationDetailsView(viewModel: viewModel,
                                     onBack: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            currentStep = 1
                        }
                    },
                                     onNext: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            currentStep = 3
                        }
                    })
                }
                .tag(2)
                
                // MARK: - Preview Step
                OnboardingStepView(
                    title: "Almost Done!",
                    subtitle: "Review your event details before publishing",
                    icon: "checkmark.circle.fill",
                    gradient: [.purple, .blue]
                ) {
                    PreviewView(viewModel: viewModel,
                              onBack: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            currentStep = 2
                        }
                    },
                              onCreateEvent: {
                        viewModel.createEvent()
                    })
                }
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentStep)
        }
        .sheet(isPresented: $showLocationSearch) {
            LocationSearchView(isPresented: $showLocationSearch) { address, coordinates in
                viewModel.setLocation(address: address, coordinates: coordinates)
            }
        }
        .navigationTitle(steps[currentStep])
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {
                viewModel.showError = false
            }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
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
                            Text(location)
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
                if let coordinates = viewModel.coordinates {
                    Map(coordinateRegion: .constant(MKCoordinateRegion(
                        center: coordinates,
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

class CreateEventViewModel: ObservableObject {
    @Published var name = ""
    @Published var description = ""
    @Published var type = "Conference"
    @Published var startDate = Date()
    @Published var endDate = Date().addingTimeInterval(3600) // 1 hour later
    @Published var location: String?
    @Published var coordinates: CLLocationCoordinate2D?
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
        self.location = address
        self.coordinates = CLLocationCoordinate2D(latitude: coordinates[0], longitude: coordinates[1])
    }
    
    func createEvent() {
        // Validate required fields
        guard !name.isEmpty else {
            errorMessage = "Please enter an event name"
            showError = true
            return
        }
        
        guard let location = location, let coordinates = coordinates else {
            errorMessage = "Please select a location for the event"
            showError = true
            return
        }
        
        guard !maxParticipants.isEmpty, let maxParticipantsInt = Int(maxParticipants), maxParticipantsInt > 0 else {
            errorMessage = "Please enter a valid number of maximum participants"
            showError = true
            return
        }
        
        isLoading = true
        
        // Get current user ID
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "You must be logged in to create an event"
            showError = true
            isLoading = false
            return
        }
        
        // Create event data
        let eventData: [String: Any] = [
            "name": self.name,
            "description": self.description,
            "type": self.type,
            "views": "0",
            "location": location,
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
            "latitude": coordinates.latitude,
            "longitude": coordinates.longitude,
            "status": "active"
        ]
        
        // Add event to Firestore
        let docRef = self.db.collection("events").document()
        docRef.setData(eventData) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to create event: \(error.localizedDescription)"
                    self.showError = true
                    self.isLoading = false
                }
                return
            }
            
            let eventId = docRef.documentID
            
            // If there are images, upload them
            if !self.selectedImages.isEmpty {
                self.uploadEventImages(images: self.selectedImages, eventId: eventId)
            } else {
                // No images to upload, we're done
                DispatchQueue.main.async {
                    self.createdEventId = eventId
                    self.eventCreated = true
                    self.isLoading = false
                }
            }
        }
    }
    
    private func uploadEventImages(images: [UIImage], eventId: String) {
        let group = DispatchGroup()
        var imageUrls: [String] = []
        
        for (index, image) in images.enumerated() {
            group.enter()
            
            guard let imageData = image.jpegData(compressionQuality: 0.7) else {
                group.leave()
                continue
            }
            
            let imageRef = storage.child("event_images/\(eventId)_\(index).jpg")
            
            imageRef.putData(imageData, metadata: nil) { [weak self] metadata, error in
                guard let self = self else {
                    group.leave()
                    return
                }
                
                if let error = error {
                    DispatchQueue.main.async {
                        self.errorMessage = "Failed to upload image: \(error.localizedDescription)"
                        self.showError = true
                    }
                    group.leave()
                    return
                }
                
                // Get download URL
                imageRef.downloadURL { [weak self] url, error in
                    guard let self = self else {
                        group.leave()
                        return
                    }
                    
                    if let error = error {
                        DispatchQueue.main.async {
                            self.errorMessage = "Failed to get image URL: \(error.localizedDescription)"
                            self.showError = true
                        }
                        group.leave()
                        return
                    }
                    
                    if let downloadURL = url {
                        imageUrls.append(downloadURL.absoluteString)
                    }
                    
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            
            // Update event with image URLs
            self.db.collection("events").document(eventId).updateData([
                "images": imageUrls
            ]) { [weak self] error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if let error = error {
                        self.errorMessage = "Failed to update event with images: \(error.localizedDescription)"
                        self.showError = true
                    } else {
                        self.createdEventId = eventId
                        self.eventCreated = true
                    }
                    self.isLoading = false
                }
            }
        }
    }
    
    func resetForm() {
        name = ""
        description = ""
        type = "Conference"
        startDate = Date()
        endDate = Date().addingTimeInterval(3600)
        location = nil
        coordinates = nil
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


