import XCTest
@testable import CornStarz

final class TrajectoryCalculatorTests: XCTestCase {

    func testTrajectoryCalculation() {
        let calculator = TrajectoryCalculator()
        let release = ReleaseVector(
            speed: 8.0,
            angle: .pi / 4,
            spin: 0,
            lateralOffset: 0
        )

        let trajectory = calculator.calculateTrajectory(release: release)
        XCTAssertFalse(trajectory.isEmpty)

        // Projectile should eventually hit the ground
        if let lastPoint = trajectory.last {
            XCTAssertEqual(lastPoint.position.y, 0, accuracy: 0.1)
        }
    }

    func testLandingDistance() {
        let calculator = TrajectoryCalculator()
        let release = ReleaseVector(
            speed: 8.0,
            angle: .pi / 4,
            spin: 0,
            lateralOffset: 0
        )

        let trajectory = calculator.calculateTrajectory(release: release)
        let distance = calculator.landingDistance(from: trajectory)
        XCTAssertGreaterThan(distance, 0)
    }
}
