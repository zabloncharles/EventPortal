import SwiftUI
import Kingfisher

struct CompactImageViewer: View {
    let imageUrls: [String]
    @State private var currentIndex = 0
    var scroll: Bool = true

    private var sources: [String] {
        imageUrls.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }

    private static func isRemoteURL(_ string: String) -> Bool {
        let lower = string.lowercased()
        return lower.hasPrefix("http://") || lower.hasPrefix("https://")
    }

    var body: some View {
        ZStack {
            if sources.isEmpty {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        Image(systemName: "photo.fill")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    )
            } else {
                TabView(selection: $currentIndex) {
                    ForEach(Array(sources.enumerated()), id: \.offset) { index, item in
                        Group {
                            if Self.isRemoteURL(item) {
                                KFImage(URL(string: item))
                                    .placeholder {
                                        ProgressView()
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                            .background(Color.gray.opacity(0.1))
                                    }
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Image(item)
                                    .resizable()
                                    .scaledToFill()
                            }
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: sources.count > 1 && scroll ? .automatic : .never))
                .overlay {
                    scroll ? Color.clear : Color.gray.opacity(0.02)
                }
            }
        }
    }
}

struct CompactImageViewer_Previews: PreviewProvider {
    static var previews: some View {
        CompactImageViewer(
            imageUrls: [
                "https://firebasestorage.googleapis.com/v0/b/eventportal-37f4b.firebasestorage.app/o/user_uploads%2F0C974F1D-B873-4F1E-9F87-9FC3DF679AF1.jpg?alt=media"
            ]
        )
    }
}
