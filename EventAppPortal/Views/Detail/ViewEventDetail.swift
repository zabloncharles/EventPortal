import SwiftUI
import MapKit



struct ViewEventDetail: View {
    var event: Event
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var tabBarManager = TabBarVisibilityManager.shared
    @State private var currentPage = 0
    @State private var isDescriptionExpanded = false
    @State private var showTicket = false
    @State private var showPurchaseView = false
    @State private var hasTicket = false
    @State private var bookmarked = false
    let hapticFeedback = UINotificationFeedbackGenerator()
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Header Image with Paging Dots
                        ZStack(alignment: .top) {
                            // Image
                            TabView(selection: $currentPage) {
                                ForEach(event.images.indices, id: \.self) { index in
                                    Image(event.images[index])
                                        .resizable()
                                        .scaledToFill()
                                        .tag(index)
                                }
                            }
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                            .frame(height: 400)
                          
                            .background(Color.red)
                          
                         
                            
                            // Page Indicator
                            HStack(spacing: 8) {
                                ForEach(0..<event.images.count, id: \.self) { index in
                                    Circle()
                                        .fill(currentPage == index ? Color.white : Color.white.opacity(0.5))
                                        .frame(width: 8, height: 8)
                                }
                            }
                            .padding(.top, 370)
                        }
                        
