import Combine
import RealityKit
import SwiftUI
import UIKit
import simd

struct MoleculeSceneView: View {
    let structure: CIFStructure
    let rotation: simd_quatf
    let zoom: Float
    @StateObject private var coordinator = MoleculeSceneCoordinator()
    
    var body: some View {
        RealityView { content in
            if let existing = coordinator.rootEntity {
                content.remove(existing)
                coordinator.rootEntity = nil
            }
            
            if let newRoot = MoleculeSceneBuilder.makeScene(for: structure, rotation: rotation, zoom: zoom) {
                content.add(newRoot)
                coordinator.rootEntity = newRoot
            }
        } update: { content in
            if let existing = coordinator.rootEntity {
                content.remove(existing)
                coordinator.rootEntity = nil
            }
            
            if let newRoot = MoleculeSceneBuilder.makeScene(for: structure, rotation: rotation, zoom: zoom) {
                content.add(newRoot)
                coordinator.rootEntity = newRoot
            }
        }
    }
}

final class MoleculeSceneCoordinator: ObservableObject {
    var rootEntity: Entity?
}

enum MoleculeSceneBuilder {
    static func makeScene(for structure: CIFStructure, rotation: simd_quatf, zoom: Float) -> Entity? {
        let atomsWithPositions = structure.atoms.compactMap { atom -> (CIFAtom, SIMD3<Float>)? in
            guard let position = atom.scenePosition else { return nil }
            return (atom, position)
        }
        
        guard !atomsWithPositions.isEmpty else {
            return nil
        }
        
        let centeredAtoms = centerAndScale(atomsWithPositions)
        let root = Entity()
        root.name = "MoleculeRoot"
        
        addLighting(to: root)
        addCamera(to: root, radius: centeredAtoms.maxRadius, zoom: zoom)
        
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
        let mesh = MeshResource.generateSphere(radius: 0.08)
        let material = SimpleMaterial(color: color(for: atom.element), roughness: 0.25, isMetallic: false)
        
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.transform.translation = position
        entity.name = "atom:\(atom.label)"
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
        var offsetAxis = simd_cross(normalizedDirection, SIMD3<Float>(0, 0, 1))
        if simd_length_squared(offsetAxis) < 0.0001 {
            offsetAxis = simd_cross(normalizedDirection, SIMD3<Float>(0, 1, 0))
        }
        offsetAxis = simd_normalize(offsetAxis)
        
        let container = Entity()
        container.transform.translation = midpoint
        container.transform.rotation = rotation
        container.name = "bond"
        
        let primaryMaterial = SimpleMaterial(color: .systemGray3, roughness: 0.15, isMetallic: true)
        let secondaryMaterial = SimpleMaterial(color: .systemGray4, roughness: 0.15, isMetallic: true)
        let baseRadius: Float = 0.035
        let secondaryRadius: Float = 0.024
        let tertiaryRadius: Float = 0.02
        let offsetDistance: Float = 0.05
        
        func addCylinder(radius: Float, material: SimpleMaterial, offsetScale: Float) {
            let mesh = MeshResource.generateCylinder(height: distance, radius: radius)
            let cylinder = ModelEntity(mesh: mesh, materials: [material])
            cylinder.transform.translation = offsetAxis * offsetDistance * offsetScale
            container.addChild(cylinder)
        }
        
        switch order {
        case .double:
            addCylinder(radius: secondaryRadius, material: secondaryMaterial, offsetScale: 1)
            addCylinder(radius: secondaryRadius, material: secondaryMaterial, offsetScale: -1)
        case .triple:
            addCylinder(radius: baseRadius * 0.9, material: primaryMaterial, offsetScale: 0)
            addCylinder(radius: tertiaryRadius, material: secondaryMaterial, offsetScale: 1)
            addCylinder(radius: tertiaryRadius, material: secondaryMaterial, offsetScale: -1)
        default:
            addCylinder(radius: baseRadius, material: primaryMaterial, offsetScale: 0)
        }
        
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
    
    private static func addCamera(to root: Entity, radius: Float, zoom: Float) {
        let camera = Entity()
        camera.components.set(PerspectiveCameraComponent())
        let baseDistance = max(radius * 2.5, 2.5)
        let distance = max(baseDistance / max(zoom, 0.25), 1.0)
        var transform = Transform()
        transform.translation = SIMD3<Float>(0, 0, distance)
        camera.transform = transform
        camera.look(at: .zero, from: transform.translation, relativeTo: nil)
        root.addChild(camera)
    }
    
    private static func color(for element: String) -> UIColor {
        switch element.uppercased() {
        case "H":
            return UIColor.white
        case "C":
            return UIColor.systemGray2
        case "N":
            return UIColor.systemBlue
        case "O":
            return UIColor.systemRed
        case "S":
            return UIColor.systemYellow
        case "P":
            return UIColor.systemOrange
        default:
            return UIColor.systemTeal
        }
    }
    
    private static func centerAndScale(_ atoms: [(CIFAtom, SIMD3<Float>)]) -> (positions: [(atom: CIFAtom, position: SIMD3<Float>)], lookup: [String: SIMD3<Float>], maxRadius: Float) {
        let positions = atoms.map { $0.1 }
        let count = Float(positions.count)
        let centroid = positions.reduce(SIMD3<Float>(repeating: 0), +) / max(count, 1)
        let centered = positions.map { $0 - centroid }
        let maxRadius = centered.map { simd_length($0) }.max() ?? 1
        let scale = maxRadius > 0 ? 1.5 / maxRadius : 1
        
        var mapped: [(CIFAtom, SIMD3<Float>)] = []
        var lookup: [String: SIMD3<Float>] = [:]
        
        for (index, entry) in atoms.enumerated() {
            let position = centered[index] * scale
            mapped.append((entry.0, position))
            lookup[entry.0.label] = position
            lookup["\(entry.0.componentID).\(entry.0.label)"] = position
        }
        
        return (positions: mapped, lookup: lookup, maxRadius: maxRadius * scale)
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
    var scenePosition: SIMD3<Float>? {
        let useX = idealX ?? x
        let useY = idealY ?? y
        let useZ = idealZ ?? z
        guard
            let x = useX,
            let y = useY,
            let z = useZ
        else { return nil }
        return SIMD3<Float>(Float(x), Float(y), Float(z))
    }
}
