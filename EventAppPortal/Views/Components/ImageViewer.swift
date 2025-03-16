import SwiftUI
import Kingfisher

struct ImageViewer: View {
    let imageUrls: [String]
    @State private var currentIndex = 0
    @State private var isZoomed = false
    @State private var dragOffset = CGSize.zero
    @State private var showFullScreen = false
    
    var body: some View {
        ZStack {
            if !showFullScreen {
                // Regular view
                TabView(selection: $currentIndex) {
                    ForEach(Array(imageUrls.enumerated()), id: \.offset) { index, url in
                        KFImage(URL(string: url))
                            .placeholder {
                                ProgressView()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(Color.gray.opacity(0.1))
                            }
                            .onFailure { error in
                                // Show a default image or error state
                                Image(systemName: "photo.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                            }
                            .resizable()
                            .scaledToFill()
                            .tag(index)
                            .onTapGesture {
                                withAnimation {
                                    showFullScreen = true
                                }
                            }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .overlay(
                    // Image counter overlay
                    Text("\(currentIndex + 1)/\(imageUrls.count)")
                        .font(.caption)
                        .padding(8)
                        .background(Color.black.opacity(0.6))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .padding(8),
                    alignment: .bottomTrailing
                )
            } else {
                // Full screen view
                ZStack {
                    Color.black.edgesIgnoringSafeArea(.all)
                    
                    TabView(selection: $currentIndex) {
                        ForEach(Array(imageUrls.enumerated()), id: \.offset) { index, url in
                            KFImage(URL(string: url))
                                .placeholder {
                                    ProgressView()
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                }
                                .resizable()
                                .scaledToFit()
                                .tag(index)
                                .scaleEffect(isZoomed ? 2 : 1)
                                .offset(dragOffset)
                                .gesture(
                                    MagnificationGesture()
                                        .onChanged { scale in
                                            withAnimation {
                                                isZoomed = scale > 1
                                            }
                                        }
                                        .simultaneously(with: DragGesture()
                                            .onChanged { gesture in
                                                if isZoomed {
                                                    dragOffset = gesture.translation
                                                }
                                            }
                                            .onEnded { _ in
                                                withAnimation {
                                                    dragOffset = .zero
                                                }
                                            }
                                        )
                                )
                                .onTapGesture(count: 2) {
                                    withAnimation {
                                        isZoomed.toggle()
                                        if !isZoomed {
                                            dragOffset = .zero
                                        }
                                    }
                                }
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                    
                    // Close button
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                withAnimation {
                                    showFullScreen = false
                                    isZoomed = false
                                    dragOffset = .zero
                                }
                            }) {
                                Image(systemName: "xmark")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            .padding()
                        }
                        Spacer()
                    }
                }
                .statusBar(hidden: true)
            }
        }
    }
}

// Preview provider
struct ImageViewer_Previews: PreviewProvider {
    static var previews: some View {
        ImageViewer(imageUrls: [
            "https://example.com/image1.jpg",
            "https://example.com/image2.jpg"
        ])
        .frame(height: 300)
    }
} 