                        VStack(alignment: .leading, spacing: 24) {
                            // Title and Views
                            VStack {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(event.name)
                                            .font(.title)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.linearGradient(colors: [.pink, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        //event location county
                                        HStack {
                                            Text("New York City")
                                               
                                            Image(systemName: "location")
                                        } .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 4) {
                                        Image(systemName: "eye.square")
                                        Text("\(4)k")
                                    }
                                    .foregroundStyle(.linearGradient(colors: [.pink, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                                }
                                // Event Type Icons
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(alignment: .top, spacing: 16) {
                                        EventTypeIcon(icon: "display", text: "Technology")
                                        
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 1, height: 40)
                                        
                                        EventTypeIcon(icon: "hand.raised.slash", text: "18+")
                                        
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 1, height: 40)
                                        
                                        EventTypeIcon(icon: "person.2", text: "Going \(event.participants.count)")
                                        
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 1, height: 40)
                                        
                                        EventTypeIcon(icon: "stairs", text: "1 Floor")
                                        
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 1, height: 40)
                                        
                                        EventTypeIcon(icon: "hand.raised.slash", text: "18+")
                                    }
                                    
                                }
                                   
                                }.padding(.vertical)
                                
                                .background(Color.dynamic)
                                .cornerRadius(16)
                                    .padding(.top,-15)
                                .padding(.bottom,-20)
                            
                            // Event Type Icons
                            
                            
                            
                            
                            // Description
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(event.description)
                                        .foregroundColor(.secondary)
                                        .lineLimit(isDescriptionExpanded ? nil : 2)
                                        .animation(.easeInOut, value: isDescriptionExpanded)
                                    
                                    Button(action: {
                                        withAnimation {
                                            isDescriptionExpanded.toggle()
                                        }
                                    }) {
                                        Text(isDescriptionExpanded ? "Read Less" : "Read More")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.blue)
                                    }
                                    .padding(.top, 4)
                                }
                            }
                            
                            // Event Facilitator
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Event Facilitator")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                
                                HStack {
                                    Image("bob") // Replace with actual facilitator image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 50, height: 50)
                                        .clipShape(Circle())
                                    
                                    VStack(alignment: .leading) {
                                        Text("Bob")
                                            .fontWeight(.semibold)
                                        Text("Event Facilitator")
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 16) {
                                        Button(action: {}) {
                                            Image(systemName: "message")
                                                .foregroundColor(.blue)
                                        }
                                        
                                        Button(action: {}) {
                                            Image(systemName: "phone")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                            }
                            
                            // Location
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Location")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                
                                LocationMapView(coordinate: CLLocationCoordinate2D(
                                    latitude:
                                    40.7128,
                                    longitude:  -74.0060
                                ))
                                .frame(height: 200)
                                .cornerRadius(12)
                                
                                HStack {
                                    Text(event.location)
                                    Spacer()
                                    Text("Get directions")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.blue)
                                }.foregroundColor(.secondary)
                                    .padding(.top, 8)
                            }
                            
                            // Recommended Events
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Recommended Events")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(sampleEvents) { event in
                                            NavigationLink(destination: ViewEventDetail(event: event)) {
                                                RecommendedEventCard(event: event)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        
                        
                    }.padding(.bottom,130) //makes sure the bottom bar is not covering content in this vstack scroll section
                }
                .ignoresSafeArea()
            .navigationBarHidden(true)
            .offset(y: showTicket ? -90 : 0) //move the view up when ticket is shown
            .animation(.spring(), value: showTicket) //use the spring animation to move the view up
              
                
                // Bottom Bar that is on top of the other sections
                VStack {
                    
                    //make the ticketview full screen
                    if !showTicket {
                        Spacer()
                    }
                    
                   
                    
                    VStack {
                    
                        // Add the ticket sheet
                        if showTicket {
                           
                            TicketView(event: event, isShowing: $showTicket)
                                .transition(.move(edge: .bottom))
                        }
                        HStack(alignment: .center) {
                            VStack(alignment: .leading) {
                                Text("$\(String(format: "%.2f", 29.99))")
                                    .font(.title2)
                                    .fontWeight(.bold)
                              
                                Text("This is a paid technology event")
                                    .foregroundColor(.secondary)
                                    .font(.callout)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                hapticFeedback.notificationOccurred(.success)
                                withAnimation(.spring()) {
                                    if hasTicket {
                                        showTicket.toggle()
                                    } else {
                                        showPurchaseView.toggle()
                                    }
                                }
                            }) {
                                Text(hasTicket ? (showTicket ? "Hide Ticket" : "View Ticket") : "Buy Ticket")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(showTicket ? Color.gray : (hasTicket ? Color.green : Color.blue))
                                    .animation(.easeInOut, value: showTicket)
                                    .cornerRadius(25)
                            }
                        }
                        .padding()
                        .background(
                            LinearGradient(colors: [.dynamic, .clear], startPoint: .bottom, endPoint: .top)
                            
                        )
                    }.background(Color.dynamic.opacity(showTicket ? 0 : 0.99))
                        .background(.ultraThinMaterial)
                }
            }
                .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showPurchaseView) {
                PurchaseTicketView(event: event, isPresented: $showPurchaseView, hasTicket: $hasTicket)
            }
            .onAppear {
                tabBarManager.hideTab = true
                
                DispatchQueue.main.asyncAfter(deadline:.now() + 1) {
                    //
                    tabBarManager.hideTab = true
                }
            }
            .onDisappear {
                tabBarManager.hideTab = false
        }
        }.navigationTitle(event.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Image(systemName: bookmarked ? "bookmark.fill" : "bookmark")
                    .foregroundColor(bookmarked ? .blue : .white)
                    .onTapGesture {
                        bookmarked.toggle()
                    }
                    .padding(10)
                    
            }
    }
}

struct EventTypeIcon: View {
    let icon: String
    let text: String
    
    var body: some View {
       HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
            Text(text)
                .font(.caption)
                .lineLimit(1)
           
       }
        .foregroundColor(.secondary)
    }
}

