import SwiftUI

struct AIOrb: View {
    @State private var rotationAngle: Double = 0
    @State private var glowIntensity: CGFloat = 0.5
    @State private var orbScale: CGFloat = 1.0
    @State private var ringRotation: Double = 0
    
    let timer = Timer.publish(every: 0.02, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                let size = min(geometry.size.width, geometry.size.height)
                ZStack {
                    // Container to prevent movement
                    Color.clear
                        .frame(width: size, height: size)
                    
                    // Main orb glow
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.5),
                                    Color.purple.opacity(0.3),
                                    Color.black.opacity(0)
                                ]),
                                center: .center,
                                startRadius: size * 0.25,
                                endRadius: size * 0.75
                            )
                        )
                        .blur(radius: size * 0.15)
                        .scaleEffect(glowIntensity)
                        .frame(width: size, height: size)
                    
                    // Core orb
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.8),
                                    Color.purple.opacity(0.6)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: size * 0.4, height: size * 0.4)
                        .blur(radius: size * 0.025)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.8),
                                            Color.blue.opacity(0.3)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .scaleEffect(orbScale)
                    
                    // Rotating ring
                    Circle()
                        .trim(from: 0.2, to: 0.8)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0),
                                    Color.blue,
                                    Color.purple,
                                    Color.blue.opacity(0)
                                ]),
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round)
                        )
                        .frame(width: size * 0.6, height: size * 0.6)
                        .rotationEffect(.degrees(ringRotation))
                        .blur(radius: 2)
                    
                    // Outer ring
                    Circle()
                        .trim(from: 0.45, to: 0.55)
                        .stroke(
                            Color.blue.opacity(0.5),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: size * 0.8, height: size * 0.8)
                        .rotationEffect(.degrees(rotationAngle))
                        .blur(radius: 2)
                }
                .frame(width: size, height: size)
                .position(x: geometry.size.width/2, y: geometry.size.height/2)
            }
            .onReceive(timer) { _ in
                withAnimation(.linear(duration: 0.02)) {
                    rotationAngle += 1
                    ringRotation -= 0.5
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    glowIntensity = 0.7
                    orbScale = 1.1
                }
        }
        }
    }
}



