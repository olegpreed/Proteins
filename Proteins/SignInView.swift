//
//  SignInView.swift
//  Proteins
//
//  Created by Oleg on 8/15/25.
//

import SwiftUI

struct SignInView: View {
    @State private var loginWithFaceID = true
    @ObservedObject var signInModel = SignInModel()
    
    var body: some View {
        ZStack {
            CameraPreview()
                .blur(radius: 4)
                .ignoresSafeArea()
//            Image("face")
//                .resizable()
//                .aspectRatio(contentMode: .fill)
//                .ignoresSafeArea()
//                .blur(radius: 10)
            Color.green
                .blendMode(.darken)
                .ignoresSafeArea()
            VStack {
                if loginWithFaceID {SignInFormView(signInModel: signInModel)}
            }
            .padding()
            VStack() {
                Spacer()
                HStack(spacing: 20) {
                    Text("Log in with")
                        .font(.custom("IBMPlexMono-Regular", size: 17))
                        .foregroundStyle(.white)
                    Image(systemName:  loginWithFaceID ? "faceid" : "lock.fill")
                        .font(.system(size: 17))
                        .foregroundStyle(.white)
                        .transition(.scale)
                        .id(loginWithFaceID)
                }
            }
            .onTapGesture {
                withAnimation {
                    loginWithFaceID.toggle()
                }
            }
        }
        .ignoresSafeArea(.keyboard)
    }
}

#Preview {
    SignInView()
}
