import CoreMotion
import Combine
import simd

class MotionCaptureService: ObservableObject {
    private let motionManager = CMMotionManager()
    private var motionDataBuffer: [CMDeviceMotion] = []

    @Published var isCapturing = false
    @Published var currentAcceleration: SIMD3<Double> = .zero
    @Published var currentRotationRate: SIMD3<Double> = .zero
    @Published var currentAttitude: (roll: Double, pitch: Double, yaw: Double) = (0, 0, 0)

    let updateInterval: TimeInterval = 1.0 / 100.0  // 100 Hz

    func startCapture() {
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion not available")
            return
        }

        motionDataBuffer.removeAll()
        motionManager.deviceMotionUpdateInterval = updateInterval

        motionManager.startDeviceMotionUpdates(
            using: .xArbitraryZVertical,
            to: .main
        ) { [weak self] motion, error in
            guard let self = self, let motion = motion else { return }

            self.motionDataBuffer.append(motion)

            self.currentAcceleration = SIMD3<Double>(
                motion.userAcceleration.x,
                motion.userAcceleration.y,
                motion.userAcceleration.z
            )

            self.currentRotationRate = SIMD3<Double>(
                motion.rotationRate.x,
                motion.rotationRate.y,
                motion.rotationRate.z
            )

            self.currentAttitude = (
                roll: motion.attitude.roll,
                pitch: motion.attitude.pitch,
                yaw: motion.attitude.yaw
            )
        }

        isCapturing = true
    }

    func stopCapture() -> [CMDeviceMotion] {
        motionManager.stopDeviceMotionUpdates()
        isCapturing = false
        return motionDataBuffer
    }

    var accelerationMagnitude: Double {
        simd_length(currentAcceleration)
    }
}
