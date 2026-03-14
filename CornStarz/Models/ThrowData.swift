import Foundation
import CoreMotion

/// Raw captured motion data for a single throw gesture
struct ThrowData {
    let motionSamples: [CMDeviceMotion]
    let startTime: Date
    let endTime: Date
    let releaseIndex: Int?

    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }

    var sampleCount: Int {
        motionSamples.count
    }
}
