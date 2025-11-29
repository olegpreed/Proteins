//
//  MoleculeView.swift
//  Proteins
//
//  Created by Oleg on 11/26/25.
//

import SwiftUI
import RealityKit

struct MoleculeView: UIViewRepresentable {
    @Environment(\.colorScheme) private var colorScheme

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.environment.background = .color(colorScheme == .dark ? .black : .white)

        let model = try! Entity.loadModel(named: "model")
        model.model?.materials = [SimpleMaterial(color: .accent, roughness: 0.4, isMetallic: false)]
        model.scale = SIMD3<Float>(repeating: 0.01)

        let anchor = AnchorEntity(world: [0, 0, 0])
        anchor.addChild(model)
        arView.scene.anchors.append(anchor)

        // Add continuous slow rotation around Y axis
        startContinuousYRotation(entity: model, duration: 40)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        uiView.environment.background = .color(colorScheme == .dark ? .black : .white)
    }

    private func startContinuousYRotation(entity: Entity, duration: TimeInterval) {
        // One step: rotate by 180 degrees (pi radians) around Y, then schedule another step.
        func rotateStep() {
            let current = entity.transform
            let deltaQuat = simd_quatf(angle: .pi, axis: SIMD3<Float>(0, 1, 0))
            var next = current
            next.rotation = deltaQuat * current.rotation

            // Start the move animation (no completion available in RealityKit)
            _ = entity.move(
                to: next,
                relativeTo: entity.parent,
                duration: duration,
                timingFunction: .linear
            )

            // Schedule the next half-turn after this one completes
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                rotateStep()
            }
        }

        rotateStep()
    }
}

#Preview {
    MoleculeView()
}
