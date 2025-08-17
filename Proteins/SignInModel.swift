//
//  SignInModel.swift
//  Proteins
//
//  Created by Oleg on 8/13/25.
//

import FirebaseAuth

class SignInModel: ObservableObject {
    @Published var user: User?
    @Published var alertItem: AlertItem?
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            user = nil
        } catch {
            alertItem = AlertItem(title: "Sign Out Error",
                                  message: error.localizedDescription)
        }
    }
    
    func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error as NSError? {
                if error.code == AuthErrorCode.userNotFound.rawValue {
                    Auth.auth().createUser(withEmail: email, password: password) { result, createError in
                        if let createError = createError {
                            self.alertItem = AlertItem(title: "Sign Up Error",
                                                            message: createError.localizedDescription)
                            return
                        }
                        self.user = result?.user
                    }
                } else {
                    self.alertItem = AlertItem(title: "Sign In Error",
                                                            message: error.localizedDescription)
                }
                return
            }
            
            // Signed in successfully
            self.user = result?.user
        }
    }
}


