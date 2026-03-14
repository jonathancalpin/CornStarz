import SwiftUI
import Combine

enum ThrowPhase {
    case placement    // scanning & placing the board
    case walkBack     // board placed, walk to throwing position
    case ready        // at throwing position, ready to throw
    case recording    // 2-second capture in progress
    case inFlight     // projectile launched
    case scored       // result displayed
}

class GameViewModel: ObservableObject {
    @Published var gameState = GameState()
    @Published var throwPhase: ThrowPhase = .placement
    @Published var lastThrowScore: Int?
    @Published var throwLog: String = ""
    @Published var targetDistanceMeters: Float = 8.2

    let motionService = MotionCaptureService()
    let throwAnalyzer = ThrowAnalyzer()
    let hapticsService = HapticsService()
    let arSessionManager = ARSessionManager()
    let collisionHandler = CollisionHandler()

    private var cancellables = Set<AnyCancellable>()
    private var recordingTimer: Timer?

    func startGame(mode: GameMode) {
        gameState.gameMode = mode
        gameState.reset()
        hapticsService.prepare()
        throwPhase = .placement

        switch mode {
        case .cornhole:
            targetDistanceMeters = 8.2
        case .horseshoe:
            targetDistanceMeters = 12.2
        }
    }

    // MARK: - Target Placement

    /// Tap to place the board on a detected surface, then walk back
    func handleTap(at point: CGPoint) {
        guard throwPhase == .placement, !arSessionManager.isTargetPlaced else { return }

        let results = arSessionManager.arView.raycast(
            from: point,
            allowing: .existingPlaneGeometry,
            alignment: .horizontal
        )

        guard let firstResult = results.first else {
            throwLog = "No surface detected. Tap the floor."
            return
        }

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

        throwPhase = .walkBack
        throwLog = "Board placed! Walk back to your throwing position."
    }

    /// User is at desired distance, ready to throw
    func confirmPosition() {
        throwPhase = .ready
        throwLog = String(format: "Throwing from %.1fm. Tap Ready to Throw!", arSessionManager.targetDistance)
    }

    // MARK: - Throw Lifecycle

    func beginThrow() {
        guard throwPhase == .ready else { return }

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

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self = self, self.throwPhase == .inFlight else { return }
            if self.lastThrowScore == nil {
                self.handleScore(0)
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
        throwLog = String(format: "Distance: %.1fm. Ready for next throw.", arSessionManager.targetDistance)
    }
}
