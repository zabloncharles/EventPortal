import SwiftUI
import Kingfisher

struct CompactImageViewer: View {
    let imageUrls: [String]
    let height: CGFloat
    @State private var currentIndex = 0
    
    var body: some View {
        ZStack {
            TabView(selection: $currentIndex) {
                ForEach(Array(imageUrls.enumerated()), id: \.offset) { index, url in
                    KFImage(URL(string: url))
                        .placeholder {
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.gray.opacity(0.1))
                        }
                        .onFailure { error in
                            Image(systemName: "photo.fill")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        }
                        .resizable()
                        .scaledToFill()
                        .frame(height: height)
                        .clipped()
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            
            // Image counter overlay
//            if imageUrls.count > 1 {
//                VStack {
//                    Spacer()
//                    HStack {
//                        Spacer()
//                        Text("\(currentIndex + 1)/\(imageUrls.count)")
//                            .font(.caption)
//                            .padding(6)
//                            .background(Color.black.opacity(0.6))
//                            .foregroundColor(.white)
//                            .clipShape(Capsule())
//                            .padding(8)
//                    }
//                }
//            }
        }
        .frame(height: height)
    }
}

// Preview provider
struct CompactImageViewer_Previews: PreviewProvider {
    static var previews: some View {
        CompactImageViewer(
            imageUrls: [
                "https://example.com/image1.jpg",
                "https://example.com/image2.jpg"
            ],
            height: 200
        )
    }
} 
