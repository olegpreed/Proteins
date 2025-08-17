//
//  CameraVC.swift
//  Proteins
//
//  Created by Oleg on 8/11/25.
//

import UIKit
import AVFoundation

final class CameraPreviewVC: UIViewController {
    
    let captureSession = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer?
    var greenOverlay: CALayer!
//    var blurView: UIVisualEffectView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCaptureSession()
        addGreenOverlay()
//        addBlurEffect()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
//        blurView.frame = view.bounds
        greenOverlay.frame = view.bounds
    }

    
    private func setupCaptureSession() {
        guard let videoCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                               for: .video,
                                                               position: .front) else {
            print("No front camera found") // add error throwing
            return
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            }
        } catch {
            print("Error accessing camera: \(error)") // add error throwing
            return
        }
        
        // Create preview layer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = .resizeAspectFill
        if let previewLayer = previewLayer {
            view.layer.addSublayer(previewLayer)
        }
        
        // Start the session
//        captureSession.startRunning()
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }
    
    private func addGreenOverlay() {
        greenOverlay = CALayer()
        greenOverlay.backgroundColor = UIColor.systemGreen.cgColor
        greenOverlay.compositingFilter = "darkenBlendMode"
        view.layer.addSublayer(greenOverlay)
    }
    
//    private func addBlurEffect() {
//        let blurEffect = UIBlurEffect(style: .regular)
//        blurView = UIVisualEffectView(effect: blurEffect)
//        blurView.frame = view.bounds
//        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        view.addSubview(blurView)
//    }
}
