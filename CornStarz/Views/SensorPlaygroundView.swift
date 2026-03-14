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

                // MARK: - Throw Label
                throwLabelSection

                // MARK: - Controls
                controlsSection

                // MARK: - Console Output
                consoleSection

                // MARK: - Export
                if viewModel.recordedThrowData != nil {
                    exportSection
                }

                // MARK: - Session Log
                if !viewModel.sessionThrows.isEmpty {
                    sessionSection
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

    // MARK: - Throw Label

    private var throwLabelSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Throw Label")
                .font(.headline)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Intensity").font(.caption2).foregroundStyle(.secondary)
                    Picker("Intensity", selection: $viewModel.selectedIntensity) {
                        Text("Soft").tag("soft")
                        Text("Medium").tag("medium")
                        Text("Hard").tag("hard")
                    }
                    .pickerStyle(.segmented)
                }
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Direction").font(.caption2).foregroundStyle(.secondary)
                    Picker("Direction", selection: $viewModel.selectedDirection) {
                        Text("Left").tag("left")
                        Text("Straight").tag("straight")
                        Text("Right").tag("right")
                    }
                    .pickerStyle(.segmented)
                }
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Spin").font(.caption2).foregroundStyle(.secondary)
                    Picker("Spin", selection: $viewModel.selectedSpin) {
                        Text("None").tag("none")
                        Text("Top").tag("topspin")
                        Text("Side").tag("sidespin")
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
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

    // MARK: - Session Log

    private var sessionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Session Log (\(viewModel.sessionThrows.count) throws)")
                    .font(.headline)
                Spacer()
                Button("Clear") {
                    viewModel.clearSession()
                }
                .font(.caption)
                .tint(.red)
            }

            // Summary table
            ForEach(Array(viewModel.sessionThrows.enumerated()), id: \.offset) { index, throwData in
                HStack {
                    if let label = throwData.label {
                        Text("#\(label.throwNumber)")
                            .font(.caption.monospacedDigit().bold())
                            .frame(width: 30, alignment: .leading)
                        Text(label.intensity)
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(intensityColor(label.intensity).opacity(0.2))
                            .clipShape(Capsule())
                        Text(label.direction)
                            .font(.caption2)
                        if label.spin != "none" {
                            Text(label.spin)
                                .font(.caption2)
                                .foregroundStyle(.purple)
                        }
                    }
                    Spacer()
                    if let analysis = throwData.analysis {
                        Text("\(String(format: "%.1f", analysis.peakAccelerationMagnitude))g")
                            .font(.caption.monospacedDigit())
                        Text("\(String(format: "%.0f", analysis.estimatedReleaseAngleDegrees))°")
                            .font(.caption.monospacedDigit())
                        Text("\(String(format: "%.1f", analysis.estimatedSpeed))m/s")
                            .font(.caption.monospacedDigit())
                    } else {
                        Text("No throw detected")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            ShareLink(
                item: viewModel.buildSession(),
                preview: SharePreview("CornStarz Session — \(viewModel.sessionThrows.count) throws")
            ) {
                Label("Export Full Session", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func intensityColor(_ intensity: String) -> Color {
        switch intensity {
        case "soft": return .green
        case "medium": return .orange
        case "hard": return .red
        default: return .gray
        }
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
