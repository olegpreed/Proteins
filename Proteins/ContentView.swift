//
//  ContentView.swift
//  Proteins
//
//  Created by Oleg on 8/4/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var signInModel = SignInModel()
    
    var body: some View {
        ZStack{
            if signInModel.user != nil
            {
                SearchView(signInModel: signInModel)
                    .transition(.move(edge: .trailing))
            }
            else
            {
                SignInView(signInModel: signInModel)
//                    .transition(.move(edge: .leading))
            }
        }
        .animation(.easeInOut, value: signInModel.user)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .inactive || newPhase == .background {
                signInModel.signOut()
            }
        }
                
    }
}

#Preview {
    ContentView()
}
