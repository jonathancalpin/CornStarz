import SwiftUI
import Combine
import simd

struct MotionSample: Identifiable {
    let id: Int
    let timestamp: Double
    let axis: String
    let value: Double
}

class MotionViewModel: ObservableObject {
    @Published var accelerationX: Double = 0
    @Published var accelerationY: Double = 0
    @Published var accelerationZ: Double = 0
    @Published var magnitude: Double = 0
    @Published var rotationX: Double = 0
    @Published var rotationY: Double = 0
    @Published var rotationZ: Double = 0

    // Chart history (rolling window)
    @Published var accelerationHistory: [MotionSample] = []
    @Published var rotationHistory: [MotionSample] = []

    // Recording state
    @Published var isMonitoring = false
    @Published var isRecording = false
    @Published var recordedThrowData: ExportableThrowData?
    @Published var consoleLog: String = "Ready. Tap Start Monitoring to begin."

    // Throw labeling
    @Published var selectedIntensity: String = "medium"
    @Published var selectedDirection: String = "straight"
    @Published var selectedSpin: String = "none"

    // Session log
    @Published var sessionThrows: [ExportableThrowData] = []
    private var throwCounter = 0

    let motionService: MotionCaptureService
    private let throwAnalyzer = ThrowAnalyzer()
    private var cancellables = Set<AnyCancellable>()
    private var sampleIndex = 0
    private var recordingStartTime: Date?
    private var recordingTimer: Timer?

    // Keep ~2 seconds at 20Hz display rate (3 axes x 40 samples)
    private let maxSamplesPerAxis = 40
    private var displayCounter = 0

    init(motionService: MotionCaptureService = MotionCaptureService()) {
        self.motionService = motionService

        motionService.$currentAcceleration
            .receive(on: DispatchQueue.main)
            .sink { [weak self] accel in
                guard let self = self else { return }
                self.accelerationX = accel.x
                self.accelerationY = accel.y
                self.accelerationZ = accel.z
                self.magnitude = simd_length(accel)

                // Downsample to ~20Hz for chart display (every 5th sample)
                self.displayCounter += 1
                guard self.displayCounter % 5 == 0 else { return }

                let t = Double(self.sampleIndex)
                self.sampleIndex += 1
                self.accelerationHistory.append(contentsOf: [
                    MotionSample(id: self.sampleIndex * 3, timestamp: t, axis: "X", value: accel.x),
                    MotionSample(id: self.sampleIndex * 3 + 1, timestamp: t, axis: "Y", value: accel.y),
                    MotionSample(id: self.sampleIndex * 3 + 2, timestamp: t, axis: "Z", value: accel.z),
                ])

                let maxTotal = self.maxSamplesPerAxis * 3
                if self.accelerationHistory.count > maxTotal {
                    self.accelerationHistory.removeFirst(3)
                }
            }
            .store(in: &cancellables)

        motionService.$currentRotationRate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rot in
                guard let self = self else { return }
                self.rotationX = rot.x
                self.rotationY = rot.y
                self.rotationZ = rot.z

                guard self.displayCounter % 5 == 0 else { return }

                let t = Double(self.sampleIndex)
                self.rotationHistory.append(contentsOf: [
                    MotionSample(id: self.sampleIndex * 3 + 10000, timestamp: t, axis: "X", value: rot.x),
                    MotionSample(id: self.sampleIndex * 3 + 10001, timestamp: t, axis: "Y", value: rot.y),
                    MotionSample(id: self.sampleIndex * 3 + 10002, timestamp: t, axis: "Z", value: rot.z),
                ])

                let maxTotal = self.maxSamplesPerAxis * 3
                if self.rotationHistory.count > maxTotal {
                    self.rotationHistory.removeFirst(3)
                }
            }
            .store(in: &cancellables)
    }

    func startMonitoring() {
        sampleIndex = 0
        displayCounter = 0
        accelerationHistory.removeAll()
        rotationHistory.removeAll()
        motionService.startCapture()
        isMonitoring = true
        consoleLog = "Monitoring... Swing phone to see data."
    }

    func stopMonitoring() {
        _ = motionService.stopCapture()
        isMonitoring = false
        isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil
        consoleLog = "Monitoring stopped."
    }

    func startRecording() {
        guard isMonitoring else {
            consoleLog = "Start monitoring first."
            return
        }

        // Restart capture to get a clean buffer
        _ = motionService.stopCapture()
        motionService.startCapture()

        isRecording = true
        recordingStartTime = Date()
        consoleLog = "Recording throw... (2 seconds)"

        recordingTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            self?.stopRecording()
        }
    }

    func stopRecording() {
        recordingTimer?.invalidate()
        recordingTimer = nil

        let endTime = Date()
        let motionData = motionService.stopCapture()
        isRecording = false

        let releaseVector = throwAnalyzer.analyze(motionData: motionData)

        throwCounter += 1

        let label = ThrowLabel(
            intensity: selectedIntensity,
            direction: selectedDirection,
            spin: selectedSpin,
            throwNumber: throwCounter
        )

        var exportData = ExportableThrowData(
            from: motionData,
            analysis: releaseVector,
            startTime: recordingStartTime ?? endTime,
            endTime: endTime,
            label: label
        )
        _ = exportData // silence mutation warning
        recordedThrowData = exportData
        sessionThrows.append(exportData)

        // Build console output
        var log = "--- Throw #\(throwCounter) [\(selectedIntensity)/\(selectedDirection)/\(selectedSpin)] ---\n"
        log += "Samples captured: \(motionData.count)\n"
        log += "Duration: \(String(format: "%.2f", endTime.timeIntervalSince(recordingStartTime ?? endTime)))s\n"

        if let analysis = exportData.analysis {
            log += "Peak acceleration: \(String(format: "%.2f", analysis.peakAccelerationMagnitude)) g\n"
            log += "Release angle: \(String(format: "%.1f", analysis.estimatedReleaseAngleDegrees))°\n"
            log += "Estimated speed: \(String(format: "%.2f", analysis.estimatedSpeed)) m/s\n"
            log += "Release at sample: \(analysis.releaseIndex)\n"
        } else {
            log += "No throw detected (below threshold or too few samples)\n"
        }

        log += "Session total: \(sessionThrows.count) throws\n"
        consoleLog = log
        print(log)

        // Resume monitoring
        motionService.startCapture()
    }

    func exportJSON() -> Data? {
        guard let throwData = recordedThrowData else { return nil }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(throwData)
    }

    func buildSession() -> ThrowSession {
        ThrowSession(sessionDate: Date(), recordings: sessionThrows)
    }

    func clearSession() {
        sessionThrows.removeAll()
        throwCounter = 0
        recordedThrowData = nil
        consoleLog = "Session cleared. Ready for new test set."
    }
}
