import SwiftUI
import Combine

enum ThrowPhase {
    case placement
    case ready
    case recording
    case inFlight
    case scored
}

class GameViewModel: ObservableObject {
    @Published var gameState = GameState()
    @Published var throwPhase: ThrowPhase = .placement
    @Published var lastThrowScore: Int?
    @Published var throwLog: String = ""

    let motionService = MotionCaptureService()
    let throwAnalyzer = ThrowAnalyzer()
    let hapticsService = HapticsService()
    let arSessionManager = ARSessionManager()
    let placementManager = TargetPlacementManager()
    let collisionHandler = CollisionHandler()

    private var cancellables = Set<AnyCancellable>()
    private var recordingTimer: Timer?

    func startGame(mode: GameMode) {
        gameState.gameMode = mode
        gameState.reset()
        hapticsService.prepare()
        throwPhase = .placement
    }

    // MARK: - Target Placement

    func handleTap(at point: CGPoint) {
        guard throwPhase == .placement, !arSessionManager.isTargetPlaced else { return }

        let results = arSessionManager.arView.raycast(
            from: point,
            allowing: .existingPlaneGeometry,
            alignment: .horizontal
        )

        guard let firstResult = results.first else { return }

        let worldPosition = SIMD3<Float>(
            firstResult.worldTransform.columns.3.x,
            firstResult.worldTransform.columns.3.y,
            firstResult.worldTransform.columns.3.z
        )

        arSessionManager.placeTarget(at: worldPosition, gameMode: gameState.gameMode)

        // Wire up collision detection
        collisionHandler.observeCollisions(in: arSessionManager.arView.scene) { [weak self] score in
            DispatchQueue.main.async {
                self?.handleScore(score)
            }
        }

        throwPhase = .ready
        throwLog = "Target placed! Tap Ready to Throw."
    }

    // MARK: - Throw Lifecycle

    func beginThrow() {
        guard throwPhase == .ready else { return }

        // Restart capture for clean buffer
        _ = motionService.stopCapture()
        motionService.startCapture()

        throwPhase = .recording
        throwLog = "Swing now!"

        recordingTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            self?.finishThrow()
        }
    }

    private func finishThrow() {
        recordingTimer?.invalidate()
        recordingTimer = nil

        let motionData = motionService.stopCapture()

        guard let release = throwAnalyzer.analyze(motionData: motionData) else {
            throwPhase = .ready
            throwLog = "No throw detected. Try again."
            return
        }

        hapticsService.playThrowRelease()

        arSessionManager.launchProjectile(
            release: release,
            gameMode: gameState.gameMode
        )

        throwPhase = .inFlight
        throwLog = String(format: "Speed: %.1f m/s | Angle: %.0f°",
                          release.speed,
                          release.angle * 180.0 / .pi)

        // Auto-transition to scored after flight time
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self = self, self.throwPhase == .inFlight else { return }
            if self.lastThrowScore == nil {
                self.handleScore(0) // miss if no collision detected
            }
        }
    }

    private func handleScore(_ score: Int) {
        lastThrowScore = score
        throwPhase = .scored

        if score >= 3 {
            hapticsService.playRinger()
            throwLog = "RINGER! +\(score) points"
        } else if score >= 1 {
            hapticsService.playOnTarget()
            throwLog = "On target! +\(score) points"
        } else {
            hapticsService.playLandingMiss()
            throwLog = "Miss! 0 points"
        }
    }

    func resetForNextThrow() {
        lastThrowScore = nil
        throwPhase = .ready
        throwLog = "Ready for next throw."
    }
}
