class CreateEventViewModel: ObservableObject {
    @Published var name = ""
    @Published var description = ""
    @Published var type: EventType = .other
    @Published var startDate = Date()
    @Published var endDate = Date().addingTimeInterval(3600)
    @Published var location: EventLocation?
    @Published var price = ""
    @Published var maxParticipants = ""
    @Published var isPrivate = false
    @Published var selectedImages: [UIImage] = []
    @Published var imageUrls: [String] = []
    @Published var isCreating = false
    @Published var error: Error?
    @Published var validationErrors: [String] = []
    @Published var showValidationAlert = false
    
    enum ValidationError: LocalizedError {
        case emptyName
        case emptyDescription
        case noLocation
        case invalidMaxParticipants
        case invalidPrice
        case invalidDateRange
        
        var errorDescription: String? {
            switch self {
                case .emptyName:
                    return "Please enter an event name"
                case .emptyDescription:
                    return "Please enter an event description"
                case .noLocation:
                    return "Please select a location for your event"
                case .invalidMaxParticipants:
                    return "Please enter a valid number of maximum participants"
                case .invalidPrice:
                    return "Please enter a valid price"
                case .invalidDateRange:
                    return "End date must be after start date"
            }
        }
    }
    
    private func validate() -> Bool {
        validationErrors.removeAll()
        
        // Check name
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors.append(ValidationError.emptyName.localizedDescription)
        }
        
        // Check description
        if description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors.append(ValidationError.emptyDescription.localizedDescription)
        }
        
        // Check location
        if location == nil {
            validationErrors.append(ValidationError.noLocation.localizedDescription)
        }
        
        // Check max participants
        if maxParticipants.isEmpty || Int(maxParticipants) == nil || Int(maxParticipants)! <= 0 {
            validationErrors.append(ValidationError.invalidMaxParticipants.localizedDescription)
        }
        
        // Check price format (allow empty for free events)
        if !price.isEmpty {
            if Double(price) == nil || Double(price)! < 0 {
                validationErrors.append(ValidationError.invalidPrice.localizedDescription)
            }
        }
        
        // Check date range
        if endDate <= startDate {
            validationErrors.append(ValidationError.invalidDateRange.localizedDescription)
        }
        
        if !validationErrors.isEmpty {
            showValidationAlert = true
            return false
        }
        
        return true
    }
    
    func createEvent() async throws {
        guard !isCreating else { return }
        
        // Validate before proceeding
        guard validate() else {
            return
        }
        
        DispatchQueue.main.async {
            self.isCreating = true
        }
        
        do {
            // Upload images first if any
            if !selectedImages.isEmpty {
                imageUrls = try await uploadImages()
            }
            
            // Create event document
            let db = Firestore.firestore()
            let eventRef = db.collection("events").document()
            
            let event = Event(
                id: eventRef.documentID,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                type: type,
                views: "0",
                location: location?.address ?? "",
                price: price.isEmpty ? "0" : price,
                owner: Auth.auth().currentUser?.uid ?? "",
                organizerName: Auth.auth().currentUser?.displayName ?? "Anonymous",
                shareContactInfo: true,
                startDate: startDate,
                endDate: endDate,
                images: imageUrls,
                participants: [],
                maxParticipants: Int(maxParticipants) ?? 0,
                isTimed: true,
                createdAt: Date(),
                coordinates: location?.coordinates ?? [0.0, 0.0],
                status: "active"
            )
            
            try await eventRef.setData(event.toFirestore())
            
            DispatchQueue.main.async {
                self.isCreating = false
            }
        } catch {
            DispatchQueue.main.async {
                self.isCreating = false
                self.error = error
                self.validationErrors.append(error.localizedDescription)
                self.showValidationAlert = true
            }
            throw error
        }
    }
    
    private func uploadImages() async throws -> [String] {
        var urls: [String] = []
        
        for image in selectedImages {
            guard let imageData = image.jpegData(compressionQuality: 0.7) else { continue }
            
            let storage = Storage.storage()
            let storageRef = storage.reference()
            let imageRef = storageRef.child("events/\(UUID().uuidString).jpg")
            
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            _ = try await imageRef.putDataAsync(imageData, metadata: metadata)
            let downloadURL = try await imageRef.downloadURL()
            urls.append(downloadURL.absoluteString)
        }
        
        return urls
    }
} 