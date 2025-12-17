//
//  MoleculeSceneView.swift
//  Proteins
//
//  Created by Artem Forkunov on 30/11/25.
//

import Combine
import RealityKit
import simd
import SwiftUI
import UIKit

struct MoleculeSceneView: View {
    let structure: CIFStructure
    let rotation: simd_quatf
    let zoom: Float
    let cameraOffset: SIMD2<Float>
    let showHydrogen: Bool
    @ObservedObject var coordinator: MoleculeSceneCoordinator

    var body: some View {
        RealityView { content in
            if let existing = coordinator.rootEntity {
                content.remove(existing)
                coordinator.rootEntity = nil
            }

            coordinator.structure = structure
            if let newRoot = MoleculeSceneBuilder.makeScene(for: structure, rotation: rotation, zoom: zoom, cameraOffset: cameraOffset, showHydrogen: showHydrogen) {
                content.add(newRoot)
                coordinator.rootEntity = newRoot
            }
        } update: { content in
            if let existing = coordinator.rootEntity {
                content.remove(existing)
                coordinator.rootEntity = nil
            }

            coordinator.structure = structure
            if let newRoot = MoleculeSceneBuilder.makeScene(for: structure, rotation: rotation, zoom: zoom, cameraOffset: cameraOffset, showHydrogen: showHydrogen) {
                content.add(newRoot)
                coordinator.rootEntity = newRoot

                // Re-apply selection outline after scene update
                coordinator.reapplySelection()
            }
        }
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    if value.entity.name.hasPrefix("atom:") {
                        coordinator.tappedAtom = coordinator.findAtom(named: value.entity.name)
                        coordinator.updateSelection(entityName: value.entity.name)
                    } else {
                        coordinator.tappedAtom = nil
                        coordinator.updateSelection(entityName: nil)
                    }
                }
        )
    }
}

final class MoleculeSceneCoordinator: ObservableObject {
    var rootEntity: Entity?
    var structure: CIFStructure?
    @Published var tappedAtom: CIFAtom?
    @Published var tapLocation: CGPoint?
    var selectedAtomEntity: Entity?
    var outlineEntity: Entity?
    var selectedAtomName: String? // Track selected atom across scene updates

    func findAtom(named name: String) -> CIFAtom? {
        guard let structure else { return nil }
        // Entity names are in format "atom:label"
        let label = name.replacingOccurrences(of: "atom:", with: "")
        return structure.atoms.first { $0.label == label }
    }

    func findAtomEntity(named name: String) -> Entity? {
        guard let rootEntity else { return nil }
        return findEntityInHierarchy(rootEntity, name: name)
    }

    private func findEntityInHierarchy(_ entity: Entity, name: String) -> Entity? {
        if entity.name == name {
            return entity
        }
        for child in entity.children {
            if let found = findEntityInHierarchy(child, name: name) {
                return found
            }
        }
        return nil
    }

    func updateSelection(entityName: String?) {
        // Store the selected atom name for persistence across scene updates
        selectedAtomName = entityName

        // Remove old outline
        if let outline = outlineEntity {
            outline.removeFromParent()
            outlineEntity = nil
        }

        guard let entityName,
              let atomEntity = findAtomEntity(named: entityName)
        else {
            selectedAtomEntity = nil
            selectedAtomName = nil
            return
        }

        selectedAtomEntity = atomEntity

        // Create outline
        let outline = MoleculeSceneBuilder.makeOutlineEntity()
        outline.transform.translation = atomEntity.transform.translation
        if let parent = atomEntity.parent {
            parent.addChild(outline)
            outlineEntity = outline
        }
    }

    func reapplySelection() {
        // Re-apply selection after scene recreation
        if let selectedName = selectedAtomName {
            updateSelection(entityName: selectedName)
        }
    }
}

enum MoleculeSceneBuilder {
    private static let bondRadius: Float = 0.008
    private static let bondSpacing: Float = 0.025

    private static func createSingleBondTemplate(height: Float, material: SimpleMaterial) -> Entity {
        let mesh = MeshResource.generateCylinder(height: height, radius: bondRadius)
        return ModelEntity(mesh: mesh, materials: [material])
    }

