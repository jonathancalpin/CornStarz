import SwiftUI

struct GameHUDView: View {
    @ObservedObject var scoreViewModel: ScoreViewModel
    let accelerationMagnitude: Double

    var body: some View {
        VStack {
            // Score bar
            HStack {
                VStack {
                    Text("P1")
                        .font(.caption)
                    Text("\(scoreViewModel.player1Score)")
                        .font(.title.bold())
                }

                Spacer()

                VStack {
                    Text("Round \(scoreViewModel.currentRound)")
                        .font(.caption)
                    Text("Player \(scoreViewModel.currentPlayer)")
                        .font(.headline)
                }

                Spacer()

                VStack {
                    Text("P2")
                        .font(.caption)
                    Text("\(scoreViewModel.player2Score)")
                        .font(.title.bold())
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Spacer()

            // Power meter
            HStack {
                Spacer()
                PowerMeterView(magnitude: accelerationMagnitude)
            }

            Spacer()
        }
        .padding()
    }
}

struct PowerMeterView: View {
    let magnitude: Double
    private let maxMagnitude: Double = 5.0

    var normalizedPower: Double {
        min(magnitude / maxMagnitude, 1.0)
    }

    var body: some View {
        VStack {
            Text("Power")
                .font(.caption2)
            GeometryReader { geo in
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(powerColor)
                        .frame(height: geo.size.height * normalizedPower)
                }
            }
            .frame(width: 20, height: 120)
        }
    }

    var powerColor: Color {
        if normalizedPower < 0.3 { return .green }
        if normalizedPower < 0.7 { return .yellow }
        return .red
    }
}
