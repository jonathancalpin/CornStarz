import SwiftUI
import Combine
import simd

struct ThrowAttempt: Identifiable {
    let id = UUID()
    let releaseVector: ReleaseVector
    let trajectoryPoints: [TrajectoryPoint]
    let landingDistance: Double
    let distanceFromTarget: Double
    let colorIndex: Int

    var color: Color {
        let palette: [Color] = [.cyan, .orange, .green, .pink, .yellow, .mint, .purple, .red]
        return palette[colorIndex % palette.count]
    }
}

class TrajectoryViewModel: ObservableObject {
    // Tuning parameters (bound to sliders)
    @Published var speedScaleFactor: Double = 2.2 {
        didSet { throwAnalyzer.config.speedScaleFactor = speedScaleFactor }
    }
    @Published var angleOffsetDegrees: Double = -20.0 {
        didSet { throwAnalyzer.config.angleOffsetDegrees = angleOffsetDegrees }
    }
    @Published var dragCoefficient: Double = 0.05 {
        didSet { trajectoryCalculator.config.dragCoefficient = dragCoefficient }
    }
    @Published var targetDistance: Double = 12.0

    // State
    @Published var attempts: [ThrowAttempt] = []
    @Published var isReady = false
    @Published var isRecording = false
    @Published var consoleLog = "Tap Start to begin."

    // Callback for scene updates
    var onNewThrow: ((ThrowAttempt) -> Void)?

    private let motionService = MotionCaptureService()
    private let throwAnalyzer = ThrowAnalyzer()
    private let trajectoryCalculator = TrajectoryCalculator()
    private var recordingTimer: Timer?
    private var throwCount = 0

    func startListening() {
        motionService.startCapture()
        isReady = true
        consoleLog = "Ready — swing phone, then tap Record."
    }

    func stopListening() {
        _ = motionService.stopCapture()
        isReady = false
        isRecording = false
        recordingTimer?.invalidate()
    }

    func recordThrow() {
        guard isReady, !isRecording else { return }

        // Restart for clean buffer
        _ = motionService.stopCapture()
        motionService.startCapture()

        isRecording = true
        consoleLog = "Recording... throw now!"

        recordingTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            self?.finishRecording()
        }
    }

    private func finishRecording() {
        recordingTimer?.invalidate()
        recordingTimer = nil

        let motionData = motionService.stopCapture()
        isRecording = false

        guard let release = throwAnalyzer.analyze(motionData: motionData) else {
            consoleLog = "No throw detected. Swing harder."
            motionService.startCapture()
            return
        }

        let trajectory = trajectoryCalculator.calculateTrajectory(
            release: release,
            targetDistance: targetDistance
        )

        let landing = trajectoryCalculator.landingDistance(from: trajectory)
        let distFromTarget = landing - targetDistance

        throwCount += 1
        let attempt = ThrowAttempt(
            releaseVector: release,
            trajectoryPoints: trajectory,
            landingDistance: landing,
            distanceFromTarget: distFromTarget,
            colorIndex: throwCount - 1
        )

        attempts.append(attempt)
        if attempts.count > 8 {
            attempts.removeFirst()
        }

        consoleLog = String(format: "Speed: %.1f m/s | Angle: %.0f° | Landed: %.1fm | Target: %+.1fm",
                            release.speed,
                            release.angle * 180.0 / .pi,
                            landing,
                            distFromTarget)

        onNewThrow?(attempt)

        // Resume capture for next throw
        motionService.startCapture()
    }

    func clearAttempts() {
        attempts.removeAll()
        throwCount = 0
        consoleLog = "Cleared. Ready for next throw."
    }
}
