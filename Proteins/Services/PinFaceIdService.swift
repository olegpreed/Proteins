//
//  AuthenticationManager.swift
//  Proteins
//
//  Created by Oleg on 11/10/25.
//

import Combine
import Foundation
import LocalAuthentication
import SwiftUI

class PinFaceIdService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var needsPINSetup = false
    
    init() {
        checkAuthenticationStatus()
    }
    
    func checkAuthenticationStatus() {
        needsPINSetup = !KeychainHelper.shared.hasPIN()
        isAuthenticated = false
    }
    
    // Setup new PIN
    func setupPIN(_ pin: String) -> Bool {
        let success = KeychainHelper.shared.savePIN(pin)
        if success {
            needsPINSetup = false
            isAuthenticated = true
        }
        return success
    }
    
    // Verify PIN
    func verifyPIN(_ pin: String) -> Bool {
        guard let storedPIN = KeychainHelper.shared.getPIN() else {
            return false
        }
        
        let isValid = pin == storedPIN
        if isValid {
            isAuthenticated = true
        }
        return isValid
    }
    
    // Authenticate with biometrics (Face ID / Touch ID)
    func authenticateWithBiometrics(completion: @escaping (Bool, Error?) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        // Check if biometric authentication is available
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            completion(false, error)
            return
        }
        
        let reason = "Authenticate to access the app"
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.isAuthenticated = true
                }
                completion(success, error)
            }
        }
    }
    
    // Check if biometrics is available
    func isBiometricsAvailable() -> Bool {
        let context = LAContext()
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }
    
    // Get biometric type
    func biometricType() -> String {
        let context = LAContext()
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else {
            return "None"
        }
        
        switch context.biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        case .none:
            return "None"
        @unknown default:
            return "Unknown"
        }
    }
    
    // Logout
    func logout() {
        isAuthenticated = false
    }
    
    // Delete PIN (for settings/reset)
    func deletePIN() {
        KeychainHelper.shared.deletePIN()
        needsPINSetup = true
        isAuthenticated = false
    }
    
    func reset() {
        // Clear everything so app returns to full sign-in state
        isAuthenticated = false
        needsPINSetup = true
        KeychainHelper.shared.deletePIN()
    }

}
