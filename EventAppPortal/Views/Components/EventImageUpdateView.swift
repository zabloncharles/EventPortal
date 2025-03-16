import SwiftUI
import FirebaseFirestore
import FirebaseStorage

struct EventImageUpdateView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isUpdating = false
    @State private var progress = 0.0
    @State private var totalEvents = 0
    @State private var updatedEvents = 0
    @State private var errorMessage: String?
    
    // Map event types to their corresponding image filenames
    private let eventTypeImages: [String: [String]] = [
        "Corporate": ["47BB1751-B001-4BB8-97F3-DD73FEA0A008.jpg", "596FE02B-B29A-4377-88BD-175A9678156D.jpg", "656B434B-AC45-416D-AC4C-301930FF6C4C.jpg"],
        "Concert": ["6417351D-3D27-451A-BF49-7DA6CA5AEE8A.jpg", "744C5A91-3DDC-4413-858E-52C9669F15A2.jpg", "7B822796-9A8B-495B-A9CA-40A4BB0F3F00.jpg"],
        "Marketing": ["47BB1751-B001-4BB8-97F3-DD73FEA0A008.jpg", "72D3E6FC-A588-4D97-B212-6B3124AD0E7A.jpg", "79E164C2-4F58-46AA-B950-662FAF3555A3.jpg"],
        "Health & Wellness": ["2F720906-BD3E-4863-9027-61CD0B972EBA.jpg", "402C3BB5-0DAB-4891-A9ED-D20E0B8003A2.jpg", "4F46F970-5D24-4C96-96BC-A02305ADC54C.jpg"],
        "Technology": ["6417351D-3D27-451A-BF49-7DA6CA5AEE8A.jpg", "72D3E6FC-A588-4D97-B212-6B3124AD0E7A.jpg", "8CF99259-8B17-4EA1-B4E4-DC695B46263F.jpg"],
        "Art & Culture": ["17D48597-59B3-44BA-BB7A-BFD8CB8470D0.jpg", "584E12C8-72C2-4803-87F8-534F57D07113.jpg", "5D77FCBD-AFCB-4ABE-A7D6-D8DB82543DBF.jpg"],
        "Charity": ["4F46F970-5D24-4C96-96BC-A02305ADC54C.jpg", "E9DDCA07-4D22-44AC-B09F-74E21B668B1F.jpg"],
        "Literature": ["708E9A54-5D27-4B5D-ABB0-CF80A73CF888.jpg", "ABED16FB-B847-4028-B65C-AD9B752CB9F8.jpg", "FBDEF039-6AE5-480A-BA21-6A614BE3162E.jpg"],
        "Lifestyle": ["17D48597-59B3-44BA-BB7A-BFD8CB8470D0.jpg", "422B072E-0B69-49FE-A8D7-5CA429CED980.jpg", "A7DD13B0-A303-482B-A538-4EB5E57567A3.jpg"],
        "Environmental": ["17D48597-59B3-44BA-BB7A-BFD8CB8470D0.jpg", "315D458E-CBEE-40BC-935E-8CABCA093EB4.jpg", "7BC972D4-8264-4C4E-B419-C072980D28B1.jpg"],
        "Entertainment": ["0C974F1D-B873-4F1E-9F87-9FC3DF679AF1.jpg", "422B072E-0B69-49FE-A8D7-5CA429CED980.jpg", "5D77FCBD-AFCB-4ABE-A7D6-D8DB82543DBF.jpg"]
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isUpdating {
                    ProgressView("Updating Events... \(updatedEvents)/\(totalEvents)")
                        .progressViewStyle(CircularProgressViewStyle())
                    
                    ProgressView(value: progress)
                        .padding(.horizontal)
                    
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                } else {
                    Text("Update Event Images")
                        .font(.title)
                        .padding()
                    
                    Text("This will update all event images based on their event type.")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                    }
                    
                    Button(action: updateEventImages) {
                        Text("Start Update")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .disabled(isUpdating)
                }
            }
            .padding()
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
    
    private func updateEventImages() {
        isUpdating = true
        progress = 0.0
        updatedEvents = 0
        errorMessage = nil
        
        let db = Firestore.firestore()
        
        // Get all events
        db.collection("events").getDocuments { snapshot, error in
            if let error = error {
                errorMessage = "Error fetching events: \(error.localizedDescription)"
                isUpdating = false
                return
            }
            
            guard let documents = snapshot?.documents else {
                errorMessage = "No events found"
                isUpdating = false
                return
            }
            
            totalEvents = documents.count
            
            // Process each event
            for (index, document) in documents.enumerated() {
                guard let eventType = document.data()["type"] as? String,
                      let imageNames = eventTypeImages[eventType] else {
                    continue
                }
                
                // Create array of image URLs for the event type
                let imageUrls = imageNames.map { imageName -> String in
                    // Use the correct URL format with the user_uploads folder
                    return "https://firebasestorage.googleapis.com/v0/b/eventportal-37f4b.firebasestorage.app/o/user_uploads%2F\(imageName)?alt=media"
                }
                
                // Update the event document with new image URLs
                db.collection("events").document(document.documentID).updateData([
                    "images": imageUrls
                ]) { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            errorMessage = "Error updating event: \(error.localizedDescription)"
                        }
                        
                        updatedEvents += 1
                        progress = Double(updatedEvents) / Double(totalEvents)
                        
                        // Check if all events are processed
                        if updatedEvents == totalEvents {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                isUpdating = false
                                dismiss()
                            }
                        }
                    }
                }
            }
        }
    }
}

struct Previews_EventImageUpdateView_Previews: PreviewProvider {
    static var previews: some View {
        EventImageUpdateView()
    }
}
