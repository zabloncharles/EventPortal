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

// MARK: - Event Creation Flow

struct EventCreationFlow: View {
    @ObservedObject var viewModel: CreateEventViewModel
    @State private var currentStep = 0
    let steps = ["Basic Info", "Date & Time", "Location & Details", "Preview"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress Steps
            ProgressStepsView(steps: steps, currentStep: currentStep)
                .padding(.horizontal) .padding(.horizontal)
            
            // Content
            TabView(selection: $currentStep) {
                BasicInfoView(viewModel: viewModel) {
                    withAnimation {
                        currentStep = 1
                    }
                }
                .tag(0)
                
                DateTimeView(viewModel: viewModel,
                             onBack: {
                    withAnimation {
                        currentStep = 0
                    }
                },
                             onNext: {
                    withAnimation {
                        currentStep = 2
                    }
                })
                .tag(1)
                
                LocationDetailsView(viewModel: viewModel,
                                    onBack: {
                    withAnimation {
                        currentStep = 1
                    }
                },
                                    onNext: {
                    withAnimation {
                        currentStep = 3
                    }
                })
                .tag(2)
                
                PreviewView(viewModel: viewModel,
                            onBack: {
                    withAnimation {
                        currentStep = 2
                    }
                },
                            onCreateEvent: {
                    viewModel.createEvent()
                })
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentStep)
        }
        .navigationTitle(steps[currentStep])
        .navigationBarTitleDisplayMode(.inline)
    }
}

class CreateEventViewModel: ObservableObject {
    @Published var name = ""
    @Published var description = ""
    @Published var type = "Conference"
    @Published var startDate = Date()
    @Published var endDate = Date().addingTimeInterval(3600) // 1 hour later
    @Published var location = ""
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
    
    func createEvent() {
        guard !name.isEmpty else {
            errorMessage = "Please enter an event name"
            showError = true
            return
        }
        
        guard !location.isEmpty else {
            errorMessage = "Please enter a location"
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
        
        // Geocode location to get coordinates
        geocoder.geocodeAddressString(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to geocode location: \(error.localizedDescription)"
                    self.showError = true
                    self.isLoading = false
                }
                return
            }
            
            guard let placemark = placemarks?.first, let location = placemark.location else {
                DispatchQueue.main.async {
                    self.errorMessage = "Could not find location coordinates"
                    self.showError = true
                    self.isLoading = false
                }
                return
            }
            
            let coordinates = location.coordinate
            
            // Create event data
            let eventData: [String: Any] = [
                "name": self.name,
                "description": self.description,
                "type": self.type,
                "views": "0",
                "location": self.location,
                "price": self.price,
                "owner": userId,
                "organizerName": "Event Organizer", // This could be fetched from user profile
                "shareContactInfo": true,
                "startDate": Timestamp(date: self.startDate),
                "endDate": Timestamp(date: self.endDate),
                "images": [],
                "participants": [userId], // Creator is the first participant
                "maxParticipants": Int(self.maxParticipants) ?? 0,
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
        location = ""
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


