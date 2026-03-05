//
//  ContentView.swift
//  Erasmus_App
//
//  Created by Pablo Domínguez Barbero on 29/7/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = FirebaseAuthManager()
    @State private var isActive = false
    
    var body: some View {
        ZStack {
            if isActive {
                if authManager.isAuthenticated {
                    HomeView()
                        .environmentObject(authManager)
                } else {
                    ModernLoginView()
                        .environmentObject(authManager)
                }
            } else {
                SplashView()
                    .environmentObject(authManager)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                            withAnimation { isActive = true }
                        }
                    }
            }
        }
    }
}

#Preview {
    ContentView()
}
