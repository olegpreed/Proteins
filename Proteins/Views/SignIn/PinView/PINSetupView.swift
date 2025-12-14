import SwiftUI

struct PINSetupView: View {
    @EnvironmentObject var authManager: PinFaceIdService
    @State private var currentStep: SetupStep = .create
    @State private var firstPIN: String = ""
    @State private var showError = false
    @State private var errorMessage = ""

    enum SetupStep {
        case create
        case confirm
    }

    var body: some View {
        ZStack {
            if currentStep == .create {
                PINEntryView(
                    title: "Create PIN",
                    subtitle: "Create a 4-digit PIN to secure your app",
                    showBiometric: false,
                    onComplete: { pin in
                        firstPIN = pin
                        withAnimation {
                            currentStep = .confirm
                        }
                        return true
                    }
                )
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            } else {
                PINEntryView(
                    title: "Confirm PIN",
                    subtitle: "Enter your PIN again to confirm",
                    showBiometric: false,
                    onComplete: { pin in
                        confirmPIN(pin)
                    }
                )
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("Try Again", role: .cancel) {
                withAnimation {
                    currentStep = .create
                }
                firstPIN = ""
            }
        } message: {
            Text(errorMessage)
        }
    }

    private func confirmPIN(_ pin: String) -> Bool {
        if pin == firstPIN {
            // PINs match, save it
            if authManager.setupPIN(pin) {
                // Successfully saved
            } else {
                errorMessage = "Failed to save PIN. Please try again."
                showError = true
            }
            return true

        } else {
            // PINs don't match
            errorMessage = "PINs don't match. Please try again."
            showError = true
            return false
        }
    }
}

#Preview {
    PINSetupView()
        .environmentObject(PinFaceIdService())
}
