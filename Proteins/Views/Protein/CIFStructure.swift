//
//  CIFStructure.swift
//  Proteins
//
//  Created by Artem Forkunov on 30/11/25.
//

import Foundation

struct CIFStructure {
    let atoms: [CIFAtom]
    let bonds: [CIFBond]
}

struct CIFAtom: Identifiable, Equatable {
    let componentID: String
    let label: String
    let alternateLabel: String?
    let element: String
    let charge: Int?
    let x: Double?
    let y: Double?
    let z: Double?
    let idealX: Double?
    let idealY: Double?
    let idealZ: Double?
    let isAromatic: Bool
    let isBackboneAtom: Bool
    
    var id: String { "\(componentID).\(label)" }
}

struct CIFBond: Identifiable {
    let componentID: String
    let atomID1: String
    let atomID2: String
    let order: CIFBondOrder
    let isAromatic: Bool
    
    var id: String { "\(componentID).\(atomID1)-\(atomID2)" }
}

enum CIFBondOrder: String {
    case single = "SING"
    case double = "DOUB"
    case triple = "TRIP"
    case aromatic = "AROM"
    case quadruple = "QUAD"
    case unspecified
    
    init(rawValue value: String) {
        switch value.uppercased() {
        case "SING":
            self = .single
        case "DOUB":
            self = .double
        case "TRIP":
            self = .triple
        case "AROM":
            self = .aromatic
        case "QUAD":
            self = .quadruple
        default:
            self = .unspecified
        }
    }
}

extension CIFBondOrder: CustomStringConvertible {
    var description: String {
        switch self {
        case .single:
            return "single"
        case .double:
            return "double"
        case .triple:
            return "triple"
        case .aromatic:
            return "aromatic"
        case .quadruple:
            return "quadruple"
        case .unspecified:
            return "unspecified"
        }
    }
}

extension CIFStructure {
    /// Calculates optimal viewing angles (yaw, pitch) to show the molecule from above using PCA
    /// Returns (yaw: Float, pitch: Float) in radians
    func calculateOptimalViewingAngles() -> (yaw: Float, pitch: Float) {
        // Get 3D coordinates
        var coords: [(x: Double, y: Double, z: Double)] = []
        for atom in atoms {
            if let x = atom.idealX ?? atom.x,
               let y = atom.idealY ?? atom.y,
               let z = atom.idealZ ?? atom.z {
                coords.append((x: x, y: y, z: z))
            }
        }

        guard coords.count > 1 else { return (0, 0) }

        // Calculate centroid
        let centroidX = coords.map { $0.x }.reduce(0, +) / Double(coords.count)
        let centroidY = coords.map { $0.y }.reduce(0, +) / Double(coords.count)
        let centroidZ = coords.map { $0.z }.reduce(0, +) / Double(coords.count)

        // Center coordinates
        let centered = coords.map { (x: $0.x - centroidX, y: $0.y - centroidY, z: $0.z - centroidZ) }

        // Calculate covariance matrix
        var cov: [[Double]] = Array(repeating: Array(repeating: 0.0, count: 3), count: 3)
        let n = Double(centered.count)

        for coord in centered {
            let v = [coord.x, coord.y, coord.z]
            for i in 0..<3 {
                for j in 0..<3 {
                    cov[i][j] += v[i] * v[j] / n
                }
            }
        }

        // Find smallest eigenvector (normal to best viewing plane)
        let normal = findSmallestEigenvector(cov)

        // Convert normal vector to viewing angles
        // We want to look along the normal direction
        let yaw = Float(atan2(normal[0], normal[2]))
        let pitch = Float(asin(-normal[1]))

        return (yaw: yaw, pitch: pitch)
    }

    private func findSmallestEigenvector(_ matrix: [[Double]]) -> [Double] {
        // Use power iteration to find eigenvectors, then return best viewing direction
        var A = matrix
        var eigenpairs: [(value: Double, vector: [Double])] = []

        for _ in 0..<3 {
            let eigenvector = powerIteration(A)

            // Calculate eigenvalue
            var Av = [0.0, 0.0, 0.0]
            for i in 0..<3 {
                for j in 0..<3 {
                    Av[i] += A[i][j] * eigenvector[j]
                }
            }
            let eigenvalue = (0..<3).map { Av[$0] * eigenvector[$0] }.reduce(0, +)

            eigenpairs.append((value: abs(eigenvalue), vector: eigenvector))

            // Deflate matrix
            for i in 0..<3 {
                for j in 0..<3 {
                    A[i][j] -= eigenvalue * eigenvector[i] * eigenvector[j]
                }
            }
        }

        // Sort by eigenvalue (largest first)
        eigenpairs.sort { $0.value > $1.value }

        // Determine best viewing direction based on eigenvalue ratios
        // If the molecule is flat (smallest eigenvalue << others), use smallest eigenvector
        // Otherwise, use middle eigenvector for better side view of elongated molecules
        let middle = eigenpairs[1].value
        let smallest = eigenpairs[2].value

        // If molecule is very flat (smallest < 0.3 * middle), look perpendicular to the plane
        if smallest < 0.3 * middle {
            return eigenpairs[2].vector  // smallest eigenvector
        } else {
            // For elongated or roughly spherical molecules, use middle eigenvector
            return eigenpairs[1].vector
        }
    }

    private func powerIteration(_ matrix: [[Double]]) -> [Double] {
        var v = [1.0, 0.0, 0.0]
        let iterations = 50

        for _ in 0..<iterations {
            var newV = [0.0, 0.0, 0.0]
            for i in 0..<3 {
                for j in 0..<3 {
                    newV[i] += matrix[i][j] * v[j]
                }
            }

            let norm = sqrt(newV[0]*newV[0] + newV[1]*newV[1] + newV[2]*newV[2])
            if norm > 1e-6 {
                for i in 0..<3 {
                    newV[i] /= norm
                }
            }

            v = newV
        }

        return v
    }
}
