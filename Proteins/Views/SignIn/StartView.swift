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
                default:
                    SignInView().environmentObject(authState)
                }
                
            }
//            SearchView()
        }
}
