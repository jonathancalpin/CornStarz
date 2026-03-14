import SwiftUI
import SpriteKit

struct TrajectoryPlaygroundView: View {
    @StateObject private var viewModel = TrajectoryViewModel()
    @State private var scene: TrajectorySceneView = {
        let scene = TrajectorySceneView(size: CGSize(width: 700, height: 350))
        scene.scaleMode = .resizeFill
        return scene
    }()

    var body: some View {
        VStack(spacing: 0) {
            // SpriteKit scene
            SpriteView(scene: scene)
                .frame(maxWidth: .infinity)
                .frame(height: UIScreen.main.bounds.height * 0.45)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 8)

            // Controls
            ScrollView {
                VStack(spacing: 12) {
                    // Console
                    Text(viewModel.consoleLog)
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color.black.opacity(0.8))
                        .foregroundStyle(.green)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    // Buttons
                    HStack(spacing: 12) {
                        Button {
                            if viewModel.isReady {
                                viewModel.recordThrow()
                            } else {
                                viewModel.startListening()
                            }
                        } label: {
                            Label(
                                viewModel.isRecording ? "Recording..." :
                                    viewModel.isReady ? "Record Throw" : "Start",
                                systemImage: viewModel.isRecording ? "record.circle" :
                                    viewModel.isReady ? "record.circle.fill" : "play.circle.fill"
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(viewModel.isRecording ? .orange : viewModel.isReady ? .orange : .green)
                        .disabled(viewModel.isRecording)

                        Button {
                            viewModel.clearAttempts()
                            scene.clearAllAttempts()
                        } label: {
                            Label("Clear", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }

                    // Tuning sliders
                    DisclosureGroup("Physics Tuning") {
                        VStack(spacing: 10) {
                            sliderRow("Speed Scale", value: $viewModel.speedScaleFactor, range: 0.5...5.0, format: "%.1f")
                            sliderRow("Angle Offset", value: $viewModel.angleOffsetDegrees, range: -45...45, format: "%.0f°")
                            sliderRow("Drag", value: $viewModel.dragCoefficient, range: 0.0...0.3, format: "%.3f")
                            sliderRow("Target (m)", value: $viewModel.targetDistance, range: 4.0...16.0, format: "%.1f")
                        }
                    }
                    .onChange(of: viewModel.targetDistance) { _, newValue in
                        scene.updateTargetDistance(newValue)
                    }

                    // Throw history
                    if !viewModel.attempts.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Throw History")
                                .font(.headline)

                            ForEach(viewModel.attempts) { attempt in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(attempt.color)
                                        .frame(width: 10, height: 10)
                                    Text(String(format: "%.1f m/s", attempt.releaseVector.speed))
                                        .font(.caption.monospacedDigit())
                                    Text(String(format: "%.0f°", attempt.releaseVector.angle * 180 / .pi))
                                        .font(.caption.monospacedDigit())
                                    Spacer()
                                    Text(String(format: "%.1fm", attempt.landingDistance))
                                        .font(.caption.monospacedDigit())
                                    Text(String(format: "%+.1fm", attempt.distanceFromTarget))
                                        .font(.caption.monospacedDigit().bold())
                                        .foregroundStyle(distanceColor(attempt.distanceFromTarget))
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Trajectory Lab")
        .onAppear {
            viewModel.onNewThrow = { [scene] attempt in
                scene.addThrowAttempt(attempt)
            }
        }
        .onDisappear {
            viewModel.stopListening()
        }
    }

    private func sliderRow(_ label: String, value: Binding<Double>, range: ClosedRange<Double>, format: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .frame(width: 90, alignment: .leading)
            Slider(value: value, in: range)
            Text(String(format: format, value.wrappedValue))
                .font(.caption.monospacedDigit())
                .frame(width: 50, alignment: .trailing)
        }
    }

    private func distanceColor(_ distance: Double) -> Color {
        let abs = abs(distance)
        if abs < 0.5 { return .green }
        if abs < 1.5 { return .yellow }
        return .red
    }
}
