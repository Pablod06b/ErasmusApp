//
//  ContentView.swift
//  Erasmus_App
//
//  Created by Pablo Domínguez Barbero on 29/7/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = FirebaseAuthManager()
    @StateObject private var router = NavigationRouter.shared
    @StateObject private var network = NetworkMonitor.shared
    @State private var isActive = false

    var body: some View {
        ZStack {
            // Contenido principal
            mainContent
                .opacity(isActive ? 1 : 0)

            // Splash inicial
            if !isActive {
                SplashView()
                    .environmentObject(authManager)
                    .transition(.opacity)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                            withAnimation { isActive = true }
                        }
                    }
            }
        }
        .onAppear {
            network.start()
        }
        // Banner persistente offline encima de TODO
        .overlay(alignment: .top) {
            if isActive && !network.isConnected {
                OfflineBannerView()
                    .transition(.move(edge: .top))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: network.isConnected)
        .sheet(isPresented: Binding(
            get: { router.pendingTarget != nil },
            set: { if !$0 { router.pendingTarget = nil } }
        )) {
            NotificationsView()
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        if authManager.isAuthenticated {
            if authManager.currentUser?.onboardingCompleted == false {
                ModernOnboardingFlow(onFinish: {})
                    .environmentObject(authManager)
            } else {
                HomeView()
                    .environmentObject(authManager)
                    .environmentObject(router)
            }
        } else {
            ModernLoginView()
                .environmentObject(authManager)
        }
    }
}

#Preview {
    ContentView()
}
