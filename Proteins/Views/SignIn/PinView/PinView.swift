//
//  PinView.swift
//  Proteins
//
//  Created by Oleg on 11/13/25.
//

import SwiftUI

struct PinView: View {
    @EnvironmentObject private var authManager: PinFaceIdService
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
            ZStack {
                if authManager.isAuthenticated {
                    // User is authenticated - show main content
                    SearchView()
                        .environmentObject(authManager)
                } else if authManager.needsPINSetup {
                    // First time user - needs to setup PIN
                    PINSetupView()
                        .environmentObject(authManager)
                } else {
                    // User has PIN but needs to authenticate
                    PINLoginView()
                        .environmentObject(authManager)
                }
            }
            .animation(.easeInOut, value: authManager.isAuthenticated)
            .animation(.easeInOut, value: authManager.needsPINSetup)
            .onChange(of: scenePhase, { oldValue, newValue in
                if newValue == .background {
                    authManager.isAuthenticated = false
                }
            })
        }
}
