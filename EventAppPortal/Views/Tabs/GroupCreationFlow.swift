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
    @Environment(\.dismiss) private var dismiss
    @State private var showLocationSearch = false
    let steps = ["Group Name", "Category", "Description", "Location", "Privacy", "Preview"]
   
    var body: some View {
        VStack(spacing: 0) {
           
            
            // Content
            TabView(selection: $currentStep) {
                // MARK: - Page 1: Group Name
                OnboardingStepView(
                    title: "Group Name",
                    subtitle: "Give your group a memorable name",
                    icon: "textformat",
                    gradient: [.blue, .purple]
                ) {
                    VStack(spacing: 20) {
                        TextField("Group Name", text: $viewModel.name)
                            .font(.title3)
                            .padding()
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        NavigationButtons(
                            onBack: { },
                            onNext: { withAnimation { currentStep = 1 } },
                            isNextDisabled: viewModel.name.isEmpty
                        )
                    }
                    .padding()
                }
                .tag(0)
                
                // MARK: - Page 2: Category
                OnboardingStepView(
                    title: "Choose Category",
                    subtitle: "Select a category for your group",
                    icon: "tag.fill",
                    gradient: [.purple, .blue]
                ) {
                    VStack(spacing: 20) {
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
                            
                            Text(viewModel.category)
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
                                                    .font(.title3)
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(viewModel.category == category ? Color.randomize : Color.gray.opacity(0.1))
                                            .foregroundColor(viewModel.category == category ? .white : .primary)
                                            .cornerRadius(12)
                                        }
                                    }
                                }
                            }
                        }
                       
                        NavigationButtons(
                            onBack: { withAnimation { currentStep = 0 } },
                            onNext: { withAnimation { currentStep = 2 } }
                        ).padding(.top, 20)
                    }
                    .padding()
                }
                .tag(1)
                
                // MARK: - Page 3: Description
                OnboardingStepView(
                    title: "Description",
                    subtitle: "Tell people about your group",
                    icon: "text.justify",
                    gradient: [.green, .blue]
                ) {
                    VStack(spacing: 20) {
                        TextEditor(text: $viewModel.description)
                            .frame(height: 200)
                            .font(.title3)
                            .padding()
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        NavigationButtons(
                            onBack: { withAnimation { currentStep = 1 } },
                            onNext: { withAnimation { currentStep = 3 } },
                            isNextDisabled: viewModel.description.isEmpty
                        )
                    }
                    .padding()
                }
                .tag(2)
                
                // MARK: - Page 4: Location
                OnboardingStepView(
                    title: "Choose location",
                    subtitle: "Where will your group meet?",
                    icon: "mappin.and.ellipse",
                    gradient: [.red, .orange]
                ) {
                    VStack(spacing: 20) {
                        if let location = viewModel.location {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Selected Location")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                HStack {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundColor(.blue)
                                    Text(location)
                                        .font(.subheadline)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                        
                        Button(action: { showLocationSearch = true }) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.blue)
                                Text(viewModel.location == nil ? "Search Location" : "Change Location")
                                    .foregroundColor(.blue)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        NavigationButtons(
                            onBack: { withAnimation { currentStep = 2 } },
                            onNext: { withAnimation { currentStep = 4 } },
                            isNextDisabled: viewModel.location == nil
                        )
                    }
                    .padding()
                }
                .tag(3)
                
                // MARK: - Page 5: Privacy
                OnboardingStepView(
                    title: "Privacy settings",
                    subtitle: "Control who can join your group",
                    icon: "lock.shield",
                    gradient: [.purple, .blue]
                ) {
                    VStack(spacing: 20) {
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
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        NavigationButtons(
                            onBack: { withAnimation { currentStep = 3 } },
                            onNext: { withAnimation { currentStep = 5 } }
                        )
                    }
                    .padding()
                }
                .tag(4)
                
                // MARK: - Page 6: Preview
                OnboardingStepView(
                    title: "Preview your group",
                    subtitle: "Review all the details before creating",
                    icon: "eye.fill",
                    gradient: [.green, .blue]
                ) {
                    VStack(spacing: 20) {
                        // Group Preview using GroupCard
                        GroupCard(
                            group: EventGroup(
                                id: "preview",
                                name: viewModel.name.isEmpty ? "Group Name" : viewModel.name,
                                description: viewModel.description,
                                shortDescription: viewModel.description.isEmpty ? "No description provided" : String(viewModel.description.prefix(50)) + "...",
                                memberCount: 1,
                                imageURL: "",
                                location: viewModel.coordinates ?? CLLocationCoordinate2D(latitude: 0, longitude: 0),
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
                        
                        VStack(spacing: 16) {
                            Button(action: {
                                viewModel.createGroup()
                            }) {
                                Text("Create Group")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.purple, .blue]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(12)
                            }
                            .disabled(viewModel.isLoading)
                            
                            Button(action: {
                                withAnimation {
                                    currentStep = 4
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
                .tag(5)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentStep)
            
            // Progress Steps
            ProgressStepsView(steps: steps, currentStep: currentStep)
                .padding(.horizontal)
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showLocationSearch) {
            LocationSearchView(isPresented: $showLocationSearch) { address, coordinates in
                viewModel.location = address
                viewModel.coordinates = CLLocationCoordinate2D(latitude: coordinates[0], longitude: coordinates[1])
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
        .alert("Success", isPresented: $viewModel.groupCreated) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your group has been created successfully!")
        }
        .overlay(
            Group {
                if viewModel.isLoading {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                        .overlay(
                            VStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                                Text("Creating group...")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                    .padding(.top, 10)
                            }
                        )
                }
            }
        )
    }
    
    // Helper function to get the appropriate icon for each category
    func categoryIcon(for category: String) -> String {
        switch category {
            case "Technology":
                return "laptopcomputer"
            case "Sports":
                return "sportscourt.fill"
            case "Art & Culture":
                return "paintbrush.fill"
            case "Music":
                return "music.note"
            case "Food":
                return "fork.knife"
            case "Travel":
                return "airplane"
            case "Environmental":
                return "leaf.fill"
            case "Literature":
                return "book.fill"
            case "Corporate":
                return "building.2.fill"
            case "Health & Wellness":
                return "heart.fill"
            case "Other":
                return "questionmark.circle.fill"
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
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var groupCreated = false
    @Published var createdGroupId: String?
    @Published var location: String?
    @Published var coordinates: CLLocationCoordinate2D?
    
    let categories = [
        "Technology",
        "Sports",
        "Art & Culture",
        "Music",
        "Food",
        "Travel",
        "Environmental",
        "Literature",
        "Corporate",
        "Health & Wellness",
        "Other"
    ]
    
    func createGroup() {
        guard let userId = Auth.auth().currentUser?.uid else {
            showError(message: "You must be logged in to create a group")
            return
        }
        
        guard !name.isEmpty else {
            showError(message: "Please enter a group name")
            return
        }
        
        guard !description.isEmpty else {
            showError(message: "Please enter a group description")
            return
        }
        
        guard let location = location, let coordinates = coordinates else {
            showError(message: "Please select a location for your group")
            return
        }
        
        isLoading = true
        
        // Create a unique ID for the group
        let groupId = UUID().uuidString
        
        // Create the group data
        let groupData: [String: Any] = [
            "id": groupId,
            "name": name,
            "description": description,
            "shortDescription": String(description.prefix(50)) + "...",
            "memberCount": 1,
            "imageURL": categoryIcon(for: category), // Store the SF Symbol name
            "location": [
                "address": location,
                "coordinates": GeoPoint(
                    latitude: coordinates.latitude,
                    longitude: coordinates.longitude
                )
            ],
            "createdAt": Timestamp(date: Date()),
            "createdBy": userId,
            "isPrivate": isPrivate,
            "category": category,
            "tags": [],
            "pendingRequests": [],
            "members": [userId],
            "admins": [userId]
        ]
        
        // Create the group document
        let db = Firestore.firestore()
        db.collection("groups").document(groupId).setData(groupData) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.showError(message: error.localizedDescription)
                } else {
                    self?.createdGroupId = groupId
                    self?.groupCreated = true
                    self?.resetForm()
                }
            }
        }
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
    
    private func resetForm() {
        name = ""
        description = ""
        category = "Technology"
        isPrivate = false
        isLoading = false
        errorMessage = nil
        showError = false
        groupCreated = false
        createdGroupId = nil
        location = nil
        coordinates = nil
    }
    
    // Helper function to get the appropriate icon for each category
    func categoryIcon(for category: String) -> String {
        switch category {
            case "Technology":
                return "laptopcomputer"
            case "Sports":
                return "sportscourt.fill"
            case "Art & Culture":
                return "paintbrush.fill"
            case "Music":
                return "music.note"
            case "Food":
                return "fork.knife"
            case "Travel":
                return "airplane"
            case "Environmental":
                return "leaf.fill"
            case "Literature":
                return "book.fill"
            case "Corporate":
                return "building.2.fill"
            case "Health & Wellness":
                return "heart.fill"
            case "Other":
                return "questionmark.circle.fill"
            default:
                return "person.3.fill"
        }
    }
}


struct GroupCreationFlow_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            GroupCreationFlow(
                viewModel: CreateGroupViewModel()
            )
        }
    }
}

// MARK: - Group Creation Flow


struct GroupCategoryButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .blue)
                    .frame(width: 50, height: 50)
                    .background(isSelected ? Color.blue : Color.blue.opacity(0.1))
                    .clipShape(Circle())
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(isSelected ? .blue : .gray)
            }
        }
    }
}

// MARK: - Group Input Fields
struct GroupInputFields: View {
    @Binding var name: String
    @Binding var description: String
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Group Name", text: $name)
                .font(.title3)
                .padding()
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            
            TextEditor(text: $description)
                .frame(height: 150)
                .font(.title3)
                .padding()
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            
            NavigationButtons(
                onBack: { },
                onNext: onNext,
                isNextDisabled: name.isEmpty || description.isEmpty
            )
        }
    }
}
