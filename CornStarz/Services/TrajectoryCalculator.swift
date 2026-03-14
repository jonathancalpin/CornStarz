import simd

struct TrajectoryPoint {
    let position: SIMD2<Double>
    let time: Double
    let velocity: SIMD2<Double>
}

class TrajectoryCalculator {

    struct Config {
        var gravity: Double = 9.81
        var dragCoefficient: Double = 0.05
        var timeStep: Double = 0.016
        var maxFlightTime: Double = 3.0
    }

    var config = Config()

    func calculateTrajectory(
        release: ReleaseVector,
        releaseHeight: Double = 1.5,
        targetDistance: Double = 12.0
    ) -> [TrajectoryPoint] {

        var points: [TrajectoryPoint] = []
        var position = SIMD2<Double>(0, releaseHeight)
        var velocity = release.velocity
        var time: Double = 0

        while time < config.maxFlightTime {
            points.append(TrajectoryPoint(
                position: position,
                time: time,
                velocity: velocity
            ))

            let speed = simd_length(velocity)
            let dragForce = config.dragCoefficient * speed * speed
            let dragDirection = simd_normalize(velocity)

            let acceleration = SIMD2<Double>(
                -dragForce * dragDirection.x,
                -config.gravity - dragForce * dragDirection.y
            )

            velocity += acceleration * config.timeStep
            position += velocity * config.timeStep
            time += config.timeStep

            if position.y <= 0 {
                points.append(TrajectoryPoint(
                    position: SIMD2<Double>(position.x, 0),
                    time: time,
                    velocity: velocity
                ))
                break
            }
        }

        return points
    }

    func landingDistance(from trajectory: [TrajectoryPoint]) -> Double {
        return trajectory.last?.position.x ?? 0
    }
}
