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
    var body: some View {
       
         
            VStack {
                Spacer()
                ShimmerVar(text:"LinkedUp",animateForever: animateForever)
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
    var text = "Fumble"
    var font = "sanfrancisco"
    var size : UIFont.TextStyle = .title3
    @State var shimmerAppeared = false
    @State var shimmerOpacity = false
    @State var useCustomFont = false
    @State var ifNotCustomFont : Font = .subheadline
    var animateForever = false
    
    var body : some View {
        
        
        textview
        
        
    }
    
    var textview : some View {
        
        VStack {
            
            //This is the text we are displaying on the view
            Text(text)
            // .customfontFunc(customFont: font, style: size)
                .font(.custom("MrDafoe-Regular", size: 42))
                .foregroundColor(.clear)
            
            
            //We are simply scrolling the gradient from left to right for effect
                .background(
                    VStack {
                        ZStack {
                            LinearGradient(colors: [Color.green, .blue, .red], startPoint: .leading, endPoint: .trailing)
                            LinearGradient(gradient:
                                            Gradient(colors: [Color.clear, .invert.opacity(0.79), Color.clear]),
                                           startPoint: /*@START_MENU_TOKEN@*/.leading/*@END_MENU_TOKEN@*/, endPoint: /*@START_MENU_TOKEN@*/.trailing/*@END_MENU_TOKEN@*/)
                            
                            .opacity(shimmerAppeared ? 1 : 1)
                            //                            .animation(.easeIn(duration: 2.3), value: shimmerAppeared)
                            .animation(.linear(duration: 1.3).repeatForever(), value: shimmerAppeared)
                            .offset(x:shimmerAppeared ? 170 : -290)
                        }
                        
                        
                    }
                    
                    
                    //We mask the gradient with the same text on the view
                        .mask(
                            Text(text)
                                .font(.custom("MrDafoe-Regular", size: 42))
                            //  .customfontFunc(customFont: font, style: size)
                        )
                    
                )
            
            //below which is black
                .background(
                    VStack {
                        LinearGradient(gradient:
                                        Gradient(colors: [Color("black").opacity(shimmerOpacity ? 1 : 0)]),
                                       startPoint: /*@START_MENU_TOKEN@*/.leading/*@END_MENU_TOKEN@*/, endPoint: /*@START_MENU_TOKEN@*/.trailing/*@END_MENU_TOKEN@*/)
                        
                    }.mask(
                        Text(text)
                            .font(.custom("MrDafoe-Regular", size: 42))
                        //  .customfontFunc(customFont: font, style: size)
                    )
                    
                )
            
        }
        .font(!useCustomFont ? ifNotCustomFont : .custom(font, size: UIFont.preferredFont(forTextStyle: size).pointSize))
        
        .onAppear {
            shimmerAppearFunc()
        }
        .onDisappear {
            shimmerDisappearFunc()
        }
    }
    
    
    
    func typeWriter() {
        shimmerAppeared.toggle()
        
    }
    
    func shimmerAppearFunc(){
        withAnimation(.easeIn(duration: 4)) {
            
            shimmerOpacity  = true
            
        }
        withAnimation(.linear(duration: 4)) {
            shimmerAppeared = true
            
        }
        
        
    }
    func shimmerDisappearFunc(){
        withAnimation(.linear) {
            shimmerAppeared = false
        }
        withAnimation(.linear) {
            shimmerOpacity = false
        }
    }
    
}

