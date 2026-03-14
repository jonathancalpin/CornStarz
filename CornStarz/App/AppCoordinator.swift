import SwiftUI

/// Navigation coordinator managing app-level routing
class AppCoordinator: ObservableObject {
    enum Screen {
        case mainMenu
        case calibration
        case targetPlacement
        case game
        case results
        case settings
    }

    @Published var currentScreen: Screen = .mainMenu
    @Published var selectedGameMode: GameMode = .cornhole

    func navigateTo(_ screen: Screen) {
        currentScreen = screen
    }
}
