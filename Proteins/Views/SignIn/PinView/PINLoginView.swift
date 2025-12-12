import SwiftUI

struct PINLoginView: View {
    @EnvironmentObject var authManager: PinFaceIdService
    @EnvironmentObject var authState: AppleSignInService
    @State private var showError = false
    @State private var attempts = 0
    @State private var showLockoutAlert = false
    
    private let maxAttempts = 5
    
    var body: some View {
        VStack {
            PINEntryView(
                title: "Enter PIN",
                showBiometric: authManager.isBiometricsAvailable(),
                onComplete: { pin in
                    let success = verifyPIN(pin)
                    return success
                },
                onBiometric: {
                    authenticateWithBiometrics()
                }
            )
        }
        .alert("Too Many Attempts",
               isPresented: $showLockoutAlert) {
            Button("OK") {
                authManager.reset()
                authState.signOut()
            }
        } message: {
            Text("You exceeded your PIN attempts. You will be logged out now.")
        }
        .onAppear {
            if authManager.isBiometricsAvailable() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    authenticateWithBiometrics()
                }
            }
        }
    }
    
    private func verifyPIN(_ pin: String) -> Bool {
        if authManager.verifyPIN(pin) {
            attempts = 0
            showLockoutAlert = false
            return true
        } else {
            attempts += 1
            
            if attempts >= maxAttempts {
                showLockoutAlert = true
            }
            return false
        }
    }
    
    private func authenticateWithBiometrics() {
        authManager.authenticateWithBiometrics { success, error in
            if !success {
                if let error = error {
                    print("Biometric authentication failed: \(error.localizedDescription)")
                }
            }
        }
    }
}

#Preview {
    PINLoginView()
        .environmentObject(PinFaceIdService())
}
