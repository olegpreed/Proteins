//
//  SplashScreen.swift
//  Proteins
//
//  Created by Oleg on 8/24/25.
//

import SwiftUI
import RiveRuntime

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
                SignInView()
                    .transition(.opacity)
            } else {
                VStack {
                    vm.view()
                }
                .frame(maxHeight: 128)
            }
        }
    }
}

#Preview {
    SplashScreen()
}
