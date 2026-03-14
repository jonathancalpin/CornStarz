import SwiftUI

struct CalibrationView: View {
    let gameMode: GameMode
    @StateObject private var motionService = MotionCaptureService()
    @State private var isCalibrating = false
    @State private var calibrationComplete = false
    @State private var showARGame = false
    @State private var peakAcceleration: Double = 0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 30) {
            Text("Calibration")
                .font(.largeTitle.bold())

            Text("Hold your phone comfortably and do a gentle practice swing.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            HStack(spacing: 30) {
                VStack(spacing: 8) {
                    Text("Current")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.2f g", motionService.accelerationMagnitude))
                        .font(.title.monospacedDigit())
                }

                VStack(spacing: 8) {
                    Text("Peak")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.2f g", peakAcceleration))
                        .font(.title.monospacedDigit().bold())
                        .foregroundStyle(peakAcceleration > 1.5 ? .green : .primary)
                }
            }

            if calibrationComplete {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)

                Text(String(format: "Peak throw: %.2f g", peakAcceleration))
                    .font(.headline)

                Button("Start Game") {
                    showARGame = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            } else {
                Button(isCalibrating ? "Stop" : "Start Calibration") {
                    if isCalibrating {
                        _ = motionService.stopCapture()
                        calibrationComplete = true
                    } else {
                        peakAcceleration = 0
                        motionService.startCapture()
                    }
                    isCalibrating.toggle()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }

            Spacer()

            Button("Skip Calibration") {
                showARGame = true
            }
            .foregroundStyle(.secondary)

            Button("Back") {
                dismiss()
            }
            .foregroundStyle(.secondary)
        }
        .padding()
        .onChange(of: motionService.accelerationMagnitude) { _, newValue in
            if newValue > peakAcceleration {
                peakAcceleration = newValue
            }
        }
        .fullScreenCover(isPresented: $showARGame) {
            TargetPlacementView(gameMode: gameMode)
        }
    }
}
