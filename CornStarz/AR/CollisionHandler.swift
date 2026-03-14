import RealityKit
import Combine

class CollisionHandler {
    private var cancellables = Set<AnyCancellable>()

    func observeCollisions(in scene: Scene, onScore: @escaping (Int) -> Void) {
        scene.subscribe(to: CollisionEvents.Began.self) { event in
            // Determine scoring based on what the projectile collided with
            let entityA = event.entityA
            let entityB = event.entityB

            if entityA is ProjectileEntity || entityB is ProjectileEntity {
                let target = entityA is ProjectileEntity ? entityB : entityA

                if target is CornholeBoardEntity {
                    onScore(CornholeScore.onTheBoard.rawValue)
                } else if target is HorseshoePitEntity {
                    onScore(HorseshoeScore.closeShoe.rawValue)
                } else {
                    onScore(0)
                }
            }
        }
        .store(in: &cancellables)
    }
}
