//
//  SignInView.swift
//  Proteins
//
//  Created by Oleg on 8/15/25.
//

import SwiftUI
import LocalAuthentication

struct SignInView: View {
    @ObservedObject var signInModel = SignInModel()
    @State private var username: String = ""
    @State private var password: String = ""
    
    var body: some View {
        VStack() {
            Text("PROTEINS")
                .font(.custom("IBMPlexMono-SemiBold", size: 100))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color("Pink"), Color("Blue")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .lineLimit(1)             // keep it in one line
                .minimumScaleFactor(0.1)  // allow shrinking down to 10%
                .frame(maxWidth: .infinity) // take full width
                .multilineTextAlignment(.center)
            
            Spacer()
            VStack(spacing: 20) {
                VStack(spacing: 20) {
                    TextField("", text: $username, prompt: Text("Email"))
                        .font(.custom("IBMPlexMono-Regular", size: 17))
                    SecureField("", text: $password, prompt: Text("Password"))
                        .font(.custom("IBMPlexMono-Regular", size: 17))
                }
                VStack(spacing: 12) {
                    Button( action: {
                        signInModel.signIn(email: username, password: password)
                    }) {
                        HStack {
                            Text("Log in with")
                                .bold()
                            Image(systemName: "lock.fill")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .controlSize(.large)
                    .buttonStyle(.borderedProminent)
                    .alert(item: $signInModel.alertItem) { alertItem in
                        Alert(title: Text(alertItem.title), message: Text(alertItem.message), dismissButton: .default(Text("OK")))
                    }
                    Button(action: {
                        authenticateWithFaceID()
                    }) {
                        HStack {
                            Text("Log in with")
                                .bold()
                            Image(systemName: "faceid")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .controlSize(.large)
                    .buttonStyle(.bordered)
                    .tint(.accent)
                    .frame(maxWidth: .infinity)
                }
            }
            
        }
        .padding(.horizontal)
    }
    
    private func authenticateWithFaceID() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Log in with Face ID"
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        // ✅ Load credentials from Keychain and sign in
                        if let creds = CredentialsStore.shared.loadCredentials() {
                            signInModel.signIn(email: creds.email, password: creds.password)
                        }
                    } else {
                        // ❌ Show error
                        signInModel.alertItem = AlertItem(
                            title: "Authentication Failed",
                            message: authenticationError?.localizedDescription ?? "Face ID failed"
                        )
                    }
                }
            }
        } else {
            // ❌ Device doesn’t support Face ID
            signInModel.alertItem = AlertItem(
                title: "Unavailable",
                message: "Your device does not support Face ID"
            )
        }
    }
}

#Preview {
    SignInView()
}
