import SwiftUI
import PhotosUI
import FirebaseStorage

struct PhotoUploadView: View {
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var uploadProgress: Double = 0
    @State private var isUploading = false
    @State private var uploadedUrls: [String] = []
    @Environment(\.dismiss) private var dismiss
    let onComplete: ([String]) -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                if !selectedImages.isEmpty {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 10) {
                            ForEach(0..<selectedImages.count, id: \.self) { index in
                                Image(uiImage: selectedImages[index])
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 120)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        Button(action: {
                                            selectedImages.remove(at: index)
                                            selectedItems.remove(at: index)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.white)
                                                .background(Circle().fill(Color.black.opacity(0.5)))
                                        }
                                        .padding(8),
                                        alignment: .topTrailing
                                    )
                            }
                        }
                        .padding()
                    }
                }
                
                if isUploading {
                    ProgressView("Uploading... \(Int(uploadProgress * 100))%")
                        .progressViewStyle(LinearProgressViewStyle())
                        .padding()
                }
                
                PhotosPicker(selection: $selectedItems,
                           maxSelectionCount: 10,
                           matching: .images) {
                    Label("Select Photos", systemImage: "photo.on.rectangle.angled")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding()
                
                if !selectedImages.isEmpty {
                    Button(action: uploadPhotos) {
                        Text("Upload \(selectedImages.count) Photos")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                    .disabled(isUploading)
                }
            }
            .navigationTitle("Upload Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: selectedItems) { newItems in
            Task {
                selectedImages = []
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImages.append(image)
                    }
                }
            }
        }
    }
    
    private func uploadPhotos() {
        guard !selectedImages.isEmpty else { return }
        
        isUploading = true
        uploadProgress = 0
        uploadedUrls = []
        
        let storage = Storage.storage()
        let storageRef = storage.reference(forURL: "gs://eventportal-37f4b.firebasestorage.app")
        
        let totalImages = Double(selectedImages.count)
        var uploadedCount = 0
        
        for (index, image) in selectedImages.enumerated() {
            let imageRef = storageRef.child("user_uploads/\(UUID().uuidString).jpg")
            
            guard let imageData = image.jpegData(compressionQuality: 0.7) else {
                continue
            }
            
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            let uploadTask = imageRef.putData(imageData, metadata: metadata) { metadata, error in
                if error == nil && metadata != nil {
                    imageRef.downloadURL { url, error in
                        if let downloadURL = url?.absoluteString {
                            uploadedUrls.append(downloadURL)
                            uploadedCount += 1
                            
                            if uploadedCount == selectedImages.count {
                                DispatchQueue.main.async {
                                    isUploading = false
                                    onComplete(uploadedUrls)
                                    dismiss()
                                }
                            }
                        }
                    }
                }
            }
            
            uploadTask.observe(.progress) { snapshot in
                let percentComplete = Double(snapshot.progress?.completedUnitCount ?? 0) / Double(snapshot.progress?.totalUnitCount ?? 1)
                let overallProgress = (Double(index) + percentComplete) / totalImages
                DispatchQueue.main.async {
                    uploadProgress = overallProgress
                }
            }
        }
    }
} 