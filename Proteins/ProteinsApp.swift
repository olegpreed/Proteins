//
//  ProteinsApp.swift
//  Proteins
//
//  Created by Oleg on 8/4/25.
//

import SwiftUI

@main
struct ProteinsApp: App {
    @StateObject private var authState = AppleSignInService()
    @StateObject private var authManager = PinFaceIdService()
    
    var body: some Scene {
            WindowGroup {
                StartView()
                    .environmentObject(authState)
                    .environmentObject(authManager)
                    .onAppear {
                        authState.checkExistingSignIn()
                    }
            }
        }
}
