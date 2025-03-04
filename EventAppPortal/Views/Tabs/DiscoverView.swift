import SwiftUI

struct DiscoverView: View {
    @State private var searchText = ""
    @State private var selectedCategory: EventCategory? = nil
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Categories
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(EventCategory.allCases) { category in
                                CategoryButton(
                                    category: category,
                                    isSelected: selectedCategory == category,
                                    action: { selectedCategory = category }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Events Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(0..<10) { _ in
                            DiscoverEventCard()
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Discover")
            .searchable(text: $searchText, prompt: "Search events")
        }
        .appBackground()
    }
}

enum EventCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case sports = "Sports"
    case music = "Music"
    case food = "Food"
    case art = "Art"
    case education = "Education"
    case social = "Social"
    
    var id: String { self.rawValue }
}

struct CategoryButton: View {
    let category: EventCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.rawValue)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(uiColor: .secondarySystemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct DiscoverEventCard: View {
    var body: some View {
        VStack(alignment: .leading) {
            Image(systemName: "photo")
                .resizable()
                .scaledToFill()
                .frame(height: 120)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Event Title")
                    .font(.headline)
                    .lineLimit(1)
                
                Text("Location")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text("Date")
                        .font(.caption)
                }
                .foregroundColor(.blue)
            }
            .padding(.horizontal, 4)
        }
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct DiscoverView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoverView()
    }
} 