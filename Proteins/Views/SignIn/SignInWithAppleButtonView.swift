//
//  SignInWithAppleButtonView.swift
//  Proteins
//
//  Created by Oleg on 11/9/25.
//

import AuthenticationServices
import SwiftUI

struct SignInWithAppleButtonView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var authState: AppleSignInService

    var body: some View {
        SignInButtonRepresentable(action: authState.signIn, style: colorScheme == .dark ? .white : .black)
            .clipShape(RoundedRectangle(cornerRadius: 200))
            .frame(height: 45)
            .id(colorScheme)
    }
}

private struct SignInButtonRepresentable: UIViewRepresentable {
    let action: () -> Void
    let style: ASAuthorizationAppleIDButton.Style

    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: style)
        button.addTarget(context.coordinator,
                         action: #selector(Coordinator.handleTap),
                         for: .touchUpInside)
        return button
    }

    func updateUIView(_: ASAuthorizationAppleIDButton, context _: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    final class Coordinator: NSObject {
        let action: () -> Void

        init(action: @escaping () -> Void) {
            self.action = action
        }

        @objc func handleTap() {
            action()
        }
    }
}

#Preview {
    SignInWithAppleButtonView()
        .environmentObject(AppleSignInService())
}
