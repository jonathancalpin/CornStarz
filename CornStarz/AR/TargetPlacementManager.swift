import ARKit
import RealityKit

class TargetPlacementManager: ObservableObject {
    @Published var placementState: PlacementState = .scanning

    enum PlacementState {
        case scanning
        case readyToPlace
        case placed
    }

    func handleTap(at point: CGPoint, in arView: ARView, gameMode: GameMode, sessionManager: ARSessionManager) {
        let results = arView.raycast(from: point, allowing: .existingPlaneGeometry, alignment: .horizontal)

        guard let firstResult = results.first else { return }

        let worldPosition = SIMD3<Float>(
            firstResult.worldTransform.columns.3.x,
            firstResult.worldTransform.columns.3.y,
            firstResult.worldTransform.columns.3.z
        )

        sessionManager.placeTarget(at: worldPosition, gameMode: gameMode)
        placementState = .placed
    }
}
