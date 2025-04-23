import SwiftUI
import Kingfisher

struct CompactImageViewer: View {
    let imageUrls: [String]
    let height: CGFloat
    @State private var currentIndex = 0
    @State private var validImageUrls: [String] = []
    @State private var loadingStates: [String: Bool] = [:]
    var scroll: Bool = true
    
    var body: some View {
        ZStack {
            if validImageUrls.isEmpty {
                // Show placeholder when no valid images are available
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: height)
                    .overlay(
                        Image(systemName: "photo.fill")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    )
            } else {
                TabView(selection: $currentIndex) {
                    ForEach(Array(validImageUrls.enumerated()), id: \.offset) { index, url in
                        KFImage(URL(string: url))
                            .placeholder {
                                ProgressView()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(Color.gray.opacity(0.1))
                            }
                            .onSuccess { result in
                                print("Successfully loaded image at index \(index): \(url)")
                                loadingStates[url] = true
                            }
                            .onFailure { error in
                                print("Failed to load image at index \(index): \(url)")
                                print("Error: \(error)")
                                // Remove the failed image URL from the array
                                if let index = validImageUrls.firstIndex(of: url) {
                                    validImageUrls.remove(at: index)
                                    loadingStates[url] = false
                                }
                            }
                            .resizable()
                            .scaledToFill()
                            .frame(height: height)
                            .clipped()
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: validImageUrls.count > 1 && scroll ? .automatic : .never))
                .overlay {
                    scroll ? Color.clear :
                    Color.gray.opacity(0.02)
                }
            }
            
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
        .onAppear {
            print("CompactImageViewer appeared with \(imageUrls.count) URLs")
            // Filter out invalid URLs and initialize loading states
            validImageUrls = imageUrls.filter { urlString in
                if let _ = URL(string: urlString) {
                    print("Valid URL found: \(urlString)")
                    loadingStates[urlString] = false
                    return true
                } else {
                    print("Invalid URL found: \(urlString)")
                    return false
                }
            }
            print("Filtered to \(validImageUrls.count) valid URLs")
        }
    }
}

// Preview provider
struct CompactImageViewer_Previews: PreviewProvider {
    static var previews: some View {
        CompactImageViewer(
            imageUrls: [
                "https://firebasestorage.googleapis.com/v0/b/eventportal-37f4b.firebasestorage.app/o/user_uploads%2F0C974F1D-B873-4F1E-9F87-9FC3DF679AF1.jpg?alt=media"
            ],
            height: 200
        )
    }
} 