struct TicketView: View {
    var event: Event
    @Binding var isShowing: Bool
    @State private var offset: CGFloat = UIScreen.main.bounds.height
    @GestureState private var dragOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag Indicator
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.gray.opacity(isShowing ? 0.3 : 0))
                .frame(width: 40, height: 5)
                .padding(.top, 10)
            
            // Header with close button
            HStack {
                Spacer()
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isShowing = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            
            ScrollView {
                VStack(spacing: 24) {
                    Text("Ticket Pass")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // Main Ticket Card
                    VStack(spacing: 20) {
                        // Cities and Time
                        HStack(alignment: .top) {
                            // Departure
                            VStack(alignment: .leading, spacing: 4) {
                                Text("CGK")
                                    .font(.system(size: 32, weight: .bold))
                                Text("New York")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text("14:35")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                            
                            Spacer()
                            
                            // Flight Icon and Duration
                            VStack(spacing: 4) {
                                Image(systemName: "airplane")
                                    .font(.title2)
                                
                                Text("16h 30m")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 60)
                            
                            Spacer()
                            
                            // Arrival
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("WAW")
                                    .font(.system(size: 32, weight: .bold))
                                Text("Warsawa")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text("15:45")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                        }
                        
                        // Progress Line
                        HStack(spacing: 0) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 12, height: 12)
                            
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                                .overlay(
                                    Image(systemName: "clock")
                                        .foregroundColor(.gray)
                                        .background(Color.black)
                                )
                            
                            Circle()
                                .stroke(Color.gray, lineWidth: 1)
                                .frame(width: 12, height: 12)
                        }
                        
                        // Flight Details Grid
                        HStack(spacing: 30) {
                         
                        }
                    }
                    .padding(24)
                    .background(Color.black)
                    .cornerRadius(20)
                    
                    // Ticket Code and Barcode
                    VStack(spacing: 12) {
                        Text("Ticket Code: C7G2K679H92")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Image(systemName: "barcode")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                            
                        // Flight Details Grid
                        HStack(spacing: 0) {
                            TicketDetailColumn(title: "Class", value: "Economy")
                            
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 1, height: 40)
                            
                            TicketDetailColumn(title: "Terminal", value: "F2")
                            
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 1, height: 40)
                            
                            TicketDetailColumn(title: "Gate", value: "32")
                            
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 1, height: 40)
                            
                            TicketDetailColumn(title: "Seat", value: "8A")
                        }
                        .padding(.vertical, 20)
                        .background(Color.black)
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
        }
        .background(Color.dynamic)
        .cornerRadius(20)
        .shadow(radius: 10)
        .padding()
        .offset(y: offset + dragOffset)
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    if value.translation.height > 0 {
                        state = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height > 100 {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isShowing = false
                        }
                    } else {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            offset = 0
                        }
                    }
                }
        )
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                offset = 0
            }
        }
        .onChange(of: isShowing) { newValue in
            if !newValue {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    offset = UIScreen.main.bounds.height
                }
            }
        }
    }
}

struct TicketDetailColumn: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
    }
}

