//
//  SettingsView.swift
//  Proteins
//
//  Created by Oleg on 11/10/25.
//

import SwiftUI
struct SettingsView: View {
    @EnvironmentObject var authManager: PinFaceIdService
    @EnvironmentObject var authState: AppleSignInService
    @Environment(\.dismiss) var dismiss
    @State private var showSignOutConfirmation: Bool = false
    
    var body: some View {
            List {
                if case let .signedIn(user) = authState.status {
                    Section("Account") {
                        HStack {
                            Text("Name")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(user.fullName ?? "")
                        }
                        HStack {
                            Text("Email")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(user.email ?? "")
                        }
                    }
                }
                Section("Security") {
                    Button(action: {
                        authManager.deletePIN()
                        dismiss()
                    }) {
                        HStack{
                            Text("Change Passcode")
                        }
                    }
                }
                Button(role: .destructive,
                       action: {
                    showSignOutConfirmation = true
                }) {
                    HStack {
                        Spacer()
                        Text("Sign out")
                        Spacer()
                    }
                }
                .alert("", isPresented: $showSignOutConfirmation) {
                    Button("Cancel", role: .cancel) { }
                    Button("Sign out", role: .destructive) {
                        authState.signOut()
                        authManager.reset()
                    }
                } message: {
                    Text("Are you sure you want to sign out?")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
        .environmentObject(PinFaceIdService())
        .environmentObject(AppleSignInService())
}
