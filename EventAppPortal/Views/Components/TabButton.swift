import SwiftUI

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(isSelected ? .white : .gray)
                .padding(.vertical, 8)
                .padding(.horizontal, 20)
                .background(
                    isSelected ?
                    LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]),
                                 startPoint: .leading,
                                 endPoint: .trailing)
                    .cornerRadius(12) :
                        Color.clear
                )
        }
    }
}

struct TabButton_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            TabButton(title: "Tab 1", isSelected: true) {}
            TabButton(title: "Tab 2", isSelected: false) {}
        }
        .padding()
        .background(Color(.systemBackground))
    }
} 