import RealityKit

class CornholeBoardEntity: Entity, HasModel, HasPhysicsBody, HasCollision {

    required init() {
        super.init()

        // Board surface (regulation: 2ft x 4ft = 0.61m x 1.22m)
        let boardMesh = MeshResource.generateBox(size: [0.61, 0.02, 1.22])
        let boardMaterial = SimpleMaterial(color: .init(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0), isMetallic: false)
        self.model = ModelComponent(mesh: boardMesh, materials: [boardMaterial])

        // Angle the board (regulation: front edge ~4 inches, back ~12 inches)
        self.transform.rotation = simd_quatf(angle: -.pi / 12, axis: SIMD3<Float>(1, 0, 0))

        let shape = ShapeResource.generateBox(size: [0.61, 0.02, 1.22])
        self.physicsBody = PhysicsBodyComponent(
            shapes: [shape],
            mass: 0,
            mode: .static
        )
        self.collision = CollisionComponent(shapes: [shape])
    }
}
