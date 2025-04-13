import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import PhotosUI

// MARK: - View Models and Types




// MARK: - Main View

struct CreateEventView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var eventViewModel = CreateEventViewModel()
    @StateObject private var groupViewModel = CreateGroupViewModel()
    @State private var creationType: CreationType = .none
    
    var body: some View {
        NavigationView {
            Group {
                switch creationType {
                case .none:
                    SelectionView(creationType: $creationType)
                case .event:
                    EventCreationFlow(viewModel: eventViewModel)
                case .group:
                    GroupCreationFlow(viewModel: groupViewModel)
                }
            }
            .navigationBarItems(
                leading: creationType != .none ? Button("Back") {
                    creationType = .none
                } : nil,
                trailing: Button("Cancel") {
                    dismiss()
                }
            )
        }
    }
}

// MARK: - Selection View

struct SelectionView: View {
    @Binding var creationType: CreationType
    
    var body: some View {
        VStack(spacing: 30) {
            Text("What would you like to create?")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 40)
            
            // Event Option
            CreationOptionButton(
                title: "Create Event",
                subtitle: "Host meetups, parties, or gatherings",
                icon: "calendar.badge.plus",
                gradient: [.purple, .blue]
            ) {
                creationType = .event
            }
            
            // Group Option
            CreationOptionButton(
                title: "Create Group",
                subtitle: "Build a community around shared interests",
                icon: "person.3.fill",
                gradient: [.green, .blue]
            ) {
                creationType = .group
            }
            
            Spacer()
        }
                                .padding()
        .navigationTitle("Create")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CreationOptionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradient: [Color]
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: gradient),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(15)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Event Creation Flow Components

struct ProgressStepsView: View {
    let steps: [String]
    let currentStep: Int
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<steps.count, id: \.self) { index in
                VStack(spacing: 8) {
                                        Circle()
                        .fill(currentStep >= index ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 30, height: 30)
                                            .overlay(
                            Text("\(index + 1)")
                                                    .foregroundColor(.white)
                                .font(.headline)
                        )
                    Text(steps[index])
                        .font(.caption)
                        .foregroundColor(currentStep >= index ? .primary : .gray)
                }
                
                if index < steps.count - 1 {
                    Rectangle()
                        .fill(currentStep > index ? Color.blue : Color.gray.opacity(0.3))
                        .frame(height: 2)
                        .padding(.horizontal, 8)
                }
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 30)
    }
}

struct BasicInfoView: View {
    @ObservedObject var viewModel: CreateEventViewModel
    let onNext: () -> Void
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                
                
                // Basic Info Section
                FormSection {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Basic Information")
                            .font(.headline)
                            .padding(.bottom, 8)
                        
                        CustomTextField(
                            title: "Event Name",
                            placeholder: "Give your event a name",
                            text: $viewModel.name
                        )
                        
                        CustomTextField(
                            title: "Description",
                            placeholder: "Describe your event",
                            text: $viewModel.description,
                            isMultiline: true
                        )
                        
                        // Event Type Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Type")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(viewModel.eventTypes, id: \.self) { type in
                                        Button(action: { viewModel.type = type }) {
                                            Text(type)
                                                .font(.subheadline)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(viewModel.type == type ? Color.blue : Color.gray.opacity(0.1))
                                                .foregroundColor(viewModel.type == type ? .white : .primary)
                                                .cornerRadius(20)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                // Images Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Event Photos")
                            .font(.headline)
                        Spacer()
                        Text("\(viewModel.selectedImages.count)/10")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    
                    ImageSelectionView(images: $viewModel.selectedImages, showPicker: $viewModel.showImagePicker)
                }
                // Next Button
                ActionButton(title: "Next", gradient: [.blue, .purple]) {
                    onNext()
                }
            }
            .padding()
        }
    }
}

struct DateTimeView: View {
    @ObservedObject var viewModel: CreateEventViewModel
    let onBack: () -> Void
    let onNext: () -> Void
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Date & Time Section
                FormSection {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Date & Time")
                            .font(.headline)
                            .padding(.bottom, 8)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Start")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            DatePicker("", selection: $viewModel.startDate, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.graphical)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("End")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            DatePicker("", selection: $viewModel.endDate, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                        }
                    }
                }
                
                // Navigation Buttons
                HStack(spacing: 16) {
                    ActionButton(title: "Back", gradient: [.gray, .gray]) {
                        onBack()
                    }
                    
                    ActionButton(title: "Next", gradient: [.blue, .purple]) {
                        onNext()
                    }
                }
            }
            .padding()
        }
    }
}

