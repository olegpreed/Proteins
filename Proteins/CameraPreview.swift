//
//  CameraView.swift
//  Proteins
//
//  Created by Oleg on 8/11/25.
//

import SwiftUI

struct CameraPreview: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> CameraVC {
        CameraVC(scannerDelegate: context.coordinator)
    }
    
    func updateUIViewController(_ uiViewController: CameraVC, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(scannerView: self)
    }
    
    final class Coordinator: NSObject, CameraVCDelegate {
        
        private let scannerView: CameraPreview
        
        init(scannerView: CameraPreview) {
            self.scannerView = scannerView
        }
        
        func didFind(barcode: String) {
            scannerView.scannedCode = barcode
        }
        
        func didSurface(error: CameraError) {
            switch error {
            case .invalidDeviceInput:
                scannerView.alertItem = AlertContext.invalidDeviceInput
            case .invalidScannedValue:
                scannerView.alertItem = AlertContext.invalidScannedType
            }
        }
    }
}

