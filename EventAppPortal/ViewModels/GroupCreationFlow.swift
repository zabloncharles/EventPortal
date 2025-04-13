//
//  GroupCreationFlow.swift
//  EventAppPortal
//
//  Created by Zablon Charles on 4/12/25.
//

import SwiftUI
import CoreLocation
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

// MARK: - Group Creation Flow

struct GroupCreationFlow: View {
    @ObservedObject var viewModel: CreateGroupViewModel
    @State private var currentStep = 0
    let steps = ["Basic Info", "Details", "Preview"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress Steps
            ProgressStepsView(steps: steps, currentStep: currentStep)
                .padding(.horizontal) .padding(.horizontal)
            
            // Content
            TabView(selection: $currentStep) {
                // MARK: - Page 1: Basic Info
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Group Icon
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.blue, .purple]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 120, height: 120)
                                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                                
                                Image(systemName: categoryIcon(for: viewModel.category))
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                            }
                            
                            Text("Group Icon")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        // Category Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.headline)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(viewModel.categories, id: \.self) { category in
                                        Button(action: { viewModel.category = category }) {
                                            HStack(spacing: 8) {
                                                Image(systemName: categoryIcon(for: category))
                                                    .font(.system(size: 14))
                                                Text(category)
                                                    .font(.subheadline)
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(viewModel.category == category ? Color.blue : Color.gray.opacity(0.1))
                                            .foregroundColor(viewModel.category == category ? .white : .primary)
                                            .cornerRadius(20)
                                        }
                                    }
                                }
                            }
                        }.padding(.horizontal)
                        // Basic Info Section
                        FormSection {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Basic Information")
                                    .font(.headline)
                                    .padding(.bottom, 8)
                                
                                CustomTextField(
                                    title: "Group Name",
                                    placeholder: "Give your group a name",
                                    text: $viewModel.name
                                )
                                
                                CustomTextField(
                                    title: "Description",
                                    placeholder: "Describe your group",
                                    text: $viewModel.description,
                                    isMultiline: true
                                )
                                
                                
                            }
                        }
                        
                        // Next Button
                        ActionButton(title: "Next", gradient: [.blue, .purple]) {
                            withAnimation {
                                currentStep = 1
                            }
                        }
                    }
                    .padding()
                }
                .tag(0)
                
                // MARK: - Page 2: Details
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Privacy Settings
                        FormSection {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Privacy Settings")
                                    .font(.headline)
                                    .padding(.bottom, 8)
                                
                                Toggle(isOn: $viewModel.isPrivate) {
                                    HStack {
                                        Image(systemName: viewModel.isPrivate ? "lock.fill" : "globe")
                                            .foregroundColor(viewModel.isPrivate ? .blue : .gray)
                                        VStack(alignment: .leading) {
                                            Text(viewModel.isPrivate ? "Private Group" : "Public Group")
                                                .font(.subheadline)
                                            Text(viewModel.isPrivate ? "Only invited people can join" : "Anyone can discover and join")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Navigation Buttons
                        HStack(spacing: 16) {
                            ActionButton(title: "Back", gradient: [.gray, .gray]) {
                                withAnimation {
                                    currentStep = 0
                                }
                            }
                            
                            ActionButton(title: "Preview", gradient: [.blue, .purple]) {
                                withAnimation {
                                    currentStep = 2
                                }
                            }
                        }
                    }
                    .padding()
                }
                .tag(1)
                
                // MARK: - Page 3: Preview
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Group Preview using GroupCard
                        GroupCard(
                            group: EventGroup(
                                id: "preview",
                                name: viewModel.name.isEmpty ? "Group Name" : viewModel.name,
                                description: viewModel.description,
                                shortDescription: viewModel.description.isEmpty ? "No description provided" : String(viewModel.description.prefix(50)) + "...",
                                memberCount: 1,
                                imageURL: "",
                                location: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                                createdAt: Date(),
                                createdBy: "preview",
                                isPrivate: viewModel.isPrivate,
                                category: viewModel.category,
                                tags: [],
                                pendingRequests: [],
                                members: [],
                                admins: []
                            )
                        )
                        .padding(.horizontal)
                        Spacer()
                        // Navigation Buttons
                        VStack(spacing: 16) {
                            ActionButton(title: "Create Group", gradient: [.purple, .blue]) {
                                viewModel.createGroup()
                            }
                            
                            Button(action: {
                                withAnimation {
                                    currentStep = 1
                                }
                            }) {
                                Text("Edit Details")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentStep)
        }
        .navigationTitle(steps[currentStep])
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Helper function to get the appropriate icon for each category
    func categoryIcon(for category: String) -> String {
        switch category {
            case "Technology":
                return "desktopcomputer"
            case "Sports":
                return "figure.dance"
            case "Art & Culture":
                return "paintbrush.fill"
            case "Music":
                return "music.note.list"
            case "Food":
                return "fork.knife"
            case "Travel":
                return "airplane"
            case "Environmental":
                return "leaf.arrow.triangle.circlepath"
            case "Literature":
                return "book.fill"
            case "Corporate":
                return "building.2.fill"
            case "Health & Wellness":
                return "heart.fill"
            case "Other":
                return "ellipsis.circle.fill"
            default:
                return "person.3.fill"
        }
    }
}

class CreateGroupViewModel: ObservableObject {
    @Published var name = ""
    @Published var description = ""
    @Published var category = "Technology"
    @Published var isPrivate = false
    @Published var selectedImage: UIImage?
    @Published var showImagePicker = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var groupCreated = false
    @Published var createdGroupId: String?
    
    let categories = [
        "Technology", "Sports", "Art & Culture", "Music", "Food",
        "Travel", "Environmental", "Literature", "Corporate",
        "Health & Wellness", "Other"
    ]
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage().reference()
    
    func createGroup() {
        guard !name.isEmpty else {
            errorMessage = "Please enter a group name"
            showError = true
            return
        }
        
        isLoading = true
        
        // Get current user ID
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "You must be logged in to create a group"
            showError = true
            isLoading = false
            return
        }
        
        // Create short description (first 50 characters)
        let shortDesc = description.isEmpty ? "No description provided" : 
            String(description.prefix(50)) + (description.count > 50 ? "..." : "")
        
        // Create group data
        let groupData: [String: Any] = [
            "name": name,
            "description": description,
            "shortDescription": shortDesc,
            "memberCount": 1,
            "imageURL": "",
            "latitude": 0.0,
            "longitude": 0.0,
            "createdAt": Timestamp(date: Date()),
            "createdBy": userId,
            "isPrivate": isPrivate,
            "category": category,
            "tags": [],
            "pendingRequests": [],
            "members": [userId], // Creator is the first member
            "admins": [userId]   // Creator is the first admin
        ]
        
        // Add group to Firestore
        let docRef = db.collection("groups").document()
        docRef.setData(groupData) { [weak self] error in
            guard let this = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    this.errorMessage = "Failed to create group: \(error.localizedDescription)"
                    this.showError = true
                    this.isLoading = false
                }
                return
            }
            
            let groupId = docRef.documentID
            
            // If there's an image, upload it
            if let image = this.selectedImage {
                this.uploadGroupImage(image: image, groupId: groupId)
            } else {
                // No image to upload, we're done
                DispatchQueue.main.async {
                    this.createdGroupId = groupId
                    this.groupCreated = true
                    this.isLoading = false
                }
            }
        }
    }
    
    private func uploadGroupImage(image: UIImage, groupId: String) {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to process image"
                self.showError = true
                self.isLoading = false
            }
            return
        }
        
        let imageRef = storage.child("group_images/\(groupId).jpg")
        
        imageRef.putData(imageData, metadata: nil) { [weak self] metadata, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to upload image: \(error.localizedDescription)"
                    self.showError = true
                    self.isLoading = false
                }
                return
            }
            
            // Get download URL
            imageRef.downloadURL { [weak self] url, error in
                guard let self = self else { return }
                
                if let error = error {
                    DispatchQueue.main.async {
                        self.errorMessage = "Failed to get image URL: \(error.localizedDescription)"
                        self.showError = true
                        self.isLoading = false
                    }
                    return
                }
                
                guard let downloadURL = url else {
                    DispatchQueue.main.async {
                        self.errorMessage = "Failed to get download URL"
                        self.showError = true
                        self.isLoading = false
                    }
                    return
                }
                
                // Update group with image URL
                self.db.collection("groups").document(groupId).updateData([
                    "imageURL": downloadURL.absoluteString
                ]) { [weak self] error in
                    guard let self = self else { return }
                    
                    DispatchQueue.main.async {
                        if let error = error {
                            self.errorMessage = "Failed to update group with image: \(error.localizedDescription)"
                            self.showError = true
                        } else {
                            self.createdGroupId = groupId
                            self.groupCreated = true
                        }
                        self.isLoading = false
                    }
                }
            }
        }
    }
    
    func resetForm() {
        name = ""
        description = ""
        category = "Technology"
        isPrivate = false
        selectedImage = nil
        errorMessage = nil
        showError = false
        groupCreated = false
        createdGroupId = nil
    }
}