struct LocationDetailsView: View {
    @ObservedObject var viewModel: CreateEventViewModel
    let onBack: () -> Void
    let onNext: () -> Void
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Location & Details Section
                FormSection {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Location & Details")
                            .font(.headline)
                            .padding(.bottom, 8)
                        
                        CustomTextField(
                            title: "Location",
                            placeholder: "Where will it take place?",
                            text: $viewModel.location,
                            icon: "mappin.circle.fill"
                        )
                        
                        CustomTextField(
                            title: "Price",
                            placeholder: "0.00",
                            text: $viewModel.price,
                            icon: "dollarsign.circle.fill",
                            keyboardType: .decimalPad
                        )
                        
                        CustomTextField(
                            title: "Maximum Participants",
                            placeholder: "Enter limit (optional)",
                            text: $viewModel.maxParticipants,
                            icon: "person.2.fill",
                            keyboardType: .numberPad
                        )
                        
                        Toggle(isOn: $viewModel.isPrivate) {
            HStack {
                                Image(systemName: viewModel.isPrivate ? "lock.fill" : "globe")
                                    .foregroundColor(viewModel.isPrivate ? .blue : .gray)
                                VStack(alignment: .leading) {
                                    Text(viewModel.isPrivate ? "Private Event" : "Public Event")
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
                        onBack()
                    }
                    
                    ActionButton(title: "Preview", gradient: [.blue, .purple]) {
                        onNext()
                    }
                }
            }
            .padding()
        }
    }
}

struct PreviewView: View {
    @ObservedObject var viewModel: CreateEventViewModel
    let onBack: () -> Void
    let onCreateEvent: () -> Void
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Event Preview using RegularEventCard
                RegularEventCard(
                    event: Event(
                        id: "preview",
                        name: viewModel.name.isEmpty ? "Event Name" : viewModel.name,
                        description: viewModel.description,
                        type: viewModel.type,
                        views: "0",
                        location: viewModel.location.isEmpty ? "Location not set" : viewModel.location,
                        price: viewModel.price,
                        owner: "preview",
                        organizerName: "Preview Organizer",
                        shareContactInfo: true,
                        startDate: viewModel.startDate,
                        endDate: viewModel.endDate,
                        images: [],
                        participants: [],
                        maxParticipants: Int(viewModel.maxParticipants) ?? 0,
                        isTimed: true,
                        createdAt: Date(),
                        coordinates: [0.0, 0.0],
                        status: "active"
                    )
                )
                                .padding(.horizontal)
                
                // Navigation Buttons
                VStack(spacing: 16) {
                    ActionButton(title: "Create Event", gradient: [.purple, .blue]) {
                        onCreateEvent()
                    }
                    
                    Button(action: onBack) {
                        Text("Edit Details")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}



struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                .foregroundColor(.gray)
                Text(value)
                    .font(.subheadline)
            }
        }
    }
}

struct CustomTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var isMultiline: Bool = false
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(.blue)
                        .font(.system(size: 20))
                }
                
                if isMultiline {
                    ZStack(alignment: .topLeading) {
                        if text.isEmpty {
                            Text(placeholder)
                                .foregroundColor(.gray.opacity(0.8))
                                .padding(.top, 8)
                                .padding(.leading, 5)
                        }
                        
                        TextEditor(text: $text)
                            .frame(height: 100)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                    }
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
            }
        }
    }
}



// MARK: - Supporting Views

struct FormSection<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 20) {
            content
                                }
                                .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(15)
    }
}

struct ActionButton: View {
    let title: String
    let gradient: [Color]
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                .padding()
                                .background(
                                    LinearGradient(
                        gradient: Gradient(colors: gradient),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                .cornerRadius(15)
        }
        .padding(.horizontal)
    }
}

struct ImageSelectionView: View {
    @Binding var images: [UIImage]
    @Binding var showPicker: Bool
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                Button(action: { showPicker = true }) {
                    VStack {
                        Image(systemName: "plus")
                            .font(.system(size: 30))
                            .foregroundColor(.blue)
                        Text("Add Photos")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .frame(width: 100, height: 100)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                }
                
                ForEach(images, id: \.self) { image in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .cornerRadius(10)
                        .clipped()
                }
            }
            .padding(.horizontal)
        }
    }
}

struct GroupImageSelector: View {
    @Binding var selectedImage: UIImage?
    @Binding var showPicker: Bool
    
    var body: some View {
        Button(action: { showPicker = true }) {
            if let selectedImage = selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .overlay(
                        Image(systemName: "camera.fill")
                            .font(.system(size: 30))
            .foregroundColor(.gray)
                    )
            }
        }
        .padding(.top)
    }
}

// MARK: - Preview

struct Previews_CreateEventView_Previews: PreviewProvider {
    static var previews: some View {
        CreateEventView()
    }
}

struct GroupCreationFlow_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            GroupCreationFlow(viewModel: CreateGroupViewModel())
        }
    }
}
