import SwiftUI

struct CalibrationView: View {
    let gameMode: GameMode
    @StateObject private var motionService = MotionCaptureService()
    @State private var isCalibrating = false
    @State private var calibrationComplete = false
    @State private var showARGame = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 30) {
            Text("Calibration")
                .font(.largeTitle.bold())

            Text("Hold your phone comfortably and do a gentle practice swing.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            VStack(spacing: 8) {
                Text("Acceleration")
                    .font(.caption)
                Text(String(format: "%.2f g", motionService.accelerationMagnitude))
                    .font(.title.monospacedDigit())
            }

            if calibrationComplete {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)

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
                        motionService.startCapture()
                    }
                    isCalibrating.toggle()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }

            Spacer()

            Button("Back") {
                dismiss()
            }
            .foregroundStyle(.secondary)
        }
        .padding()
        .fullScreenCover(isPresented: $showARGame) {
            TargetPlacementView(gameMode: gameMode)
        }
    }
}
