import RealityKit

class HorseshoePitEntity: Entity, HasModel, HasCollision {

    required init() {
        super.init()

        // Placeholder: ground pit area
        let pitMesh = MeshResource.generatePlane(width: 0.9, depth: 1.2)
        let pitMaterial = SimpleMaterial(color: .brown, isMetallic: false)
        self.model = ModelComponent(mesh: pitMesh, materials: [pitMaterial])

        // Stake in the center
        let stake = ModelEntity(
            mesh: MeshResource.generateCylinder(height: 0.35, radius: 0.015),
            materials: [SimpleMaterial(color: .gray, isMetallic: true)]
        )
        stake.position = SIMD3<Float>(0, 0.175, 0)
        self.addChild(stake)

        let shape = ShapeResource.generateBox(size: [0.9, 0.01, 1.2])
        self.collision = CollisionComponent(shapes: [shape])
    }
}
