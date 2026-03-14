import RealityKit

class ProjectileEntity: Entity, HasModel, HasPhysicsBody, HasCollision {

    required init() {
        super.init()
    }

    convenience init(gameMode: GameMode) {
        self.init()

        switch gameMode {
        case .horseshoe:
            let mesh = MeshResource.generateBox(size: [0.15, 0.02, 0.18])
            let material = SimpleMaterial(color: .gray, isMetallic: true)
            self.model = ModelComponent(mesh: mesh, materials: [material])

            let shape = ShapeResource.generateBox(size: [0.15, 0.02, 0.18])
            self.physicsBody = PhysicsBodyComponent(
                shapes: [shape],
                mass: 1.13,
                material: .generate(
                    staticFriction: 0.6,
                    dynamicFriction: 0.4,
                    restitution: 0.3
                ),
                mode: .dynamic
            )
            self.collision = CollisionComponent(shapes: [shape])

        case .cornhole:
            let mesh = MeshResource.generateBox(size: [0.15, 0.05, 0.15])
            let material = SimpleMaterial(color: .blue, isMetallic: false)
            self.model = ModelComponent(mesh: mesh, materials: [material])

            let shape = ShapeResource.generateBox(size: [0.15, 0.05, 0.15])
            self.physicsBody = PhysicsBodyComponent(
                shapes: [shape],
                mass: 0.45,
                material: .generate(
                    staticFriction: 0.8,
                    dynamicFriction: 0.6,
                    restitution: 0.05
                ),
                mode: .dynamic
            )
            self.collision = CollisionComponent(shapes: [shape])
        }
    }
}
