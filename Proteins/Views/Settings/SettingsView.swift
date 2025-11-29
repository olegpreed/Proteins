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
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Security") {
                    HStack {
                        Text("Biometric Type")
                        Spacer()
                        Text(authManager.biometricType())
                            .foregroundColor(.secondary)
                    }
                    
                    Button(role: .destructive, action: {
                        showDeleteConfirmation = true
                    }) {
                        Label("Reset PIN", systemImage: "trash")
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
                Button(action: {
                    authState.signOut()
                    authManager.reset()
                }) {
                    HStack {
                        Image(systemName: "arrow.right.square")
                        Text("Logout")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Reset PIN?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    authManager.deletePIN()
                    dismiss()
                }
            } message: {
                Text("This will delete your current PIN and log you out. You'll need to set up a new PIN.")
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(PinFaceIdService())
}
