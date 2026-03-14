import Foundation

class GameState: ObservableObject {
    @Published var currentRound: Int = 1
    @Published var currentPlayer: Int = 1
    @Published var throwsThisRound: Int = 0
    @Published var player1Score: Int = 0
    @Published var player2Score: Int = 0
    @Published var isGameOver: Bool = false
    @Published var gameMode: GameMode = .cornhole

    let throwsPerRound = 4  // 2 per player
    let winScore = 21

    func reset() {
        currentRound = 1
        currentPlayer = 1
        throwsThisRound = 0
        player1Score = 0
        player2Score = 0
        isGameOver = false
    }
}
