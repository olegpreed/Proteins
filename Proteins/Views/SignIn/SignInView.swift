//
//  SignInView.swift
//  Proteins
//
//  Created by Oleg on 8/15/25.
//

import SwiftUI
import LocalAuthentication

struct SignInView: View {
    @EnvironmentObject private var authState: AppleSignInService
    @Environment(\.colorScheme) var colorScheme
    
    @State private var username: String = ""
    @State private var password: String = ""
    
    var body: some View {
        ZStack() {
            MoleculeView()
                .ignoresSafeArea()
            VStack(){
                Spacer()
                VStack() {
                    Text("Swifty-\nProteins")
                        .font(.custom("IBMPlexMono-Medium", size: 60))
                        .lineHeight(.tight)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                    Spacer().frame(height: 20)
                    Text("Explore proteins structures with ease")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                        .padding(.bottom, 15)
                        .foregroundStyle(
                            .gray
                                               )
                    SignInWithAppleButtonView().environmentObject(authState)
                    Spacer().frame(height: 20)
                }
                .safeAreaPadding()
                .background {
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 20))
            }
            .ignoresSafeArea()
        }
    }
    
       private var gradientColors: [Color] {
           if colorScheme == .dark {
               return [
                   Color.black.opacity(0.0),
                   Color.black.opacity(0.9),
                   Color.black.opacity(1.0)
               ]
           } else {
               return [
                   Color.white.opacity(0.0),
                   Color.white.opacity(0.9),
                   Color.white.opacity(1.0)
               ]
           }
       }
}

#Preview {
    SignInView().environmentObject(AppleSignInService())
}
