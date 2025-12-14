//
//  ProteinView_ViewModel.swift
//  Proteins
//
//  Created by Artem Forkunov on 29/11/25.
//

import Foundation
import UIKit

extension ProteinView {
    enum LigandLoadError: Error, LocalizedError {
        case invalidCode, invalidResponse, invalidData, unknownError

        var errorDescription: String? {
            switch self {
            case .invalidCode: "Invalid ligand code."
            case .invalidResponse: "Invalid response from the server."
            case .invalidData: "Invalid data received from the server."
            default: nil
            }
        }
    }

    @Observable
    class ViewModel {
        private static let ligandBaseURL = "https://files.rcsb.org/ligands/view/"

        let ligandCode: String

        private(set) var structure: CIFStructure?
        private(set) var loadingError: LigandLoadError?

        init(ligandCode: String) {
            self.ligandCode = ligandCode
        }

        func loadLigand() async {
            do {
                let cifData = try await fetchCIFData(for: ligandCode)
                let cif = try CIFParser.parse(from: cifData)

                guard let dataBlock = cif.dataBlocks.first else {
                    throw LigandLoadError.invalidData
                }

                structure = dataBlock.structure()
            } catch let error as LigandLoadError {
                loadingError = error
            } catch _ as CIFParserError {
                loadingError = .invalidData
            } catch {
                loadingError = .unknownError
            }
        }

        private func fetchCIFData(for ligandCode: String) async throws -> String {
            guard let url = URL(string: "\(Self.ligandBaseURL)\(ligandCode).cif") else {
                throw LigandLoadError.invalidCode
            }

            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw LigandLoadError.invalidResponse
            }
            guard let text = String(data: data, encoding: .utf8) else {
                throw LigandLoadError.invalidData
            }
            return text
        }

        func createShareActivityController(sceneFrame: CGRect) -> UIActivityViewController {
            let rcsbURL = URL(string: "https://www.rcsb.org/ligand/\(ligandCode)")!

            // Capture screenshot using window snapshot (works with RealityKit)
            let screenshot = captureWindowScreenshot(sceneFrame: sceneFrame)

            var items: [Any] = [
                "Ligand: \(ligandCode)",
                rcsbURL,
            ]

            if let screenshot {
                items.append(screenshot)
            }

            let activityVC = UIActivityViewController(
                activityItems: items,
                applicationActivities: nil
            )

            return activityVC
        }

        private func captureWindowScreenshot(sceneFrame: CGRect) -> UIImage? {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first
            else {
                return nil
            }

            // Capture full window
            let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
            let fullImage = renderer.image { _ in
                window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
            }

            // Crop to just the 3D scene area (remove UI controls)
            guard sceneFrame != .zero,
                  let cgImage = fullImage.cgImage
            else {
                return fullImage
            }

            // Add insets to cut interface elements from top and bottom
            let topInset: CGFloat = 150
            let bottomInset: CGFloat = 100

            let adjustedFrame = CGRect(
                x: sceneFrame.origin.x,
                y: sceneFrame.origin.y + topInset,
                width: sceneFrame.width,
                height: sceneFrame.height - topInset - bottomInset
            )

            // Convert frame to pixel coordinates (accounting for screen scale)
            let scale = fullImage.scale
            let cropRect = CGRect(
                x: adjustedFrame.origin.x * scale,
                y: adjustedFrame.origin.y * scale,
                width: adjustedFrame.size.width * scale,
                height: adjustedFrame.size.height * scale
            )

            guard let croppedCGImage = cgImage.cropping(to: cropRect) else {
                return fullImage
            }

            return UIImage(cgImage: croppedCGImage, scale: scale, orientation: fullImage.imageOrientation)
        }
    }
}
