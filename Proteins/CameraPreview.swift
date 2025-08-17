//
//  CameraView.swift
//  Proteins
//
//  Created by Oleg on 8/11/25.
//

import SwiftUI

struct CameraPreview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CameraPreviewVC {
        return CameraPreviewVC()
    }
    
    func updateUIViewController(_ uiViewController: CameraPreviewVC, context: Context) {}
}
