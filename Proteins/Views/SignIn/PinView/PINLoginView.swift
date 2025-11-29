import SwiftUI

struct PINLoginView: View {
    @EnvironmentObject var authManager: PinFaceIdService
    @State private var showError = false
    @State private var pinEntryKey = UUID() // For resetting the view
    @State private var attempts = 0
    @State private var isLocked = false
    @State private var lockoutEndTime: Date?
    
    private let maxAttempts = 5
    private let lockoutDuration: TimeInterval = 60 // 60 seconds
    
    var body: some View {
        VStack {
            if isLocked {
                lockedView
            } else {
                PINEntryView(
                    title: "Enter PIN",
                    subtitle: attempts > 0 ? "Incorrect PIN. Try again." : "Enter your PIN to continue",
                    showBiometric: authManager.isBiometricsAvailable(),
                    onComplete: { pin in
                        verifyPIN(pin)
                    },
                    onBiometric: {
                        authenticateWithBiometrics()
                    }
                )
                .id(pinEntryKey) // Force view refresh when key changes
            }
        }
        .onAppear {
            // Auto-trigger biometrics on appear if available
            if authManager.isBiometricsAvailable() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    authenticateWithBiometrics()
                }
            }
        }
    }
    
    private var lockedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Too Many Attempts")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Please wait before trying again.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let endTime = lockoutEndTime {
                Text(timeRemaining(until: endTime))
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
            }
        }
        .padding()
    }
    
    private func verifyPIN(_ pin: String) {
        if authManager.verifyPIN(pin) {
            // Success - authentication handled by manager
            attempts = 0
            isLocked = false
        } else {
            // Failed attempt
            attempts += 1
            
            if attempts >= maxAttempts {
                // Lock the user out
                isLocked = true
                lockoutEndTime = Date().addingTimeInterval(lockoutDuration)
                
                // Reset after lockout period
                DispatchQueue.main.asyncAfter(deadline: .now() + lockoutDuration) {
                    isLocked = false
                    attempts = 0
                    lockoutEndTime = nil
                    pinEntryKey = UUID()
                }
            } else {
                // Just reset the entry
                pinEntryKey = UUID()
            }
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
    
    private func timeRemaining(until endTime: Date) -> String {
        let remaining = Int(endTime.timeIntervalSinceNow)
        if remaining <= 0 {
            return "Unlocking..."
        }
        let minutes = remaining / 60
        let seconds = remaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    PINLoginView()
        .environmentObject(PinFaceIdService())
}
