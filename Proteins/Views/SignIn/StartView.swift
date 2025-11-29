//
//  StartView.swift
//  Proteins
//
//  Created by Oleg on 11/9/25.
//

import SwiftUI

struct StartView: View {
    @EnvironmentObject private var authState: AppleSignInService

        var body: some View {
            Group {
                switch authState.status {
                case .signedIn:
                    PinView()
                case .error(let message):
                    VStack(spacing: 12) {
                        Text("Something went wrong")
                            .font(.headline)
                        Text(message)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                        Button("Try again") {
                            authState.signOut()
                        }
                    }
                    .padding()
                default:
                    SignInView().environmentObject(authState)
                }
                
            }
//            SearchView()
        }
}
