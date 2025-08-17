//
//  LogInFormView.swift
//  Proteins
//
//  Created by Oleg on 8/12/25.
//

import SwiftUI

struct SignInFormView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @ObservedObject var signInModel: SignInModel
    
    var body: some View {
        HStack {
            VStack() {
                TextField("", text: $username, prompt: Text("Login").foregroundStyle(.white))
                    .font(.custom("IBMPlexMono-Regular", size: 17))
                    .foregroundStyle(.white)
                    .padding()
                SecureField("", text: $password, prompt: Text("Password").foregroundStyle(.white))
                    .font(.custom("IBMPlexMono-Regular", size: 17))
                    .padding()
            }
            Button(action: {
                signInModel.signIn(email: username, password: password)
            }
            ) {
                Image(systemName: "arrowshape.right.fill")
                    .font(.system(size: 17))
                    .padding()
                    .frame(maxHeight: .infinity)
                
            }
            .cornerRadius(0)
            .buttonStyle(.bordered)
            .buttonBorderShape(.roundedRectangle(radius: 6))
            .tint(.white)
        }
        .fixedSize(horizontal: false, vertical: true)
        .alert(item: $signInModel.alertItem) { alertItem in
            Alert(title: Text(alertItem.title), message: Text(alertItem.message), dismissButton: .default(Text("OK")))
        }
    }
}

#Preview {
    SignInFormView(
        signInModel: SignInModel()
    )
}
