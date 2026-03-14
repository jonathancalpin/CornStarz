import XCTest
@testable import CornStarz

final class ScoringRulesTests: XCTestCase {

    func testHorseshoeCancellationScoring() {
        let result = ScoringRules.calculateHorseshoeRound(
            player1Throws: [.ringer, .miss],
            player2Throws: [.closeShoe, .closeShoe]
        )
        // P1: 3, P2: 2 → P1 gets 1 point
        XCTAssertEqual(result.player1Points, 1)
        XCTAssertEqual(result.player2Points, 0)
    }

    func testCornholeCancellationScoring() {
        let result = ScoringRules.calculateCornholeRound(
            player1Throws: [.inTheHole, .onTheBoard],
            player2Throws: [.onTheBoard, .miss]
        )
        // P1: 4, P2: 1 → P1 gets 3 points
        XCTAssertEqual(result.player1Points, 3)
        XCTAssertEqual(result.player2Points, 0)
    }

    func testTieRoundNoPoints() {
        let result = ScoringRules.calculateCornholeRound(
            player1Throws: [.onTheBoard],
            player2Throws: [.onTheBoard]
        )
        XCTAssertEqual(result.player1Points, 0)
        XCTAssertEqual(result.player2Points, 0)
    }
}
