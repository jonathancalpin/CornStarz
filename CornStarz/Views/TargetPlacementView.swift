import SwiftUI

struct TargetPlacementView: View {
    let gameMode: GameMode
    @StateObject private var arSessionManager = ARSessionManager()
    @StateObject private var placementManager = TargetPlacementManager()

    var body: some View {
        ZStack {
            ARGameView(arSessionManager: arSessionManager)
                .ignoresSafeArea()

            VStack {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Planes: \(arSessionManager.planesDetected)")
                        if arSessionManager.isTargetPlaced {
                            Text(String(format: "Distance: %.1fm", arSessionManager.targetDistance))
                        }
                    }
                    .font(.caption.monospacedDigit())
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    Spacer()
                }

                Spacer()

                if !arSessionManager.isTargetPlaced {
                    Text("Tap a surface to place the \(gameMode.rawValue) target")
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
            }
            .padding()
        }
    }
}
