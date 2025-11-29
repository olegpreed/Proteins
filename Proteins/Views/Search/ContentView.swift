//
//  ContentView.swift
//  Proteins
//
//  Created by Oleg on 11/13/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: PinFaceIdService
    @EnvironmentObject var authState: AppleSignInService
    @State private var showSettings = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                Text("Welcome!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("You're successfully authenticated")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                VStack(spacing: 15) {
                    Button(action: {
                        showSettings = true
                    }) {
                        HStack {
                            Image(systemName: "gear")
                            Text("Settings")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
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
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .navigationTitle("Home")
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(authManager)
            }
        }
    }
}
