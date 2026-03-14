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
    private var targetWorldPosition: SIMD3<Float>?
    private var distanceTimer: Timer?

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

    /// Auto-place target at a given distance in front of the camera on a detected plane
    func placeTargetAtDistance(_ meters: Float, gameMode: GameMode) {
        guard let frame = arView.session.currentFrame else { return }

        let cameraTransform = frame.camera.transform
        let cameraPos = SIMD3<Float>(
            cameraTransform.columns.3.x,
            cameraTransform.columns.3.y,
            cameraTransform.columns.3.z
        )

        // Forward direction (horizontal only, ignore camera tilt)
        let rawForward = SIMD3<Float>(
            -cameraTransform.columns.2.x,
            0,
            -cameraTransform.columns.2.z
        )
        let forward = simd_normalize(rawForward)

        // Place target at distance in front, at the camera's Y level (ground estimate)
        // Use the lowest detected plane Y if available, otherwise camera Y - 1.2m (rough floor)
        let floorY: Float
        if let lowestPlane = planeAnchors.min(by: { $0.transform.columns.3.y < $1.transform.columns.3.y }) {
            floorY = lowestPlane.transform.columns.3.y
        } else {
            floorY = cameraPos.y - 1.2
        }

        let targetPos = SIMD3<Float>(
            cameraPos.x + forward.x * meters,
            floorY,
            cameraPos.z + forward.z * meters
        )

        placeTarget(at: targetPos, gameMode: gameMode)
    }

    func placeTarget(at worldPosition: SIMD3<Float>, gameMode: GameMode) {
        let anchor = AnchorEntity(world: worldPosition)

        // Orient board to face the camera
        if let cameraTransform = arView.session.currentFrame?.camera.transform {
            let cameraPos = SIMD3<Float>(
                cameraTransform.columns.3.x,
                0,
                cameraTransform.columns.3.z
            )
            let targetPos2D = SIMD3<Float>(worldPosition.x, 0, worldPosition.z)
            let dir = simd_normalize(cameraPos - targetPos2D)
            let yaw = atan2(dir.x, dir.z)
            anchor.transform.rotation = simd_quatf(angle: yaw, axis: SIMD3<Float>(0, 1, 0))
        }

        switch gameMode {
        case .horseshoe:
            let pit = HorseshoePitEntity()
            anchor.addChild(pit)
        case .cornhole:
            let board = CornholeBoardEntity()
            anchor.addChild(board)
        }

        arView.scene.addAnchor(anchor)

        // Add invisible ground plane for physics collisions
        let floorAnchor = AnchorEntity(world: SIMD3<Float>(worldPosition.x, worldPosition.y, worldPosition.z))
        let floorMesh = MeshResource.generatePlane(width: 20, depth: 20)
        let floorEntity = ModelEntity(mesh: floorMesh, materials: [OcclusionMaterial()])
        floorEntity.generateCollisionShapes(recursive: false)
        floorEntity.physicsBody = PhysicsBodyComponent(
            shapes: [.generateBox(size: [20, 0.01, 20])],
            mass: 0,
            mode: .static
        )
        floorAnchor.addChild(floorEntity)
        arView.scene.addAnchor(floorAnchor)

        targetWorldPosition = worldPosition
        updateDistance()
        startDistanceUpdates()

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

        // Scale impulse for RealityKit physics (needs tuning vs 2D calculator)
        let impulseScale: Float = 0.4
        let speed = Float(release.speed) * impulseScale
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
        projectile.applyLinearImpulse(impulse, relativeTo: nil)

        let spinTorque = SIMD3<Float>(Float(release.spin) * 0.1, 0, 0)
        projectile.applyAngularImpulse(spinTorque, relativeTo: nil)

        // Clean up projectile after 6 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) { [weak self] in
            self?.arView.scene.removeAnchor(anchor)
        }
    }

    // MARK: - Distance Updates

    private func startDistanceUpdates() {
        distanceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.updateDistance()
        }
    }

    private func updateDistance() {
        guard let targetPos = targetWorldPosition,
              let cameraTransform = arView.session.currentFrame?.camera.transform else { return }

        let cameraPos = SIMD3<Float>(
            cameraTransform.columns.3.x,
            cameraTransform.columns.3.y,
            cameraTransform.columns.3.z
        )
        targetDistance = distance(cameraPos, targetPos)
    }
}

extension ARSessionManager: ARSessionDelegate {
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        let newPlanes = anchors.compactMap { $0 as? ARPlaneAnchor }
        planeAnchors.append(contentsOf: newPlanes)
        planesDetected = planeAnchors.count
    }
}
