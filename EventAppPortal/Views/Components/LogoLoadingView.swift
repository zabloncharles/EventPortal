//
//  LogoLoadingView.swift
//  Soul25
//
//  Created by Zablon Charles on 4/22/24.
//

import SwiftUI

struct LogoLoadingView: View {
    var animateForever = false
    var background = true
    @State var isAnimating = false
    
    var body: some View {
       
         
            VStack {
                Spacer()
                Image("transparent-icon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height:150)
                    .offset(y: isAnimating ? -10 : 10)
                    .animation(
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                    .onAppear {
                        isAnimating = true
                    }
                    
                ShimmerVar("LinkedUp",  font: .system(size: 25, weight: .bold), gradientColors: [.purple, .blue])
                    .scaleEffect(1.0)
                Spacer()
            }.background(Color.dynamic.edgesIgnoringSafeArea(.all))
        
    }
}

struct LogoLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LogoLoadingView()
    }
}

struct ShimmerVar: View {
    let text: String
    let font: Font
    let gradientColors: [Color]
    @State private var isAnimating = false
    
    init(
        _ text: String,
        font: Font = .system(size: 24, weight: .bold),
        gradientColors: [Color] = [.gray.opacity(0.3), .gray.opacity(0.5), .gray.opacity(0.3)]
    ) {
        self.text = text
        self.font = font
        self.gradientColors = gradientColors
    }
    
    var body: some View {
        Text(text)
            .font(font)
            .foregroundColor(.clear)
            .background(
                ZStack {
                    Color.invert
                    LinearGradient(
                        gradient: Gradient(colors: [Color.invert,gradientColors[0],gradientColors[1] ?? Color.gray,Color.invert]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .offset(x: isAnimating ? 400 : -400)
                }
            )
            .mask(
                Text(text)
                    .font(font)
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 2).speed(0.5)
                    .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}
                           // Using system font
                         //  ShimmerVar("Hello World", font: .system(size: 24, weight: .bold))
                           
                           // Using custom font
                         //  ShimmerVar("Hello World", font: .custom("YourCustomFont", size: 24))
                           
                           // Using default font (system bold 24)
                         //  ShimmerVar("Hello World")
