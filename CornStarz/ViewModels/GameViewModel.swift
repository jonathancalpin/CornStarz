import SwiftUI
import Combine

class GameViewModel: ObservableObject {
    @Published var gameState = GameState()
    @Published var isThrowInProgress = false
    @Published var lastThrowScore: Int?

    let motionService = MotionCaptureService()
    let throwAnalyzer = ThrowAnalyzer()
    let trajectoryCalculator = TrajectoryCalculator()
    let hapticsService = HapticsService()
    let audioService = AudioService()
    let arSessionManager = ARSessionManager()
    let collisionHandler = CollisionHandler()

    private var cancellables = Set<AnyCancellable>()

    func startGame(mode: GameMode) {
        gameState.gameMode = mode
        gameState.reset()
        hapticsService.prepare()
    }

    func beginThrow() {
        isThrowInProgress = true
        motionService.startCapture()
    }

    func releaseThrow() {
        let motionData = motionService.stopCapture()
        isThrowInProgress = false

        hapticsService.playThrowRelease()

        guard let releaseVector = throwAnalyzer.analyze(motionData: motionData) else {
            return
        }

        arSessionManager.launchProjectile(
            release: releaseVector,
            gameMode: gameState.gameMode
        )
    }
}
