import SwiftUI
import simd

struct MoleculeViewerScreen: View {
    let structure: CIFStructure

    @State private var yaw: Float = 0
    @State private var pitch: Float = 0
    @State private var zoom: Float = 1
    @State private var lastDragTranslation: CGSize?
    @State private var lastMagnification: CGFloat = 1

    private let minZoom: Float = 0.3
    private let maxZoom: Float = 3.0
    private let rotationSpeed: Float = 0.01

    var body: some View {
        VStack(spacing: 16) {
            MoleculeSceneView(structure: structure, rotation: currentRotation, zoom: zoom)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
                .gesture(dragGesture)
                .simultaneousGesture(magnificationGesture)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Rotation: yaw \(formattedDegrees(yaw)), pitch \(formattedDegrees(pitch))")
                    Spacer()
                    Text("Zoom: \(String(format: "%.2f×", Double(zoom)))")
                }
                Text("Drag to rotate, pinch to zoom.")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                Button {
                    resetView()
                } label: {
                    Label("Reset View", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .navigationTitle("Molecule Viewer")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(uiColor: .systemBackground))
    }

    private var currentRotation: simd_quatf {
        let yawQuat = simd_quatf(angle: yaw, axis: SIMD3<Float>(0, 1, 0))
        let pitchQuat = simd_quatf(angle: pitch, axis: SIMD3<Float>(1, 0, 0))
        return yawQuat * pitchQuat
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if let last = lastDragTranslation {
                    let deltaX = Float(value.translation.width - last.width)
                    let deltaY = Float(value.translation.height - last.height)
                    yaw += deltaX * rotationSpeed
                    pitch = clamp(pitch + deltaY * rotationSpeed, min: -.pi / 2, max: .pi / 2)
                }
                lastDragTranslation = value.translation
            }
            .onEnded { _ in
                lastDragTranslation = nil
            }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = Float(value / max(lastMagnification, 0.001))
                zoom = clamp(zoom * delta, min: minZoom, max: maxZoom)
                lastMagnification = value
            }
            .onEnded { _ in
                lastMagnification = 1
            }
    }

    private func resetView() {
        yaw = 0
        pitch = 0
        zoom = 1
    }

    private func formattedDegrees(_ radians: Float) -> String {
        let degrees = radians * 180 / .pi
        return String(format: "%.0f°", Double(degrees))
    }

    private func clamp<T: Comparable>(_ value: T, min minValue: T, max maxValue: T) -> T {
        Swift.max(minValue, Swift.min(value, maxValue))
    }
}

#Preview {
//    MoleculeViewerScreen(structure: );
}
