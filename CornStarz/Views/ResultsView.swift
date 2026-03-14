import SwiftUI

struct ResultsView: View {
    let player1Score: Int
    let player2Score: Int
    let gameMode: GameMode
    @Environment(\.dismiss) private var dismiss

    var winnerText: String {
        if player1Score > player2Score {
            return "Player 1 Wins!"
        } else if player2Score > player1Score {
            return "Player 2 Wins!"
        }
        return "It's a Tie!"
    }

    var body: some View {
        VStack(spacing: 30) {
            Text("Game Over")
                .font(.largeTitle.bold())

            Text(winnerText)
                .font(.title)
                .foregroundStyle(.primary)

            HStack(spacing: 40) {
                VStack {
                    Text("Player 1")
                        .font(.headline)
                    Text("\(player1Score)")
                        .font(.system(size: 48, weight: .bold).monospacedDigit())
                }

                Text("—")
                    .font(.title)

                VStack {
                    Text("Player 2")
                        .font(.headline)
                    Text("\(player2Score)")
                        .font(.system(size: 48, weight: .bold).monospacedDigit())
                }
            }

            Spacer()

            Button("Play Again") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button("Main Menu") {
                dismiss()
            }
            .foregroundStyle(.secondary)
        }
        .padding()
    }
}