    private static func createDoubleBondTemplate(height: Float, material: SimpleMaterial) -> Entity {
        let container = Entity()

        let cylinder1 = ModelEntity(
            mesh: MeshResource.generateCylinder(height: height, radius: bondRadius),
            materials: [material]
        )
        cylinder1.position.x = -bondSpacing / 2

        let cylinder2 = ModelEntity(
            mesh: MeshResource.generateCylinder(height: height, radius: bondRadius),
            materials: [material]
        )
        cylinder2.position.x = bondSpacing / 2

        container.addChild(cylinder1)
        container.addChild(cylinder2)
        return container
    }

    private static func createTripleBondTemplate(height: Float, material: SimpleMaterial) -> Entity {
        let container = Entity()

        let cylinder1 = ModelEntity(
            mesh: MeshResource.generateCylinder(height: height, radius: bondRadius),
            materials: [material]
        )
        cylinder1.position.x = -bondSpacing

        let cylinder2 = ModelEntity(
            mesh: MeshResource.generateCylinder(height: height, radius: bondRadius),
            materials: [material]
        )
        cylinder2.position.x = 0

        let cylinder3 = ModelEntity(
            mesh: MeshResource.generateCylinder(height: height, radius: bondRadius),
            materials: [material]
        )
        cylinder3.position.x = bondSpacing

        container.addChild(cylinder1)
        container.addChild(cylinder2)
        container.addChild(cylinder3)
        return container
    }

    static func makeOutlineEntity() -> Entity {
        let entity = Entity()
        entity.name = "selection-outline"

        // Create a glowing outline using a slightly larger transparent sphere
        let atomRadius: Float = 0.05
        let outlineRadius: Float = atomRadius * 1.8

        var outlineMaterial = UnlitMaterial(color: .accent)
        outlineMaterial.blending = .transparent(opacity: 0.4)

        let outlineSphere = ModelEntity(
            mesh: MeshResource.generateSphere(radius: outlineRadius),
            materials: [outlineMaterial]
        )

        entity.addChild(outlineSphere)

        // Add a second, thinner ring for extra visibility
        var ringMaterial = UnlitMaterial(color: .accent)
        ringMaterial.blending = .transparent(opacity: 0.8)

        let innerRing = ModelEntity(
            mesh: MeshResource.generateSphere(radius: outlineRadius * 0.9),
            materials: [ringMaterial]
        )

        entity.addChild(innerRing)

        return entity
    }

    static func makeScene(for structure: CIFStructure, rotation: simd_quatf, zoom: Float, cameraOffset: SIMD2<Float>, showHydrogen: Bool) -> Entity? {
        // Check if we should use ideal or model coordinates
        // Use model coords if ANY atom is missing ideal coords (to avoid coordinate system mismatch)
        let useIdealCoords = structure.atoms.allSatisfy { atom in
            atom.idealX != nil && atom.idealY != nil && atom.idealZ != nil
        }

        let atomsWithPositions = structure.atoms.compactMap { atom -> (CIFAtom, SIMD3<Float>)? in
            // Filter out hydrogen atoms if showHydrogen is false
            if !showHydrogen, atom.element.uppercased() == "H" {
                return nil
            }
            guard let position = atom.scenePosition(preferIdeal: useIdealCoords) else { return nil }
            return (atom, position)
        }

        guard !atomsWithPositions.isEmpty else {
            return nil
        }

        let centeredAtoms = centerAndScale(atomsWithPositions, bonds: structure.bonds)
        let root = Entity()
        root.name = "MoleculeRoot"

        addLighting(to: root)
        addCamera(to: root, radius: centeredAtoms.maxRadius, zoom: zoom, offset: cameraOffset)

        let moleculeEntity = Entity()
        moleculeEntity.name = "MoleculeModel"

        for entry in centeredAtoms.positions {
            let atomEntity = makeAtomEntity(atom: entry.atom, position: entry.position)
            moleculeEntity.addChild(atomEntity)
        }

        for bond in structure.bonds {
            guard
                let first = centeredAtoms.lookup[bond.atomID1] ?? centeredAtoms.lookup["\(bond.componentID).\(bond.atomID1)"],
                let second = centeredAtoms.lookup[bond.atomID2] ?? centeredAtoms.lookup["\(bond.componentID).\(bond.atomID2)"]
            else {
                continue
            }
            if let bondEntity = makeBondEntity(from: first, to: second, order: bond.order) {
                moleculeEntity.addChild(bondEntity)
            }
        }

        moleculeEntity.transform.rotation = rotation
        root.addChild(moleculeEntity)
        return root
    }

