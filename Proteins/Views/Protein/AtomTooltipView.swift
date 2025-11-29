import SwiftUI

struct AtomDetailsSheet: View {
    let atom: CIFAtom
    @Environment(\.dismiss) private var dismiss

    var body: some View {
            List {
                Section {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(elementColor(for: atom.element))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text(atom.element)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(atom.element == "H" ? .black : .white)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(elementName(for: atom.element))
                                .font(.title2)
                                .fontWeight(.semibold)

                            Text("Element: \(atom.element)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Atom Information") {
                    LabeledContent("Label", value: atom.label)

                    if let altLabel = atom.alternateLabel {
                        LabeledContent("Alternate Label", value: altLabel)
                    }

                    if let charge = atom.charge, charge != 0 {
                        LabeledContent("Charge", value: "\(charge > 0 ? "+" : "")\(charge)")
                    }

                    LabeledContent("Component ID", value: atom.componentID)
                }

                Section("Properties") {
                    if atom.isAromatic {
                        HStack {
                            Image(systemName: "hexagon")
                                .foregroundColor(.purple)
                            Text("Aromatic")
                            Spacer()
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                        }
                    }

                    if atom.isBackboneAtom {
                        HStack {
                            Image(systemName: "link")
                                .foregroundColor(.blue)
                            Text("Backbone Atom")
                            Spacer()
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                        }
                    }

                    if !atom.isAromatic && !atom.isBackboneAtom {
                        Text("No special properties")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }
                }

                if atom.x != nil || atom.idealX != nil {
                    Section("Coordinates") {
                        if let x = atom.x, let y = atom.y, let z = atom.z {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Model Coordinates")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("X: \(String(format: "%.3f", x))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("Y: \(String(format: "%.3f", y))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("Z: \(String(format: "%.3f", z))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        if let x = atom.idealX, let y = atom.idealY, let z = atom.idealZ {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Ideal Coordinates")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("X: \(String(format: "%.3f", x))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("Y: \(String(format: "%.3f", y))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("Z: \(String(format: "%.3f", z))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
    }

    private func elementColor(for element: String) -> Color {
        switch element.uppercased() {
        case "H":
            return Color.white.opacity(0.9)
        case "C":
            return Color.gray
        case "N":
            return Color.blue
        case "O":
            return Color.red
        case "S":
            return Color.yellow
        case "P":
            return Color.orange
        default:
            return Color.teal
        }
    }

    private func elementName(for element: String) -> String {
        switch element.uppercased() {
        case "H": return "Hydrogen"
        case "C": return "Carbon"
        case "N": return "Nitrogen"
        case "O": return "Oxygen"
        case "S": return "Sulfur"
        case "P": return "Phosphorus"
        case "F": return "Fluorine"
        case "CL": return "Chlorine"
        case "BR": return "Bromine"
        case "I": return "Iodine"
        case "NA": return "Sodium"
        case "K": return "Potassium"
        case "CA": return "Calcium"
        case "MG": return "Magnesium"
        case "FE": return "Iron"
        case "ZN": return "Zinc"
        default: return element
        }
    }
}
