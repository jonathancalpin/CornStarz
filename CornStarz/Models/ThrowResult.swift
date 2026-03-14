import Foundation
import simd

/// Computed result of a throw after physics simulation
struct ThrowResult {
    let releaseVector: ReleaseVector
    let landingPosition: SIMD3<Float>
    let distanceFromTarget: Float
    let score: Int
    let flightTime: TimeInterval
}
