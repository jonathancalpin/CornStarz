import Foundation
import CoreMotion
import CoreTransferable
import UniformTypeIdentifiers

struct ExportableMotionSample: Codable, Identifiable {
    let id: Int
    let timestamp: TimeInterval
    let accelerationX: Double
    let accelerationY: Double
    let accelerationZ: Double
    let rotationRateX: Double
    let rotationRateY: Double
    let rotationRateZ: Double
    let pitch: Double
    let roll: Double
    let yaw: Double

    var accelerationMagnitude: Double {
        sqrt(accelerationX * accelerationX + accelerationY * accelerationY + accelerationZ * accelerationZ)
    }
}

struct ThrowLabel: Codable {
    let intensity: String    // soft, medium, hard
    let direction: String    // straight, left, right
    let spin: String         // none, topspin, sidespin
    let throwNumber: Int
}

struct ThrowAnalysisResult: Codable {
    let peakAccelerationMagnitude: Double
    let estimatedReleaseAngleDegrees: Double
    let estimatedSpeed: Double
    let releaseIndex: Int
}

struct ExportableThrowData: Codable {
    let startTime: Date
    let endTime: Date
    let sampleRate: Double
    let samples: [ExportableMotionSample]
    let analysis: ThrowAnalysisResult?
    var label: ThrowLabel?

    init(from motionData: [CMDeviceMotion], analysis: ReleaseVector?, startTime: Date, endTime: Date, label: ThrowLabel? = nil) {
        self.startTime = startTime
        self.endTime = endTime
        self.sampleRate = 100.0

        let baseTimestamp = motionData.first?.timestamp ?? 0
        self.samples = motionData.enumerated().map { index, motion in
            ExportableMotionSample(
                id: index,
                timestamp: motion.timestamp - baseTimestamp,
                accelerationX: motion.userAcceleration.x,
                accelerationY: motion.userAcceleration.y,
                accelerationZ: motion.userAcceleration.z,
                rotationRateX: motion.rotationRate.x,
                rotationRateY: motion.rotationRate.y,
                rotationRateZ: motion.rotationRate.z,
                pitch: motion.attitude.pitch,
                roll: motion.attitude.roll,
                yaw: motion.attitude.yaw
            )
        }

        self.label = label

        if let release = analysis {
            let peakMag = motionData.map { m in
                sqrt(m.userAcceleration.x * m.userAcceleration.x +
                     m.userAcceleration.y * m.userAcceleration.y +
                     m.userAcceleration.z * m.userAcceleration.z)
            }.max() ?? 0

            let accelerations = motionData.map { m in
                sqrt(m.userAcceleration.x * m.userAcceleration.x +
                     m.userAcceleration.y * m.userAcceleration.y +
                     m.userAcceleration.z * m.userAcceleration.z)
            }
            let peakIndex = accelerations.indices.max(by: { accelerations[$0] < accelerations[$1] }) ?? 0

            self.analysis = ThrowAnalysisResult(
                peakAccelerationMagnitude: peakMag,
                estimatedReleaseAngleDegrees: release.angle * 180.0 / .pi,
                estimatedSpeed: release.speed,
                releaseIndex: peakIndex
            )
        } else {
            self.analysis = nil
        }
    }
}

extension ExportableThrowData: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .json) { throwData in
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            return try encoder.encode(throwData)
        }
    }
}

struct ThrowSession: Codable, Transferable {
    let sessionDate: Date
    let recordings: [ExportableThrowData]

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .json) { session in
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            return try encoder.encode(session)
        }
    }
}
