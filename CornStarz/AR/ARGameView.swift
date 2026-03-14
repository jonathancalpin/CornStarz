import SwiftUI
import RealityKit
import ARKit

struct ARGameView: UIViewRepresentable {
    let arSessionManager: ARSessionManager
    var onTap: ((CGPoint) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: onTap)
    }

    func makeUIView(context: Context) -> ARView {
        arSessionManager.configure()
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arSessionManager.arView.addGestureRecognizer(tapGesture)
        return arSessionManager.arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.onTap = onTap
    }

    class Coordinator: NSObject {
        var onTap: ((CGPoint) -> Void)?

        init(onTap: ((CGPoint) -> Void)?) {
            self.onTap = onTap
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            let location = gesture.location(in: gesture.view)
            onTap?(location)
        }
    }
}
