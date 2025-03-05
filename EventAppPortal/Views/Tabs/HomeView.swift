import SwiftUI

struct HomeView: View {
    @State private var searchText = ""
    @State private var pageAppeared = false
    @State private var startPoint: UnitPoint = .leading
    @State private var endPoint: UnitPoint = .trailing
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 30) {
                    VStack {
                        HStack {
                            Text("LinkedUp Event Expectations.")
                                .font(.title)
                                .fontWeight(.bold)
                                .padding(.top, 20)
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.invert, .yellow, Color.invert]),
                                        startPoint: startPoint,
                                        endPoint: endPoint
                                    )
                                )
                                .onAppear {
                                    withAnimation(
                                        .linear(duration: 2)
                                    ) {
                                        startPoint = .trailing
                                        endPoint = .leading
                                    }
                                }
                            
                            Spacer()
                            
                            NavigationLink(destination: CreateEventView()) {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .medium))
                                    .frame(width: 36, height: 36)
                                    .background(Color.dynamic)
                                    .cornerRadius(60)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 60)
                                            .stroke(Color.gray, lineWidth: 1)
                                    )
                            }
                            
                            NavigationLink(destination: Text("calendar")) {
                                Image(systemName: "calendar")
                                    .renderingMode(.original)
                                    .font(.system(size: 16, weight: .medium))
                                    .frame(width: 36, height: 36)
                                    .background(Color.dynamic)
                                    .cornerRadius(60)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 60)
                                            .stroke(Color.gray, lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.horizontal)
                        
                        ZStack {
                            Rectangle()
                                .fill(.ultraThinMaterial)
                                .blur(radius: 570)
                            
                            VStack {
                                HStack {
                                    TextField("Search event, party...", text: $searchText)
                                        .padding()
                                        .background(Color(.systemGray6))
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.dynamic, lineWidth: 2)
                                        )
                                }
                                .padding(10)
                                .padding(.top, 0)
                                
                                if searchText.isEmpty {
                                    ForEach(["Community Cleanup", "Yoga Workshop", "Charity Gala"], id: \.self) { eventName in
                                        NavigationLink(destination: ViewEventDetail(event: sampleEvent)) {
                                            VStack {
                                                Divider()
                                                HStack {
                                                    Image(systemName: eventName == "Community Cleanup" ? "arrow.clockwise" :
                                                            eventName == "Yoga Workshop" ? "heart.fill" : "heart")
                                                    Text(eventName)
                                                        .font(.callout)
                                                        .foregroundColor(.primary)
                                                    Spacer()
                                                }
                                                .padding(.vertical, 7)
                                                .padding(.horizontal, 10)
                                                .cornerRadius(9)
                                                .padding(.horizontal)
                                            }
                                            .animation(.spring(), value: searchText.isEmpty)
                                        }
                                    }
                                }
                            }
                            .cornerRadius(20)
                        }
                        .padding(.horizontal)
                    }
                    .offset(y: !pageAppeared ? -UIScreen.main.bounds.height * 0.5 : 0)
                    
                    
                    
                    VStack {
                        // Popular Events Section
                        VStack(alignment: .leading, spacing: 20) {
                            HStack(alignment: .bottom) {
                                VStack(alignment: .leading) {
                                    Text("Popular events")
                                        .font(.headline)
                                    Text("View & join popular events!")
                                        .font(.callout)
                                }
                                Spacer()
                                VStack(alignment: .center) {
                                    Image(systemName: "flame")
                                }
                            }.padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 16) {
                                    ForEach(0..<5) { _ in
                                        NavigationLink(destination: ViewEventDetail(event: sampleEvent)) {
                                            PopularEventCard(event: sampleEvent)
                                                .frame(width: 280)
                                        }
                                    }
                                }.padding(.leading)
                                    .padding(.trailing, 10)
                            }
                        }
                        
                        
                        // Plans Near You Section
                        VStack(alignment: .leading) {
                            HStack(alignment: .bottom) {
                                VStack(alignment: .leading) {
                                    Text("Plans near you")
                                        .font(.headline)
                                    Text("View and join plans near your area!")
                                        .font(.callout)
                                }
                                .padding(.top, 30)
                                Spacer()
                                VStack(alignment: .center) {
                                    Image(systemName: "figure.dance")
                                }
                            }
                            
                            ScrollView(.vertical, showsIndicators: false) {
                                LazyVStack {
                                    ForEach(0..<5) { _ in
                                        NavigationLink(destination: ViewEventDetail(event: sampleEvent)) {
                                            RegularEventCard(event: sampleEvent)
                                        }
                                    }
                                }
                                .padding(.bottom, 70)
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                    .offset(y: !pageAppeared ? UIScreen.main.bounds.height * 0.5 : 0)
                }
                .padding(.bottom)
            }
            .background(Color.dynamic)
            .navigationBarHidden(true)
            .onAppear {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                    pageAppeared = true
                }
            }
        }
    }
}

struct PopularEventCard: View {
    var event: Event = sampleEvent
    let colors: [Color] = [.red, .blue, .green, .orange]
    