    private static func makeAtomEntity(atom: CIFAtom, position: SIMD3<Float>) -> ModelEntity {
        let atomRadius: Float = 0.05
        let mesh = MeshResource.generateSphere(radius: atomRadius)
        let material = SimpleMaterial(color: color(for: atom.element), roughness: 0.5, isMetallic: true)

        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.transform.translation = position
        entity.name = "atom:\(atom.label)"

        // Add collision component for hit testing
        entity.components.set(CollisionComponent(shapes: [.generateSphere(radius: atomRadius)]))
        entity.components.set(InputTargetComponent())

        return entity
    }

    private static func makeBondEntity(from first: SIMD3<Float>, to second: SIMD3<Float>, order: CIFBondOrder) -> Entity? {
        let direction = second - first
        let distance = simd_length(direction)
        guard distance > 0.0001 else { return nil }

        let midpoint = (first + second) / 2
        let upAxis = SIMD3<Float>(0, 1, 0)
        let normalizedDirection = simd_normalize(direction)
        let rotation = simd_quatf(from: upAxis, to: normalizedDirection)

        let container = Entity()
        container.transform.translation = midpoint
        container.transform.rotation = rotation
        container.name = "bond"

        let primaryMaterial = SimpleMaterial(color: .systemGray3, roughness: 0.9, isMetallic: true)
        let atomRadius: Float = 0.05
        let bondLength = max(distance - (atomRadius * 1.6), 0.001)

        let bondEntity: Entity = switch order {
        case .double, .aromatic:
            createDoubleBondTemplate(height: bondLength, material: primaryMaterial)
        case .triple:
            createTripleBondTemplate(height: bondLength, material: primaryMaterial)
        default:
            createSingleBondTemplate(height: bondLength, material: primaryMaterial)
        }

        container.addChild(bondEntity)

        return container
    }

    private static func addLighting(to root: Entity) {
        let light = DirectionalLight()
        light.light.intensity = 2000
        light.light.color = .white
        light.transform = Transform(pitch: -.pi / 4, yaw: .pi / 4, roll: 0)
        root.addChild(light)

        let ambientLight = PointLight()
        ambientLight.light.intensity = 500
        ambientLight.light.color = .white
        ambientLight.transform.translation = SIMD3<Float>(1.5, 1.5, 1.5)
        root.addChild(ambientLight)
    }

    private static func addCamera(to root: Entity, radius: Float, zoom: Float, offset: SIMD2<Float>) {
        let camera = Entity()
        camera.components.set(PerspectiveCameraComponent())
        let baseDistance = max(radius * 2.5, 2.5)
        let distance = max(baseDistance / max(zoom, 0.25), 1.0)
        var transform = Transform()
        transform.translation = SIMD3<Float>(offset.x, offset.y, distance)
        camera.transform = transform
        camera.look(at: SIMD3<Float>(offset.x, offset.y, 0), from: transform.translation, relativeTo: nil)
        root.addChild(camera)
    }

    private static func color(for element: String) -> UIColor {
        switch element.uppercased() {
        case "H":
            UIColor.white
        case "C":
            UIColor.systemGray4
        case "N":
            UIColor.systemBlue
        case "O":
            UIColor.systemRed
        case "S":
            UIColor.systemYellow
        case "P":
            UIColor.systemOrange
        case "ZN":
            UIColor.systemBrown
        case "FE":
            UIColor.systemOrange
        case "MG":
            UIColor.systemGreen
        case "CA":
            UIColor.systemGray
        case "NA", "K":
            UIColor.systemPurple
        case "CL", "BR", "I":
            UIColor.systemTeal
        default:
            UIColor.systemIndigo
        }
    }

