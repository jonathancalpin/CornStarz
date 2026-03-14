import SpriteKit

class TrajectorySceneView: SKScene {

    // Meters to points conversion
    private var scale: CGFloat = 40.0
    private let releaseHeight: CGFloat = 1.5
    private let groundHeight: CGFloat = 40.0

    private var targetNode: SKShapeNode?
    private var targetLabel: SKLabelNode?
    private var attemptNodes: [[SKNode]] = []

    private var currentTargetDistance: Double = 12.0

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(white: 0.1, alpha: 1.0)
        anchorPoint = CGPoint(x: 0.05, y: 0)

        // Calculate scale to fit target distance + margin in view
        updateScale()
        drawStaticElements()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard size.width > 0 else { return }
        removeAllChildren()
        attemptNodes.removeAll()
        updateScale()
        drawStaticElements()
    }

    private func updateScale() {
        let viewableMeters = currentTargetDistance + 4.0
        scale = (size.width * 0.9) / CGFloat(viewableMeters)
    }

    private func drawStaticElements() {
        drawGround()
        drawDistanceMarkers()
        drawTarget(at: currentTargetDistance)
        drawReleasePoint()
    }

    private func drawGround() {
        let ground = SKShapeNode(rect: CGRect(x: -20, y: 0, width: size.width + 40, height: groundHeight))
        ground.fillColor = UIColor(red: 0.15, green: 0.3, blue: 0.15, alpha: 1.0)
        ground.strokeColor = UIColor(red: 0.2, green: 0.5, blue: 0.2, alpha: 1.0)
        ground.lineWidth = 2
        ground.name = "ground"
        addChild(ground)
    }

    private func drawDistanceMarkers() {
        let maxDist = Int(currentTargetDistance + 4)
        for meter in stride(from: 2, through: maxDist, by: 2) {
            let x = CGFloat(meter) * scale
            let marker = SKShapeNode(rect: CGRect(x: x - 0.5, y: groundHeight, width: 1, height: 10))
            marker.fillColor = .gray
            marker.strokeColor = .clear
            marker.name = "marker"
            addChild(marker)

            let label = SKLabelNode(text: "\(meter)m")
            label.fontSize = 10
            label.fontColor = .gray
            label.fontName = "Menlo"
            label.position = CGPoint(x: x, y: groundHeight + 14)
            label.name = "marker"
            addChild(label)
        }
    }

    private func drawTarget(at distance: Double) {
        targetNode?.removeFromParent()
        targetLabel?.removeFromParent()

        let x = CGFloat(distance) * scale

        let target = SKShapeNode(rect: CGRect(x: x - 2, y: groundHeight, width: 4, height: 30))
        target.fillColor = .red
        target.strokeColor = .red
        target.name = "target"
        addChild(target)
        targetNode = target

        let label = SKLabelNode(text: String(format: "%.1fm", distance))
        label.fontSize = 12
        label.fontColor = .red
        label.fontName = "Menlo-Bold"
        label.position = CGPoint(x: x, y: groundHeight + 36)
        label.name = "target"
        addChild(label)
        targetLabel = label
    }

    private func drawReleasePoint() {
        let y = groundHeight + CGFloat(releaseHeight) * scale
        let circle = SKShapeNode(circleOfRadius: 4)
        circle.position = CGPoint(x: 0, y: y)
        circle.fillColor = .white
        circle.strokeColor = .white
        circle.name = "releasePoint"
        addChild(circle)
    }

    // MARK: - Public API

    func addThrowAttempt(_ attempt: ThrowAttempt) {
        let points = attempt.trajectoryPoints
        guard points.count > 1 else { return }

        var nodes: [SKNode] = []
        let color = UIColor(attempt.color)

        // Draw trajectory arc
        let path = CGMutablePath()
        let firstPt = scenePoint(from: points[0].position)
        path.move(to: firstPt)

        for i in 1..<points.count {
            let pt = scenePoint(from: points[i].position)
            path.addLine(to: pt)
        }

        let trail = SKShapeNode(path: path)
        trail.strokeColor = color
        trail.lineWidth = 2
        trail.glowWidth = 1
        trail.name = "trail"
        addChild(trail)
        nodes.append(trail)

        // Animate projectile along the path
        let projectile = SKShapeNode(circleOfRadius: 5)
        projectile.fillColor = color
        projectile.strokeColor = .white
        projectile.lineWidth = 1
        projectile.position = firstPt
        projectile.name = "projectile"
        addChild(projectile)
        nodes.append(projectile)

        // Build animation from trajectory points
        var actions: [SKAction] = []
        for i in 1..<points.count {
            let pt = scenePoint(from: points[i].position)
            let dt = points[i].time - points[i - 1].time
            actions.append(SKAction.move(to: pt, duration: dt))
        }

        let sequence = SKAction.sequence(actions)
        projectile.run(sequence) { [weak self] in
            // Landing indicator
            guard let self = self else { return }
            let landingPt = self.scenePoint(from: points.last!.position)

            let diamond = SKShapeNode(circleOfRadius: 6)
            diamond.position = landingPt
            diamond.fillColor = self.landingColor(distanceFromTarget: attempt.distanceFromTarget)
            diamond.strokeColor = .white
            diamond.lineWidth = 1
            diamond.name = "landing"
            self.addChild(diamond)
            nodes.append(diamond)

            let distLabel = SKLabelNode(text: String(format: "%+.1fm", attempt.distanceFromTarget))
            distLabel.fontSize = 11
            distLabel.fontColor = .white
            distLabel.fontName = "Menlo-Bold"
            distLabel.position = CGPoint(x: landingPt.x, y: landingPt.y + 12)
            distLabel.name = "landing"
            self.addChild(distLabel)
            nodes.append(distLabel)

            // Fade the projectile circle
            projectile.run(SKAction.fadeAlpha(to: 0.3, duration: 0.5))
        }

        attemptNodes.append(nodes)

        // Limit visible attempts
        if attemptNodes.count > 8 {
            let old = attemptNodes.removeFirst()
            old.forEach { $0.removeFromParent() }
        }
    }

    func updateTargetDistance(_ distance: Double) {
        currentTargetDistance = distance
        updateScale()

        // Redraw everything
        removeAllChildren()
        attemptNodes.removeAll()
        drawStaticElements()
    }

    func clearAllAttempts() {
        for group in attemptNodes {
            group.forEach { $0.removeFromParent() }
        }
        attemptNodes.removeAll()
    }

    // MARK: - Coordinate conversion

    private func scenePoint(from position: SIMD2<Double>) -> CGPoint {
        CGPoint(
            x: CGFloat(position.x) * scale,
            y: groundHeight + CGFloat(position.y) * scale
        )
    }

    private func landingColor(distanceFromTarget: Double) -> UIColor {
        let absDistance = abs(distanceFromTarget)
        if absDistance < 0.5 { return .green }
        if absDistance < 1.5 { return .yellow }
        return .red
    }
}
