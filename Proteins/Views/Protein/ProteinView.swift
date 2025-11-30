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
    
    init(ligandCode: String) {
        let viewModel = ViewModel(ligandCode: ligandCode)
        self._viewModel = .init(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack {
            if let error = viewModel.loadingError {
                Text("Loading Error: \(error.localizedDescription)")
            } else if let structure = viewModel.structure {
                MoleculeViewerScreen(structure: structure, onFrameChange: { frame in
                    sceneFrame = frame
                })
            } else {
                Text("Loading...")
            }
        }
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
        }
        .task {
            await viewModel.loadLigand()
        }
    }
    
    private func shareLigand() {
        let ligandCode = viewModel.ligandCode
        let rcsbURL = URL(string: "https://www.rcsb.org/ligand/\(ligandCode)")!
        
        // Capture screenshot using window snapshot (works with RealityKit)
        let screenshot = captureWindowScreenshot()
        
        var items: [Any] = [
            "Ligand: \(ligandCode)",
            rcsbURL
        ]
        
        if let screenshot = screenshot {
            items.append(screenshot)
        }
        
        let activityVC = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
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
    
    private func captureWindowScreenshot() -> UIImage? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        
        // Capture full window
        let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
        let fullImage = renderer.image { context in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        
        // Crop to just the 3D scene area (remove UI controls)
        guard sceneFrame != .zero,
              let cgImage = fullImage.cgImage else {
            return fullImage
        }
        
        // Convert frame to pixel coordinates (accounting for screen scale)
        let scale = fullImage.scale
        let cropRect = CGRect(
            x: sceneFrame.origin.x * scale,
            y: sceneFrame.origin.y * scale,
            width: sceneFrame.size.width * scale,
            height: sceneFrame.size.height * scale
        )
        
        guard let croppedCGImage = cgImage.cropping(to: cropRect) else {
            return fullImage
        }
        
        return UIImage(cgImage: croppedCGImage, scale: scale, orientation: fullImage.imageOrientation)
    }
}

#Preview {
    ProteinView(ligandCode: "13M")
}
