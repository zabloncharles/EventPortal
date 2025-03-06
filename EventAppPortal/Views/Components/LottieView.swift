import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    var filename: String
    var loop: Bool = true
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let animationView = AnimationView()
        
        // Debug: Print the file path
        if let bundlePath = Bundle.main.path(forResource: filename, ofType: "json") {
            print("Found Lottie file at: \(bundlePath)")
        } else {
            print("⚠️ Could not find Lottie file: \(filename).json")
        }
        
        if let animation = Animation.named(filename) {
            animationView.animation = animation
            print("✅ Successfully loaded animation: \(filename)")
        } else {
            print("❌ Failed to load animation: \(filename)")
        }
        
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = loop ? .loop : .playOnce
        animationView.play()
        
        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animationView)
        
        NSLayoutConstraint.activate([
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor),
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
} 