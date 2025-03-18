import SwiftUI

struct RecommendedEventsView: View {
    @StateObject private var viewModel = RecommendedEventsViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recommended for You")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding(.horizontal)
            
            if let error = viewModel.error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.subheadline)
                    .padding(.horizontal)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(viewModel.recommendedEvents) { event in
                        RecommendedEventCardView(event: event)
                            .onAppear {
                                self.viewModel.recordEventInteraction(event, type: .view)
                            }
                    }
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            self.viewModel.loadRecommendedEvents()
        }
    }
}

private struct RecommendedEventCardView: View {
    let event: Event
    
    var body: some View {
        NavigationLink(destination: ViewEventDetail(event: self.event)) {
            VStack(alignment: .leading, spacing: 8) {
                // Event Image
                if let firstImage = self.event.images.first {
                    AsyncImage(url: URL(string: firstImage)) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .foregroundColor(.gray.opacity(0.2))
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(width: 240, height: 135)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    // Event Type
                    Text(self.event.type)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                    
                    // Event Name
                    Text(self.event.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    // Date and Location
                    HStack(spacing: 8) {
                        // Date
                        Label(self.event.startDate.formatted(date: .abbreviated, time: .shortened),
                              systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Participants
                        Label("\(self.event.participants.count)",
                              systemImage: "person.2")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 8)
            }
            .frame(width: 240)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RecommendedEventsView_Previews: PreviewProvider {
    static var previews: some View {
        RecommendedEventsView()
    }
} 