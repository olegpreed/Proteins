//
//  AuthState.swift
//  Proteins
//
//  Created by Oleg on 11/5/25.
//

import AuthenticationServices
import Combine
import Foundation
import UIKit

@MainActor
final class AppleSignInService: NSObject, ObservableObject {
    @Published var status: Status = .signedOut

    enum Status {
        case signedOut
        case loading
        case signedIn(User)
        case error(String)
    }

    struct User {
        let id: String
        let email: String?
        let fullName: PersonNameComponents?
    }

    private var authorizationController: ASAuthorizationController?

    func signIn() {
        status = .loading

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [
            request
        ])
        controller.delegate = self
        controller.presentationContextProvider = self
        authorizationController = controller
        controller.performRequests()
    }

    func signOut() {
        UserDefaults.standard.removeObject(forKey: "appleUserId")
        status = .signedOut
    }

    func checkExistingSignIn() {
        guard let userId = UserDefaults.standard.string(forKey: "appleUserId")
        else {
            status = .signedOut
            return
        }

        let provider = ASAuthorizationAppleIDProvider()
        provider.getCredentialState(forUserID: userId) {
            [weak self] credentialState, _ in
            DispatchQueue.main.async {
                switch credentialState {
                case .authorized:
                    // Restore signed-in state
                    self?.status = .signedIn(
                        User(id: userId, email: nil, fullName: nil)
                    )
                default:
                    // If revoked or not found, sign out
                    self?.status = .signedOut
                }
            }
        }
    }
}

extension AppleSignInService: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        authorizationController = nil

        guard
            let credential = authorization.credential
                as? ASAuthorizationAppleIDCredential
        else {
            status = .error("Unsupported credential type.")
            return
        }

        let user = User(
            id: credential.user,
            email: credential.email,
            fullName: credential.fullName
        )

        UserDefaults.standard.set(user.id, forKey: "appleUserId")

        status = .signedIn(user)
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        authorizationController = nil

        status = .error(error.localizedDescription)
    }
}

extension AppleSignInService:
    ASAuthorizationControllerPresentationContextProviding
{
    func presentationAnchor(for controller: ASAuthorizationController)
        -> ASPresentationAnchor
    {
        guard
            let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
            let window = windowScene.windows.first(where: { $0.isKeyWindow })
        else {
            fatalError("No active window scene found")
        }
        return window
    }
}
