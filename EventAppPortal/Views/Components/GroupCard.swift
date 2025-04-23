import SwiftUI

struct GroupCard: View {
    let group: EventGroup
    let colors =  [Color.red,Color.blue,Color.green,Color.purple,Color.orange]
    var body: some View {
        NavigationLink(destination: GroupDetailView(group: group)) {
           
                
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(group.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [colors.randomElement() ?? Color.red, .blue]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text(group.shortDescription)
                            .font(.subheadline)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(Color.invert.opacity(0.8))
                            .lineLimit(1)
                        
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Image(systemName: "person.2")
                                Text("\(group.memberCount) members")
                            }
                            
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                Text("4.9")
                            }
                        }
                        .font(.caption)
                        .foregroundColor(Color.invert.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Image(systemName: categoryIcon(for: group.category))
                        .font(.system(size: 44))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [colors.randomElement() ?? Color.red, .blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                .padding()
            
            
        }.overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.invert.opacity(0.20), lineWidth: 1)
        )
        .padding(.horizontal)
        
    }
    
    private func categoryIcon(for category: String) -> String {
        switch category {
        case "Sports": return "figure.run"
        case "Music": return "music.note"
        case "Art": return "paintbrush.fill"
        case "Technology": return "desktopcomputer"
        case "Food": return "fork.knife"
        case "Travel": return "airplane"
        case "Environmental": return "leaf.arrow.triangle.circlepath"
        case "Literature": return "book.fill"
        case "Corporate": return "building.2.fill"
        case "Health & Wellness": return "heart.fill"
        default: return "star.fill"
        }
    }
} 
