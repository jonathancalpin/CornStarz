import Foundation

enum HorseshoeScore: Int {
    case ringer = 3
    case leaner = 2
    case closeShoe = 1
    case miss = 0
}

enum CornholeScore: Int {
    case inTheHole = 3
    case onTheBoard = 1
    case miss = 0
}

struct ScoringRules {

    /// Horseshoe: Cancellation scoring
    static func calculateHorseshoeRound(
        player1Throws: [HorseshoeScore],
        player2Throws: [HorseshoeScore]
    ) -> (player1Points: Int, player2Points: Int) {
        let p1Total = player1Throws.reduce(0) { $0 + $1.rawValue }
        let p2Total = player2Throws.reduce(0) { $0 + $1.rawValue }

        if p1Total > p2Total {
            return (p1Total - p2Total, 0)
        } else if p2Total > p1Total {
            return (0, p2Total - p1Total)
        }
        return (0, 0)
    }

    /// Cornhole: Cancellation scoring
    static func calculateCornholeRound(
        player1Throws: [CornholeScore],
        player2Throws: [CornholeScore]
    ) -> (player1Points: Int, player2Points: Int) {
        let p1Total = player1Throws.reduce(0) { $0 + $1.rawValue }
        let p2Total = player2Throws.reduce(0) { $0 + $1.rawValue }

        if p1Total > p2Total {
            return (p1Total - p2Total, 0)
        } else if p2Total > p1Total {
            return (0, p2Total - p1Total)
        }
        return (0, 0)
    }

    static let horseshoeWinScore = 21
    static let cornholeWinScore = 21
}
