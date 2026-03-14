import SwiftUI
import RealityKit
import ARKit

/// UIViewRepresentable wrapper to embed ARView in SwiftUI
struct ARGameView: UIViewRepresentable {
    let arSessionManager: ARSessionManager

    func makeUIView(context: Context) -> ARView {
        arSessionManager.configure()
        return arSessionManager.arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}
}