struct PurchaseTicketView: View {
    var event: Event
    @Binding var isPresented: Bool
    @Binding var hasTicket: Bool
    @State private var selectedPaymentMethod = 0
    @State private var isProcessing = false
    @State private var cardNumber = ""
    @State private var cardExpiry = ""
    @State private var cardCVV = ""
    @State private var cardHolderName = ""
    @State private var isCardFlipped = false
    let hapticFeedback = UINotificationFeedbackGenerator()
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Ticket Summary
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Ticket Summary")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("Event")
                                    .foregroundColor(.white)
                                Spacer()
                                Text(event.name)
                                    .foregroundColor(.gray)
                            }
                            
                            HStack {
                                Text("Date")
                                    .foregroundColor(.white)
                                Spacer()
                                Text("Mar 15, 2024")
                                    .foregroundColor(.gray)
                            }
                            
                            HStack {
                                Text("Time")
                                    .foregroundColor(.white)
                                Spacer()
                                Text("14:35")
                                    .foregroundColor(.gray)
                            }
                            
                            Divider()
                                .background(Color.gray.opacity(0.3))
                            
                            HStack {
                                Text("Total")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Spacer()
                                Text("$29.99")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                    
                    // Credit Card Preview with Flip
                    if selectedPaymentMethod == 0 {
                        ZStack {
                            CreditCardView(
                                cardNumber: cardNumber,
                                cardHolderName: cardHolderName,
                                expiryDate: cardExpiry
                            )
                            .opacity(isCardFlipped ? 0 : 1)
                            .rotation3DEffect(.degrees(isCardFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                            
                            BackCardView(cvv: cardCVV)
                                .opacity(isCardFlipped ? 1 : 0)
                                .rotation3DEffect(.degrees(isCardFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
                        }
                        .animation(.easeInOut(duration: 0.5), value: isCardFlipped)
                        
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    }
                    
                    // Payment Method
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Payment Method")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Picker("Payment Method", selection: $selectedPaymentMethod) {
                            Text("Credit Card").tag(0)
                            Text("Apple Pay").tag(1)
                            Text("PayPal").tag(2)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .colorScheme(.dark)
                        .animation(.easeInOut(duration: 0.3), value: selectedPaymentMethod)
                        
                        if selectedPaymentMethod == 0 {
                            VStack(spacing: 16) {
                                TextField("Card Holder Name", text: $cardHolderName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .colorScheme(.dark)
                                    .textInputAutocapitalization(.words)
                                    .onTapGesture {
                                        withAnimation {
                                            isCardFlipped = false
                                        }
                                    }
                                
                                TextField("Card Number", text: $cardNumber)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .colorScheme(.dark)
                                    .keyboardType(.numberPad)
                                    .onChange(of: cardNumber) { newValue in
                                        // Format card number with spaces
                                        
                                        let filtered = newValue.filter { $0.isNumber }
                                        if filtered.count > 16 {
                                            cardNumber = String(filtered.prefix(16))
                                        } else {
                                            cardNumber = filtered.enumerated().map { index, char in
                                                if index > 0 && index % 4 == 0 {
                                                    return " \(char)"
                                                }
                                                return String(char)
                                            }.joined()
                                        }
                                    }
                                    .onTapGesture {
                                        withAnimation {
                                            isCardFlipped = false
                                        }
                                    }
                                
                                HStack {
                                    TextField("MM/YY", text: $cardExpiry)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .colorScheme(.dark)
                                        .keyboardType(.numberPad)
                                        .onTapGesture {
                                            withAnimation {
                                                isCardFlipped = false
                                            }
                                        }
                                        .onChange(of: cardExpiry) { newValue in
                                            let filtered = newValue.filter { $0.isNumber }
                                            if filtered.count > 4 {
                                                cardExpiry = String(filtered.prefix(4))
                                            } else if filtered.count > 2 {
                                                cardExpiry = String(filtered.prefix(2)) + "/" + String(filtered.dropFirst(2))
                                            } else {
                                                cardExpiry = filtered
                                            }
                                        }
                                    
                                    SecureField("CVV", text: $cardCVV)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .colorScheme(.dark)
                                        .keyboardType(.numberPad)
                                        .onChange(of: cardCVV) { newValue in
                                            if newValue.count > 3 {
                                                cardCVV = String(newValue.prefix(3))
                                            }
                                        }
                                    .onTapGesture {
                                        withAnimation {
                                            isCardFlipped = true
                                        }
                                    }
                                    .onSubmit {
                                        withAnimation {
                                            isCardFlipped = false
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Purchase Button
                    Button(action: {
                        isProcessing = true
                        hapticFeedback.notificationOccurred(.success)
                        
                        // Simulate payment processing
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            isProcessing = false
                            hasTicket = true
                            isPresented = false
                        }
                    }) {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding(.trailing, 8)
                            }
                            Text(isProcessing ? "Processing..." : "Purchase Ticket")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .opacity(isProcessing ? 0.8 : 1)
                    }
                    .disabled(isProcessing)
                }
                .padding() .padding(.bottom,30)
            }
            .background(Color.dynamic)
            .navigationTitle("Purchase Ticket")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationBarItems(trailing: Button("Cancel") {
                isPresented = false
            }
            .foregroundColor(.white))
           
        }
        .preferredColorScheme(.dark)
        
    }
}

struct CreditCardView: View {
    var cardNumber: String
    var cardHolderName: String
    var expiryDate: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "creditcard.fill")
                    .font(.title)
                Spacer()
                Image(systemName: "wave.3.right")
                    .font(.title2)
            }
            .foregroundColor(.white)
            
            // Card Number
            Text(cardNumber.isEmpty ? "•••• •••• •••• ••••" : cardNumber)
                .font(.system(.title2, design: .monospaced))
                .foregroundColor(.white)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CARD HOLDER")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text(cardHolderName.isEmpty ? "YOUR NAME" : cardHolderName.uppercased())
                        .font(.callout)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("EXPIRES")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text(expiryDate.isEmpty ? "MM/YY" : expiryDate)
                        .font(.callout)
                        .foregroundColor(.white)
                }
            }
        }
        .padding(20)
        .padding(.vertical,20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

struct BackCardView: View {
    var cvv: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Black magnetic stripe
            Rectangle()
                .fill(Color.black)
                .frame(height: 50)
                .padding(.top)
            
            // CVV strip
            HStack {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("CVV")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    ZStack(alignment: .trailing) {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 60, height: 30)
                        
                        Text(cvv.isEmpty ? "•••" : cvv)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.trailing, 8)
                    }
                }
                .padding(.trailing)
            }
            
            Spacer()
        }
        .padding(20)
        .padding(.vertical,20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

struct LocationMapView: View {
    let coordinate: CLLocationCoordinate2D
    
    var body: some View {
        Map(coordinateRegion: .constant(MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )), interactionModes: [], annotationItems: [MapPin(coordinate: coordinate)]) { pin in
            MapMarker(coordinate: pin.coordinate, tint: .red)
        }
    }
}

