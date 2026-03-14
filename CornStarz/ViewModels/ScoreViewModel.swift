import SwiftUI
import Combine

class ScoreViewModel: ObservableObject {
    @Published var player1Score: Int = 0
    @Published var player2Score: Int = 0
    @Published var currentRound: Int = 1
    @Published var currentPlayer: Int = 1
    @Published var gameOverMessage: String?

    private var cancellables = Set<AnyCancellable>()

    func bind(to gameState: GameState) {
        gameState.$player1Score
            .assign(to: &$player1Score)
        gameState.$player2Score
            .assign(to: &$player2Score)
        gameState.$currentRound
            .assign(to: &$currentRound)
        gameState.$currentPlayer
            .assign(to: &$currentPlayer)
    }
}
