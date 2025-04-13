import SwiftUI
import MapKit
import FirebaseFirestore
import FirebaseStorage
import PhotosUI


// MARK: - Main View

struct CreateView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var eventViewModel = CreateEventViewModel()
    @StateObject private var groupViewModel = CreateGroupViewModel()
    @State private var creationType: CreationType = .none

    var body: some View {
        NavigationView {
            VStack {
                switch creationType {
                case .none:
                    SelectionView(creationType: $creationType)
                case .event:
                    EventCreationFlow(viewModel: eventViewModel)
                case .group:
                    GroupCreationFlow(viewModel: groupViewModel)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if creationType != .none {
                        Button("Back") {
                            creationType = .none
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Selection View

struct SelectionView: View {
    @Binding var creationType: CreationType
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Create New")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Choose what you'd like to create")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            // Event Option
            CreationOptionButton(
                title: "Create Event",
                subtitle: "Organize and host events",
                icon: "calendar",
                gradient: [.blue, .purple]
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
    @State private var showImagePicker = false
    @State private var animateFields = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Event Type Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("What type of event is this?")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 12) {
                    ForEach(EventType.allCases, id: \.self) { type in
                        EventTypeButton(
                            type: type,
                            isSelected: viewModel.type == type,
                            action: { viewModel.type = type }
                        )
                    }
                }
            }
            .opacity(animateFields ? 1 : 0)
            .offset(y: animateFields ? 0 : 20)
            
            // Event Name
            VStack(alignment: .leading, spacing: 8) {
                Text("Give your event a name")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Choose a clear, descriptive name that will attract attendees")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                CustomTextField(
                    text: $viewModel.name,
                    placeholder: "Event Name",
                    icon: "textformat"
                )
            }
            .opacity(animateFields ? 1 : 0)
            .offset(y: animateFields ? 0 : 20)
            
            // Event Description
            VStack(alignment: .leading, spacing: 8) {
                Text("Describe your event")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Tell people what to expect and why they should attend")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                TextEditor(text: $viewModel.description)
                    .frame(height: 120)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            .opacity(animateFields ? 1 : 0)
            .offset(y: animateFields ? 0 : 20)
            
            // Event Images
            VStack(alignment: .leading, spacing: 8) {
                Text("Add event images")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Upload photos that showcase your event (optional)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        Button(action: { showImagePicker = true }) {
                            VStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 30))
                                Text("Add Photo")
                                    .font(.caption)
                            }
                            .frame(width: 100, height: 100)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        
                        ForEach(viewModel.selectedImages, id: \.self) { image in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    Button(action: {
                                        viewModel.selectedImages.removeAll { $0 == image }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.white)
                                            .background(Color.black.opacity(0.5))
                                            .clipShape(Circle())
                                    }
                                    .padding(4),
                                    alignment: .topTrailing
                                )
                        }
                    }
                }
            }
            .opacity(animateFields ? 1 : 0)
            .offset(y: animateFields ? 0 : 20)
            
            Spacer()
            
            // Next Button
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
            .disabled(viewModel.name.isEmpty || viewModel.description.isEmpty)
            .opacity(animateFields ? 1 : 0)
            .offset(y: animateFields ? 0 : 20)
        }
        .padding()
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImages: $viewModel.selectedImages)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3)) {
                animateFields = true
            }
        }
    }
}

struct EventTypeButton: View {
    let type: EventType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.system(size: 24))
                Text(type.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .foregroundColor(isSelected ? .blue : .primary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
    }
}

struct DateTimeView: View {
    @ObservedObject var viewModel: CreateEventViewModel
    let onBack: () -> Void
    let onNext: () -> Void
    @State private var animateFields = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Start Date & Time
            VStack(alignment: .leading, spacing: 8) {
                Text("When does your event start?")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Choose the date and time your event begins")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                DatePicker(
                    "Start Date",
                    selection: $viewModel.startDate,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .opacity(animateFields ? 1 : 0)
            .offset(y: animateFields ? 0 : 20)
            
            // End Date & Time
            VStack(alignment: .leading, spacing: 8) {
                Text("When does your event end?")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Choose the date and time your event concludes")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                DatePicker(
                    "End Date",
                    selection: $viewModel.endDate,
                    in: viewModel.startDate...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .opacity(animateFields ? 1 : 0)
            .offset(y: animateFields ? 0 : 20)
            
            Spacer()
            
            // Navigation Buttons
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
            }
            .opacity(animateFields ? 1 : 0)
            .offset(y: animateFields ? 0 : 20)
        }
        .padding()
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3)) {
                animateFields = true
            }
        }
    }
}

struct LocationDetailsView: View {
    @ObservedObject var viewModel: CreateEventViewModel
    let onBack: () -> Void
    let onNext: () -> Void
    @State private var showLocationSearch = false
    @State private var animateFields = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Location Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Where is your event?")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Choose the location where your event will take place")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
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
                        center: location.coordinates,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )))
                    .frame(height: 200)
                    .cornerRadius(12)
                }
            }
            .opacity(animateFields ? 1 : 0)
            .offset(y: animateFields ? 0 : 20)
            
            // Price
            VStack(alignment: .leading, spacing: 8) {
                Text("How much does it cost?")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Set the price per ticket for your event")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                HStack {
                    Text("$")
                        .foregroundColor(.gray)
                    TextField("0.00", value: $viewModel.price, format: .number)
                        .keyboardType(.decimalPad)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .opacity(animateFields ? 1 : 0)
            .offset(y: animateFields ? 0 : 20)
            
            // Maximum Participants
            VStack(alignment: .leading, spacing: 8) {
                Text("How many people can join?")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Set the maximum number of participants")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                TextField("Maximum Participants", value: $viewModel.maxParticipants, format: .number)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
            .opacity(animateFields ? 1 : 0)
            .offset(y: animateFields ? 0 : 20)
            
            // Private Event Toggle
            VStack(alignment: .leading, spacing: 8) {
                Text("Event Visibility")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Make your event private or public")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Toggle("Private Event", isOn: $viewModel.isPrivate)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
            .opacity(animateFields ? 1 : 0)
            .offset(y: animateFields ? 0 : 20)
            
            Spacer()
            
            // Navigation Buttons
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
                .disabled(viewModel.location == nil)
                .opacity(viewModel.location == nil ? 0.6 : 1)
            }
            .opacity(animateFields ? 1 : 0)
            .offset(y: animateFields ? 0 : 20)
        }
        .padding()
        .sheet(isPresented: $showLocationSearch) {
            LocationSearchView(isPresented: $showLocationSearch) { address, coordinates in
                viewModel.location = EventLocation(address: address, coordinates: coordinates)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3)) {
                animateFields = true
            }
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
                        location: (viewModel.location?.isEmpty ?? false ? "Location not set" : viewModel.location) ?? "",
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
// MARK: - Preview

struct CreateView_Previews: PreviewProvider {
    static var previews: some View {
        CreateView()
    }
}