    private static func centerAndScale(_ atoms: [(CIFAtom, SIMD3<Float>)], bonds: [CIFBond]) -> (positions: [(atom: CIFAtom, position: SIMD3<Float>)], lookup: [String: SIMD3<Float>], maxRadius: Float) {
        let positions = atoms.map(\.1)
        let count = Float(positions.count)
        let centroid = positions.reduce(SIMD3<Float>(repeating: 0), +) / max(count, 1)
        let centered = positions.map { $0 - centroid }

        // Create a temporary lookup for calculating bond lengths
        var tempLookup: [String: SIMD3<Float>] = [:]
        for (index, entry) in atoms.enumerated() {
            tempLookup[entry.0.label] = centered[index]
            tempLookup["\(entry.0.componentID).\(entry.0.label)"] = centered[index]
        }

        // Calculate average bond length to normalize scaling
        var bondLengths: [Float] = []
        for bond in bonds {
            if let pos1 = tempLookup[bond.atomID1] ?? tempLookup["\(bond.componentID).\(bond.atomID1)"],
               let pos2 = tempLookup[bond.atomID2] ?? tempLookup["\(bond.componentID).\(bond.atomID2)"]
            {
                let length = simd_length(pos2 - pos1)
                if length > 0.0001 { // Avoid zero-length bonds
                    bondLengths.append(length)
                }
            }
        }

        // Determine scale factor based on average bond length
        let scale: Float
        if !bondLengths.isEmpty {
            let avgBondLength = bondLengths.reduce(0, +) / Float(bondLengths.count)
            let targetBondLength: Float = 0.35 // Target bond length in scene units
            scale = avgBondLength > 0 ? targetBondLength / avgBondLength : 1
        } else {
            // Fallback to old scaling method if no bonds
            let maxRadius = centered.map { simd_length($0) }.max() ?? 1
            // For single atoms or molecules with zero spread, use scale of 1
            // This ensures they remain visible at their natural size
            scale = maxRadius > 0.001 ? 1.5 / maxRadius : 1
        }

        var mapped: [(CIFAtom, SIMD3<Float>)] = []
        var lookup: [String: SIMD3<Float>] = [:]

        for (index, entry) in atoms.enumerated() {
            let position = centered[index] * scale
            mapped.append((entry.0, position))
            lookup[entry.0.label] = position
            lookup["\(entry.0.componentID).\(entry.0.label)"] = position
        }

        var maxRadius = centered.map { simd_length($0) }.max() ?? 1
        maxRadius = maxRadius * scale

        // Ensure minimum radius for single atoms or very small molecules
        // This prevents camera positioning issues
        if maxRadius < 0.1 {
            maxRadius = 0.5
        }

        return (positions: mapped, lookup: lookup, maxRadius: maxRadius)
    }
}

private extension Transform {
    init(pitch: Float, yaw: Float, roll: Float) {
        let rotation = simd_quatf(angle: yaw, axis: SIMD3<Float>(0, 1, 0)) *
            simd_quatf(angle: pitch, axis: SIMD3<Float>(1, 0, 0)) *
            simd_quatf(angle: roll, axis: SIMD3<Float>(0, 0, 1))
        self.init(scale: .one, rotation: rotation, translation: .zero)
    }
}

private extension CIFAtom {
    func scenePosition(preferIdeal: Bool = true) -> SIMD3<Float>? {
        let useX: Double?
        let useY: Double?
        let useZ: Double?

        if preferIdeal {
            useX = idealX ?? x
            useY = idealY ?? y
            useZ = idealZ ?? z
        } else {
            useX = x ?? idealX
            useY = y ?? idealY
            useZ = z ?? idealZ
        }

        guard
            let x = useX,
            let y = useY,
            let z = useZ
        else { return nil }
        return SIMD3<Float>(Float(x), Float(y), Float(z))
    }
}
