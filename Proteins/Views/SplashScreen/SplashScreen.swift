//
//  SplashScreen.swift
//  Proteins
//
//  Created by Oleg on 8/24/25.
//

import RiveRuntime
import SwiftUI

class IntroRiveVM: RiveViewModel {
    @Published var finished = false

    init() {
        super.init(fileName: "proteins", stateMachineName: "State Machine 1")
    }

    @objc func onRiveEventReceived(onRiveEvent riveEvent: RiveEvent) {
        if riveEvent as? RiveGeneralEvent != nil {
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.5)) {
                    self.finished = true
                }
            }
        }
    }
}

struct SplashScreen: View {
    @StateObject private var vm = IntroRiveVM()

    var body: some View {
        ZStack {
            if vm.finished {
                StartView()
                    .transition(.opacity)
            } else {
                VStack {
                    vm.view()
                }
                .frame(maxHeight: 128)
            }
        }
        .animation(.easeInOut, value: vm.finished)
    }
}

#Preview {
    SplashScreen()
}
