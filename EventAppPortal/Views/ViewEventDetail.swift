import SwiftUI

struct ViewEventDetail: View {
    var event: Event
    @Environment(\.presentationMode) var presentationMode
    @State private var currentPage = 0
    
    var body: some View {
        ScrollView {
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
                    
                    // Navigation Bar
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial)
                            .cornerRadius(20)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            // Add to bookmarks
                        }) {
                            Image(systemName: "bookmark")
                                .foregroundColor(.white)
                                .padding(10)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 50)
                    
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
                    HStack {
                        Text(event.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "eye")
                            Text("\(4500)")
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    // Event Type Icons
                    HStack(spacing: 20) {
                        EventTypeIcon(icon: "display", text: "Technology")
                        EventTypeIcon(icon: "hand.raised.slash", text: "18+")
                        EventTypeIcon(icon: "person.2", text: "Going \(event.participants.count)")
                        EventTypeIcon(icon: "stairs", text: "1 Floor")
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Text(event.description)
                            .foregroundColor(.secondary)
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
                        
                        // Map View placeholder
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 150)
                            .overlay(
                                Text(event.location)
                                    .foregroundColor(.secondary)
                            )
                    }
                }
                .padding()
                
                // Bottom Bar
                VStack {
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("$\(String(format: "%.2f", 29.99))")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("This is a paid technology event")
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Text("View Ticket")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.green)
                                .cornerRadius(25)
                        }
                    }
                    .padding()
                }
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
    }
}

struct EventTypeIcon: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
            Text(text)
                .font(.caption)
        }
        .foregroundColor(.secondary)
    }
}

struct ViewEventDetail_Previews: PreviewProvider {
    static var previews: some View {
        ViewEventDetail(event: sampleEvent)
    }
} 