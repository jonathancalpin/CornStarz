import XCTest
@testable import CornStarz

final class ThrowAnalyzerTests: XCTestCase {

    func testAnalyzerRejectsEmptyData() {
        let analyzer = ThrowAnalyzer()
        let result = analyzer.analyze(motionData: [])
        XCTAssertNil(result)
    }

    func testAnalyzerRejectsTooFewSamples() {
        let analyzer = ThrowAnalyzer()
        let result = analyzer.analyze(motionData: [])
        XCTAssertNil(result, "Should reject motion data with fewer than 10 samples")
    }
}
