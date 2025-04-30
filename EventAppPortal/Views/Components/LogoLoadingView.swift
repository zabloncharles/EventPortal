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
       
         
        ZStack {
            
            VStack {
                    Spacer()
                
                ZStack {
                    
                    Image("transparent-icon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            
                            .frame(height:150)
                            .scaleEffect( isAnimating ? 1 : 0.90)
                            .animation(
                                Animation.easeInOut(duration: 1.8)
                                    .repeatForever(autoreverses: true),
                                value: isAnimating
                            )
                            .onAppear {
                              isAnimating = true
                        }
                }
                        
                    HStack {
                        Spacer()
                        ShimmerVar("LinkedUp",  font: .title3, gradientColors: [.dynamic, .orange])
                            .fontWeight(.bold)
                        Spacer()
                    }
                Text("Make a connection.")
                    Spacer()
            }
        }
        
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
