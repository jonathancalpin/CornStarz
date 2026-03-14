import SwiftUI

struct MainMenuView: View {
    @State private var selectedMode: GameMode = .cornhole
    @State private var showGame = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Text("CornStarz")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(.primary)

                Text("AR Toss Game")
                    .font(.title2)
                    .foregroundStyle(.secondary)

                VStack(spacing: 16) {
                    ForEach(GameMode.allCases, id: \.self) { mode in
                        Button {
                            selectedMode = mode
                            showGame = true
                        } label: {
                            HStack {
                                Image(systemName: mode == .cornhole ? "target" : "circle.circle")
                                Text(mode.rawValue.capitalized)
                            }
                            .font(.title3)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.thinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(.horizontal, 40)

                Spacer()

                VStack(spacing: 12) {
                    #if DEBUG
                    NavigationLink(destination: SensorPlaygroundView()) {
                        Label("Sensor Playground", systemImage: "waveform")
                            .font(.body)
                    }

                    NavigationLink(destination: TrajectoryPlaygroundView()) {
                        Label("Trajectory Lab", systemImage: "arrow.up.right")
                            .font(.body)
                    }
                    #endif

                    NavigationLink(destination: SettingsView()) {
                        Label("Settings", systemImage: "gear")
                            .font(.body)
                    }
                }
            }
            .padding(.top, 80)
            .fullScreenCover(isPresented: $showGame) {
                CalibrationView(gameMode: selectedMode)
            }
        }
    }
}
