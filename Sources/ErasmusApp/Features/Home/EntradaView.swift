// Views/SplashView.swift
import SwiftUI

struct SplashView: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.5
    
    var body: some View {
        ZStack {
            Color.gray.opacity(0.05)
                .ignoresSafeArea()
            
            VStack {
                Image("app_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.5).repeatCount(1, autoreverses: true)) {
                            scale = 1.0
                            opacity = 1.0
                        }
                    }
            }
        }
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
}

