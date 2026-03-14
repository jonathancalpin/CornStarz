import CoreMotion
import simd

struct ReleaseVector {
    let speed: Double
    let angle: Double
    let spin: Double
    let lateralOffset: Double

    var velocity: SIMD2<Double> {
        SIMD2<Double>(
            speed * cos(angle),
            speed * sin(angle)
        )
    }
}

class ThrowAnalyzer {

    struct Config {
        var speedScaleFactor: Double = 2.5
        var angleOffsetDegrees: Double = 0.0
        var minThrowAcceleration: Double = 1.5
        var releaseDetectionThreshold: Double = 0.3
        var spinScaleFactor: Double = 1.0
    }

    var config = Config()

    func analyze(motionData: [CMDeviceMotion]) -> ReleaseVector? {
        guard motionData.count > 10 else { return nil }

        let accelerations = motionData.map { m in
            sqrt(
                m.userAcceleration.x * m.userAcceleration.x +
                m.userAcceleration.y * m.userAcceleration.y +
                m.userAcceleration.z * m.userAcceleration.z
            )
        }

        guard let peakIndex = accelerations.indices.max(by: { accelerations[$0] < accelerations[$1] }) else {
            return nil
        }

        let peakAcceleration = accelerations[peakIndex]
        guard peakAcceleration > config.minThrowAcceleration else { return nil }

        var releaseIndex = peakIndex
        for i in peakIndex..<motionData.count - 1 {
            let decelRate = accelerations[i] - accelerations[i + 1]
            if decelRate > config.releaseDetectionThreshold {
                releaseIndex = i
                break
            }
        }

        let releaseMotion = motionData[releaseIndex]

        let speed = peakAcceleration * config.speedScaleFactor
        let angle = releaseMotion.attitude.pitch + (config.angleOffsetDegrees * .pi / 180.0)
        let spin = releaseMotion.rotationRate.x * config.spinScaleFactor
        let lateralOffset = releaseMotion.rotationRate.y * 0.1

        return ReleaseVector(
            speed: speed,
            angle: angle,
            spin: spin,
            lateralOffset: lateralOffset
        )
    }
}