struct MapPin: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

struct ViewEventDetail_Previews: PreviewProvider {
    static var previews: some View {
        ViewEventDetail(event: sampleEvent)
    }
}

struct RecommendedEventCard: View {
    var event: Event = sampleEvent
    let colors: [Color] = [.red, .blue, .green, .orange]
    var body: some View {
        VStack(alignment: .leading) {
            // Event Image
            
            RoundedRectangle(cornerRadius: 0)
                .fill(Color.gray.opacity(0))
                .frame(height: 160)
                .background(Image(event.images[0]) // Replace with your event image
                    .resizable()
                    .aspectRatio(contentMode: .fill))
                .overlay(
                    VStack {
                        HStack {
                            Spacer()
                            Text(event.type)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                            .foregroundStyle(.linearGradient(colors: [.pink, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .padding(.horizontal,5)
                            .padding(.vertical,2)
                            .background(.ultraThinMaterial)
                            .background(LinearGradient(colors: [.dynamic.opacity(0.60)], startPoint: .bottom, endPoint: .top))
                            .cornerRadius(15)
                        }
                        Spacer()
                    }.padding()
                )
                .padding(.bottom,-20)
            
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Mar 20")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(event.name)
                    .font(.headline)
                    .foregroundStyle(.linearGradient(colors: [colors.randomElement() ?? .blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .lineLimit(1)
                
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.gray)
                    Text("New York")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                }
                
               
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 12)
            .padding(.top, 12)
            .background(.ultraThinMaterial)
            
            .background(LinearGradient(colors: [.dynamic.opacity(0.60)], startPoint: .bottom, endPoint: .top))
          
            
        }
        
        .background(Image(event.images[0]) // Replace with your event image
            .resizable()
            .aspectRatio(contentMode: .fill).blur(radius: 40))
        
        .cornerRadius(16)
        .frame(width: 200)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.dynamic.opacity(1), lineWidth: 1)
        )
        
    }
} 
