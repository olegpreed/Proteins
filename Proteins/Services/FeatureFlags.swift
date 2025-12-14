//
//  FeatureFlags.swift
//  Proteins
//
//  Created on 12/4/25.
//

import Foundation

/// Feature flags for testing and development purposes
enum FeatureFlags {
    /// When enabled, bypasses actual Sign in with Apple and uses mock authentication.
    /// Useful for testing without Apple ID or on simulator.
    static let bypassAppleSignIn: Bool = {
        #if DEBUG
            return UserDefaults.standard.bool(forKey: "FeatureFlags.bypassAppleSignIn")
        #else
            return false
        #endif
    }()

    /// Mock user data used when bypassAppleSignIn is enabled
    enum MockUser {
        static let id = "mock-user-id-12345"
        static let email = "test@example.com"
        static let fullName = "Test User"
    }
}
