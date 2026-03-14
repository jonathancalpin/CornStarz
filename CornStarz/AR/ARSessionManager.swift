import ARKit
import RealityKit
import Combine

class ARSessionManager: NSObject, ObservableObject {
    let arView = ARView(frame: .zero)

    @Published var planesDetected: Int = 0
    @Published var isTargetPlaced = false
    @Published var targetDistance: Float = 0

    private var planeAnchors: [ARPlaneAnchor] = []
    private var cancellables = Set<AnyCancellable>()

    func configure() {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic

        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }

        arView.session.run(config)
        arView.session.delegate = self

        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.session = arView.session
        coachingOverlay.goal = .horizontalPlane
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        arView.addSubview(coachingOverlay)
    }

    func placeTarget(at worldPosition: SIMD3<Float>, gameMode: GameMode) {
        let anchor = AnchorEntity(world: worldPosition)

        switch gameMode {
        case .horseshoe:
            let pit = HorseshoePitEntity()
            anchor.addChild(pit)
        case .cornhole:
            let board = CornholeBoardEntity()
            anchor.addChild(board)
        }

        arView.scene.addAnchor(anchor)

        if let cameraTransform = arView.session.currentFrame?.camera.transform {
            let cameraPos = SIMD3<Float>(
                cameraTransform.columns.3.x,
                cameraTransform.columns.3.y,
                cameraTransform.columns.3.z
            )
            targetDistance = distance(cameraPos, worldPosition)
        }

        isTargetPlaced = true
    }

    func launchProjectile(release: ReleaseVector, gameMode: GameMode) {
        guard let frame = arView.session.currentFrame else { return }

        let cameraTransform = frame.camera.transform
        let cameraPosition = SIMD3<Float>(
            cameraTransform.columns.3.x,
            cameraTransform.columns.3.y,
            cameraTransform.columns.3.z
        )

        let forward = SIMD3<Float>(
            -cameraTransform.columns.2.x,
            -cameraTransform.columns.2.y,
            -cameraTransform.columns.2.z
        )

        let projectile = ProjectileEntity(gameMode: gameMode)
        let anchor = AnchorEntity(world: cameraPosition)
        anchor.addChild(projectile)
        arView.scene.addAnchor(anchor)

        let speed = Float(release.speed)
        let angle = Float(release.angle)
        let lateral = Float(release.lateralOffset)

        let up = SIMD3<Float>(0, 1, 0)
        let right = simd_normalize(simd_cross(forward, up))

        let impulseDirection = simd_normalize(
            forward * cos(angle) +
            up * sin(angle) +
            right * lateral
        )

        let impulse = impulseDirection * speed

        projectile.physicsBody?.mode = .dynamic
        projectile.addForce(impulse, relativeTo: nil)

        let spinTorque = SIMD3<Float>(Float(release.spin), 0, 0)
        projectile.addTorque(spinTorque, relativeTo: nil)
    }
}

extension ARSessionManager: ARSessionDelegate {
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        let newPlanes = anchors.compactMap { $0 as? ARPlaneAnchor }
        planeAnchors.append(contentsOf: newPlanes)
        planesDetected = planeAnchors.count
    }
}
