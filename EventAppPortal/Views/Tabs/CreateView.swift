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
    @State private var textOffset: CGFloat = 100
    @State private var viewState = CGSize.zero
    @State private var isDragging = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.dynamic.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                   
                    
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
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if creationType != .none {
                        Button(action: { creationType = .none }) {
                            HStack(spacing: 4.0) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .bold))
                                Text("Back")
                            }
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
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 0) {
                Image(systemName: "note.text.badge.plus")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Text("What do\nyou want to")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.purple, Color.invert]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
              
                Text("be apart of?")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.red, .orange]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                HStack(spacing:5) {
                    Image(systemName: "info.circle")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("Choose what you'd like to create")
                        .font(.subheadline)
                    .foregroundColor(.gray)
                }
            }.padding(.horizontal)
            
            
            
            // Event Option
            CreationOptionButton(
                title: "Create Event",
                subtitle: "Organize and host events",
                icon: "bird.fill",
                gradient: [.blue, .purple]
            ) {
                creationType = .event
            }
            Divider()
            // Group Option
            CreationOptionButton(
                title: "Create Group",
                subtitle: "Build a community around shared interests",
                icon: "person.2.fill",
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
        VStack(spacing: 16) {
            // Progress Bar
            HStack(spacing: 4) {
            ForEach(0..<steps.count, id: \.self) { index in
                    Rectangle()
                        .fill(index <= currentStep ? Color.blue : Color(.systemGray5))
                        .frame(height: 4)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
            
           
        }
        .padding(.horizontal, 50)
    }
}

struct BasicInfoView: View {
    @ObservedObject var viewModel: CreateEventViewModel
    let onNext: () -> Void
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                
                
                // Basic Info Section
                FormSection(title: "Basic Information") {
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
                FormSection(title: "Date & Time") {
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
    @State private var showLocationSearch = false
    
    var body: some View {
        VStack(spacing: 20) {
            FormSection(title: "Location & Details") {
                    VStack(alignment: .leading, spacing: 16) {
                    // Location selection button
                    Button(action: {
                        showLocationSearch = true
                    }) {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.blue)
                            Text(viewModel.location?.address ?? "Select Location")
                                .foregroundColor(viewModel.location == nil ? .gray : .primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 2)
                    }
                    
                    // Map preview if location is selected
                    if let location = viewModel.location {
                        MapPreview(coordinates: location.coordinates)
                            .frame(height: 150)
                            .cornerRadius(10)
                    }
                    
                    // Price field
                        CustomTextField(
                            title: "Price",
                        placeholder: "Price (leave empty if free)",
                            text: $viewModel.price,
                            keyboardType: .decimalPad
                        )
                        
                    // Max participants field
                        CustomTextField(
                            title: "Maximum Participants",
                            placeholder: "Enter limit (optional)",
                        text: .init(
                            get: { String(viewModel.maxParticipants) },
                            set: { 
                                if let value = Int($0) {
                                    viewModel.maxParticipants = String(value)
                                }
                            }
                        ),
                        keyboardType: .numberPad
                    )
                    
                    // Private event toggle
                    Toggle("Private Event", isOn: $viewModel.isPrivate)
                        .padding(.vertical, 8)
                }
            }
            
            // Navigation buttons
            HStack {
                Button(action: onBack) {
                    Text("Back")
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Button(action: onNext) {
                    Text("Next")
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(viewModel.location != nil ? Color.blue : Color.gray)
                        .cornerRadius(8)
                }
                .disabled(viewModel.location == nil)
            }
            .padding(.horizontal)
        }
        .sheet(isPresented: $showLocationSearch) {
            LocationSearchView(
                isPresented: $showLocationSearch,
                onLocationSelected: { address, coordinates in
                    viewModel.location = EventLocation(address: address, coordinates: coordinates)
                }
            )
        }
    }
}

struct MapPreview: View {
    let coordinates: [Double]
    
    var body: some View {
        // Implement map preview using coordinates
        Color.gray // Placeholder for now
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
                        location: viewModel.location?.address ?? "Location not set",
                        price: viewModel.price,
                        owner: "preview",
                        organizerName: "Preview Organizer",
                        shareContactInfo: true,
                        startDate: viewModel.startDate,
                        endDate: viewModel.endDate,
                        images: viewModel.selectedImages.isEmpty ? ["placeholder_image"] : viewModel.selectedImages.map { _ in "placeholder_image" },
                        participants: [],
                        maxParticipants: Int(viewModel.maxParticipants) ?? 0,
                        isTimed: true,
                        createdAt: Date(),
                        coordinates: viewModel.location?.coordinates ?? [0.0, 0.0],
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
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 8)
            
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