    var body: some View {
        VStack {
            ZStack {
                LinearGradient(colors: [.black, .clear], startPoint: .bottomLeading, endPoint: .topTrailing)
                
                ZStack {
                    VStack(alignment: .leading) {
                        HStack {
                            if event.endDate == nil {
                                Text("Ongoing")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("Event")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                            } else {
                                Text(returnMonthOrDay(from: event.startDate ?? Date(), getDayNumber: false).capitalized)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Text(returnMonthOrDay(from: event.startDate ?? Date(), getDayNumber: true))
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.top, 10)
                        Spacer()
                        
                        HStack(alignment: .bottom) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(event.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.clear)
                                    .overlay(
                                        LinearGradient(
                                            gradient: Gradient(colors: [colors.randomElement() ?? .blue, .purple]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                        .mask(
                                            Text(event.name)
                                                .font(.title2)
                                                .fontWeight(.bold)
                                        )
                                    )
                                Text(event.location.components(separatedBy: ",")[0])
                            }
                            .multilineTextAlignment(.leading)
                            Spacer()
                            VStack {
                                ZStack {
                                    ForEach(0..<colors.count, id: \.self) { index in
                                        Circle()
                                            .fill(colors[index])
                                            .frame(width: 15, height: 15)
                                            .offset(x: CGFloat(index * 10 - 0))
                                    }
                                }
                                Text("\(event.participants.count) \(event.participants.count > 1 ? "Participants" : "Participant")")
                                    .font(.footnote)
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    }
                    .padding()
                }
            }
            .background(
                Image(event.images[0])
                    .resizable()
                    .scaledToFill()
            )
            .cornerRadius(20)
        }
    }
    
    func returnMonthOrDay(from date: Date, getDayNumber: Bool) -> String {
        let calendar = Calendar.current
        if getDayNumber {
            let day = calendar.component(.day, from: date)
            return "\(day)"
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM"
            return dateFormatter.string(from: date)
        }
    }
}

struct RegularEventCard: View {
    var event: Event = sampleEvent
    let colors: [Color] = [.red, .blue, .green, .orange]
    
    var body: some View {
        VStack {
            ZStack {
                LinearGradient(colors: [.black, .black.opacity(0.40), .black.opacity(0.60)], startPoint: .bottomLeading, endPoint: .topTrailing)
                
                ZStack {
                    VStack(alignment: .leading) {
                        HStack {
                            if event.endDate == nil {
                                Text("Ongoing")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("Event")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                            } else {
                                Text(returnMonthOrDay(from: event.startDate ?? Date(), getDayNumber: false).capitalized)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Text(returnMonthOrDay(from: event.startDate ?? Date(), getDayNumber: true))
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.top, 10)
                        
                        Spacer()
                        HStack(alignment: .bottom) {
                            Spacer()
                            VStack(alignment: .leading, spacing: 3) {
                                Text(event.description.split(separator: ".")[0] + ".")
                                    .font(.callout)
                                    .foregroundColor(.white)
                                    .padding(.leading)
                                    .lineLimit(2)
                            }.multilineTextAlignment(.trailing)
                        }
                        HStack(alignment: .bottom) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(event.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.clear)
                                    .overlay(
                                        LinearGradient(
                                            gradient: Gradient(colors: [colors.randomElement() ?? .blue, .purple]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                        .mask(
                                            Text(event.name)
                                                .font(.title2)
                                                .fontWeight(.bold)
                                        )
                                    )
                                Text(event.location.components(separatedBy: ",")[0])
                            }.multilineTextAlignment(.leading)
                            Spacer()
                            VStack {
                                ZStack {
                                    ForEach(0..<colors.count, id: \.self) { index in
                                        Circle()
                                            .fill(colors[index])
                                            .frame(width: 15, height: 15)
                                            .offset(x: CGFloat(index * 10 - 0))
                                    }
                                }
                                Text("\(event.participants.count) \(event.participants.count > 1 ? "Participants" : "Participant")")
                                    .font(.footnote)
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    }
                    .padding()
                }
            }
            .background(
                Image(event.images[0])
                    .resizable()
                    .scaledToFill()
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.dynamic.opacity(0.20), lineWidth: 1)
            )
            .cornerRadius(20)
        }.frame(height: 200)
        
    }
    
    func returnMonthOrDay(from date: Date, getDayNumber: Bool) -> String {
        let calendar = Calendar.current
        if getDayNumber {
            let day = calendar.component(.day, from: date)
            return "\(day)"
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM"
            return dateFormatter.string(from: date)
        }
    }
}

struct EventCard: View {
    var event: Event
    let colors: [Color] = [.red, .blue, .green, .orange]
    
    var body: some View {
        ZStack {
            // Background Image with Gradient Overlay
            Image(event.images[0])
                .resizable()
                .scaledToFill()
                .frame(height: 200)
                .clipped()
            
            // Gradient Overlay
            LinearGradient(
                colors: [
                    .black.opacity(0.7),
                    .black.opacity(0.3),
                    .clear
                ],
                startPoint: .bottom,
                endPoint: .top
            )
            
            // Content
            VStack(alignment: .leading, spacing: 0) {
                // Top Date Section
                HStack( spacing: 4) {
                    Text("Feb")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Text("27")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                .padding([.top, .leading])
                
                Spacer()
                
                // Bottom Content Section
                VStack(alignment: .leading, spacing: 8) {
                    // Title with gradient
                    Text(event.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.clear)
                        .overlay(
                            LinearGradient(
                                gradient: Gradient(colors: [.orange, .yellow]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .mask(
                                Text(event.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                            )
                        )
                    
                    // Location and Participants
                    HStack {
                        Text(event.location)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Spacer()
                        
                        // Participant circles
                        HStack(spacing: -5) {
                            ForEach(0..<4, id: \.self) { index in
                                Circle()
                                    .fill(colors[index])
                                    .frame(width: 20, height: 20)
                            }
                        }
                        
                        Text("\(event.participants.count)")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.leading, 5)
                    }
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
        )
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
} 

