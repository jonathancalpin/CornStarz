import SwiftUI
import RealityKit
import ARKit

struct ARGameView: UIViewRepresentable {
    let arSessionManager: ARSessionManager
    var onTap: ((CGPoint) -> Void)?
    var tapEnabled: Bool = true

    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: onTap)
    }

    func makeUIView(context: Context) -> ARView {
        arSessionManager.configure()
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arSessionManager.arView.addGestureRecognizer(tapGesture)
        context.coordinator.tapGesture = tapGesture
        return arSessionManager.arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.onTap = onTap
        context.coordinator.tapGesture?.isEnabled = tapEnabled
    }

    class Coordinator: NSObject {
        var onTap: ((CGPoint) -> Void)?
        var tapGesture: UITapGestureRecognizer?

        init(onTap: ((CGPoint) -> Void)?) {
            self.onTap = onTap
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            let location = gesture.location(in: gesture.view)
            onTap?(location)
        }
    }
}
