import RealityKit
import UIKit

class CornholeBoardEntity: Entity, HasModel, HasPhysicsBody, HasCollision {

    required init() {
        super.init()

        // Regulation: 2ft x 4ft = 0.61m x 1.22m, 3/4 inch thick = 0.019m
        let boardMesh = MeshResource.generateBox(size: [0.61, 0.019, 1.22])
        let boardMaterial = SimpleMaterial(
            color: UIColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0),
            isMetallic: false
        )
        self.model = ModelComponent(mesh: boardMesh, materials: [boardMaterial])

        // Regulation angle: front edge 4" (0.10m), back edge 12" (0.30m)
        // Rise = 0.20m over 1.22m length = ~9.4°
        self.transform.rotation = simd_quatf(angle: -0.164, axis: SIMD3<Float>(1, 0, 0))

        // Position so front edge sits at ground level
        // With the board centered and rotated, raise to compensate
        self.position.y = 0.20

        // Hole: 6" diameter (0.152m), centered 9" (0.229m) from the top edge
        // Top edge is at z = -0.61 (half of 1.22), hole center at z = -0.61 + 0.229 = -0.381
        let holeMesh = MeshResource.generateCylinder(height: 0.03, radius: 0.076)
        let holeMaterial = SimpleMaterial(
            color: UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1.0),
            isMetallic: false
        )
        let holeEntity = ModelEntity(mesh: holeMesh, materials: [holeMaterial])
        holeEntity.position = SIMD3<Float>(0, 0.01, -0.381)
        self.addChild(holeEntity)

        // White ring around the hole for visibility
        let ringMesh = MeshResource.generateCylinder(height: 0.005, radius: 0.085)
        let ringMaterial = SimpleMaterial(color: .white, isMetallic: false)
        let ringEntity = ModelEntity(mesh: ringMesh, materials: [ringMaterial])
        ringEntity.position = SIMD3<Float>(0, 0.011, -0.381)
        self.addChild(ringEntity)

        // Board legs (front and back)
        let frontLeg = ModelEntity(
            mesh: MeshResource.generateBox(size: [0.61, 0.10, 0.03]),
            materials: [SimpleMaterial(color: UIColor(red: 0.6, green: 0.08, blue: 0.08, alpha: 1.0), isMetallic: false)]
        )
        frontLeg.position = SIMD3<Float>(0, -0.01, 0.59)
        self.addChild(frontLeg)

        let backLeg = ModelEntity(
            mesh: MeshResource.generateBox(size: [0.61, 0.30, 0.03]),
            materials: [SimpleMaterial(color: UIColor(red: 0.6, green: 0.08, blue: 0.08, alpha: 1.0), isMetallic: false)]
        )
        backLeg.position = SIMD3<Float>(0, -0.01, -0.59)
        self.addChild(backLeg)

        let shape = ShapeResource.generateBox(size: [0.61, 0.019, 1.22])
        self.physicsBody = PhysicsBodyComponent(
            shapes: [shape],
            mass: 0,
            mode: .static
        )
        self.collision = CollisionComponent(shapes: [shape])
    }
}
