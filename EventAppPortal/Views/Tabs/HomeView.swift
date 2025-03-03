import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Featured Events Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Featured Events")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(0..<3) { _ in
                                    FeaturedEventCard()
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Nearby Events Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Nearby Events")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        VStack(spacing: 15) {
                            ForEach(0..<5) { _ in
                                EventCard()
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Home")
        }
    }
}

struct FeaturedEventCard: View {
    var body: some View {
        VStack(alignment: .leading) {
            Image(systemName: "photo")
                .resizable()
                .scaledToFill()
                .frame(width: 280, height: 160)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Event Title")
                    .font(.headline)
                Text("Location")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text("Date")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 8)
        }
        .frame(width: 280)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

struct EventCard: View {
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: "photo")
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Event Title")
                    .font(.headline)
                Text("Location")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text("Date")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

#Preview {
    HomeView()
} 