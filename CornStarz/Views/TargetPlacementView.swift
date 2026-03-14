import SwiftUI

struct TargetPlacementView: View {
    let gameMode: GameMode
    @StateObject private var gameViewModel = GameViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // AR Camera feed
            ARGameView(
                arSessionManager: gameViewModel.arSessionManager,
                onTap: { point in
                    gameViewModel.handleTap(at: point)
                }
            )
            .ignoresSafeArea()

            // HUD Overlay
            VStack {
                // Top bar
                topBar

                Spacer()

                // Bottom controls
                bottomControls
            }
            .padding()
        }
        .onAppear {
            gameViewModel.startGame(mode: gameMode)
        }
        .statusBarHidden()
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Planes: \(gameViewModel.arSessionManager.planesDetected)")
                    .font(.caption.monospacedDigit())

                if gameViewModel.arSessionManager.isTargetPlaced {
                    Text(String(format: "Distance: %.1fm", gameViewModel.arSessionManager.targetDistance))
                        .font(.caption.monospacedDigit())
                }
            }
            .padding(8)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Spacer()

            // Close button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 12) {
            // Console log
            if !gameViewModel.throwLog.isEmpty {
                Text(gameViewModel.throwLog)
                    .font(.system(.callout, design: .monospaced).bold())
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Color.black.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // Phase-specific controls
            switch gameViewModel.throwPhase {
            case .placement:
                promptCapsule("Tap a surface to place the \(gameMode.rawValue) target")

            case .ready:
                Button {
                    gameViewModel.beginThrow()
                } label: {
                    Label("Ready to Throw", systemImage: "figure.throw")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)

            case .recording:
                VStack(spacing: 8) {
                    Text("SWING NOW!")
                        .font(.title.bold())
                        .foregroundStyle(.orange)

                    ProgressView()
                        .tint(.orange)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            case .inFlight:
                promptCapsule("Watching...")

            case .scored:
                VStack(spacing: 12) {
                    if let score = gameViewModel.lastThrowScore {
                        Text(score > 0 ? "+\(score)" : "MISS")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(score >= 3 ? .green : score >= 1 ? .yellow : .red)
                    }

                    Button {
                        gameViewModel.resetForNextThrow()
                    } label: {
                        Label("Throw Again", systemImage: "arrow.counterclockwise")
                            .font(.title3.bold())
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func promptCapsule(_ text: String) -> some View {
        Text(text)
            .font(.callout)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
    }
}
