import SwiftUI
import Charts

struct SensorPlaygroundView: View {
    @StateObject private var viewModel = MotionViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Live Values
                liveValuesSection

                // MARK: - Acceleration Chart
                chartSection(
                    title: "Acceleration (g)",
                    data: viewModel.accelerationHistory
                )

                // MARK: - Rotation Rate Chart
                chartSection(
                    title: "Rotation Rate (rad/s)",
                    data: viewModel.rotationHistory
                )

                // MARK: - Magnitude Meter
                magnitudeSection

                Divider()

                // MARK: - Controls
                controlsSection

                // MARK: - Console Output
                consoleSection

                // MARK: - Export
                if viewModel.recordedThrowData != nil {
                    exportSection
                }
            }
            .padding()
        }
        .navigationTitle("Sensor Playground")
        .onDisappear {
            viewModel.stopMonitoring()
        }
    }

    // MARK: - Live Values

    private var liveValuesSection: some View {
        VStack(spacing: 8) {
            HStack {
                ValueLabel(title: "Accel X", value: viewModel.accelerationX, color: .red)
                ValueLabel(title: "Y", value: viewModel.accelerationY, color: .green)
                ValueLabel(title: "Z", value: viewModel.accelerationZ, color: .blue)
            }
            HStack {
                ValueLabel(title: "Rot X", value: viewModel.rotationX, color: .red)
                ValueLabel(title: "Y", value: viewModel.rotationY, color: .green)
                ValueLabel(title: "Z", value: viewModel.rotationZ, color: .blue)
            }
        }
    }

    // MARK: - Chart Section

    private func chartSection(title: String, data: [MotionSample]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)

            Chart(data) { sample in
                LineMark(
                    x: .value("Time", sample.timestamp),
                    y: .value("Value", sample.value)
                )
                .foregroundStyle(by: .value("Axis", sample.axis))
            }
            .chartForegroundStyleScale([
                "X": Color.red,
                "Y": Color.green,
                "Z": Color.blue
            ])
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 160)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Magnitude Meter

    private var magnitudeSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Acceleration Magnitude")
                .font(.headline)

            HStack(spacing: 12) {
                Gauge(value: min(viewModel.magnitude, 5.0), in: 0...5.0) {
                    EmptyView()
                } currentValueLabel: {
                    Text(String(format: "%.2f g", viewModel.magnitude))
                        .font(.caption.monospacedDigit())
                }
                .gaugeStyle(.accessoryLinear)
                .tint(magnitudeGradient)

                Text(String(format: "%.2f g", viewModel.magnitude))
                    .font(.title2.monospacedDigit().bold())
                    .frame(width: 100, alignment: .trailing)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var magnitudeGradient: Gradient {
        Gradient(colors: [.green, .yellow, .orange, .red])
    }

    // MARK: - Controls

    private var controlsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Button {
                    if viewModel.isMonitoring {
                        viewModel.stopMonitoring()
                    } else {
                        viewModel.startMonitoring()
                    }
                } label: {
                    Label(
                        viewModel.isMonitoring ? "Stop Monitoring" : "Start Monitoring",
                        systemImage: viewModel.isMonitoring ? "stop.circle.fill" : "play.circle.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(viewModel.isMonitoring ? .red : .green)

                Button {
                    viewModel.startRecording()
                } label: {
                    Label(
                        viewModel.isRecording ? "Recording..." : "Record Throw",
                        systemImage: viewModel.isRecording ? "record.circle" : "record.circle.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(!viewModel.isMonitoring || viewModel.isRecording)
            }

            if viewModel.isRecording {
                ProgressView("Capturing 2 seconds of motion data...")
                    .font(.caption)
            }
        }
    }

    // MARK: - Console Output

    private var consoleSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Console")
                .font(.headline)

            Text(viewModel.consoleLog)
                .font(.system(.caption, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(Color.black.opacity(0.8))
                .foregroundStyle(.green)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Export

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recorded Throw")
                .font(.headline)

            if let throwData = viewModel.recordedThrowData {
                // Mini chart of recorded acceleration magnitude
                Chart(throwData.samples) { sample in
                    LineMark(
                        x: .value("Time", sample.timestamp),
                        y: .value("Magnitude", sample.accelerationMagnitude)
                    )
                    .foregroundStyle(.orange)
                }
                .chartXAxisLabel("Time (s)")
                .chartYAxisLabel("Accel (g)")
                .frame(height: 120)

                HStack {
                    if let analysis = throwData.analysis {
                        VStack(alignment: .leading) {
                            Text("Peak: \(String(format: "%.2f", analysis.peakAccelerationMagnitude)) g")
                            Text("Angle: \(String(format: "%.1f", analysis.estimatedReleaseAngleDegrees))°")
                            Text("Speed: \(String(format: "%.2f", analysis.estimatedSpeed)) m/s")
                        }
                        .font(.caption.monospacedDigit())
                    }

                    Spacer()

                    ShareLink(
                        item: throwData,
                        preview: SharePreview("CornStarz Throw Data")
                    ) {
                        Label("Export JSON", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Helper Views

private struct ValueLabel: View {
    let title: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(String(format: "%+.2f", value))
                .font(.caption.monospacedDigit().bold())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }
}
