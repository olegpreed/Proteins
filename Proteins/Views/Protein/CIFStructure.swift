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
