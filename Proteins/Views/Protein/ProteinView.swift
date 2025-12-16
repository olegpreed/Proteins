//
//  ProteinView.swift
//  Proteins
//
//  Created by Oleg on 8/16/25.
//

import SwiftUI
import UIKit
import WebKit

struct ProteinView: View {
    @State private var viewModel: ViewModel
    @State private var sceneFrame: CGRect = .zero
    @State private var showHydrogen = false
    @State private var resetTrigger = false
    @State private var showErrorAlert = false
    @Environment(\.dismiss) private var dismiss

    init(ligandCode: String) {
        let viewModel = ViewModel(ligandCode: ligandCode)
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        VStack {
            if let structure = viewModel.structure {
                MoleculeViewerScreen(structure: structure,
                                     onFrameChange: { frame in
                                         sceneFrame = frame
                                     },
                                     showHydrogen: $showHydrogen,
                                     resetTrigger: $resetTrigger)
                    .transition(.opacity)
            } else {
                ProgressView()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.structure != nil)
        .navigationTitle(viewModel.ligandCode)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    shareLigand()
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
            ToolbarItem(placement: .bottomBar) {
                Button {
                    resetTrigger.toggle()
                } label: {
                    Label("Reset View", systemImage: "arrow.counterclockwise")
                }
            }
            ToolbarSpacer(placement: .bottomBar)
            ToolbarItem(placement: .bottomBar) {
                Button {
                    showHydrogen.toggle()
                } label: {
                    Label(showHydrogen ? "Hide Details" : "Show Details",
                          systemImage: showHydrogen ? "microbe" : "circle")
                }
            }
        }
        .task {
            await viewModel.loadLigand()

            if viewModel.loadingError != nil {
                showErrorAlert = true
            }
        }
        .alert("Loading Error",
               isPresented: $showErrorAlert,
               actions: {
                   Button("OK") {
                       dismiss()
                   }
               },
               message: {
                   if let error = viewModel.loadingError {
                       Text(error.localizedDescription)
                   }
               })
    }

    private func shareLigand() {
        let activityVC = viewModel.createShareActivityController(sceneFrame: sceneFrame)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController
        {
            var presentingVC = rootVC
            while let presented = presentingVC.presentedViewController {
                presentingVC = presented
            }

            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = presentingVC.view
                popover.sourceRect = CGRect(
                    x: presentingVC.view.bounds.midX,
                    y: presentingVC.view.bounds.midY,
                    width: 0,
                    height: 0
                )
                popover.permittedArrowDirections = []
            }

            presentingVC.present(activityVC, animated: true)
        }
    }
}

#Preview {
    ProteinView(ligandCode: "13R")
}
