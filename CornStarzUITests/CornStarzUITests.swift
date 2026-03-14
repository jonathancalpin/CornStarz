import XCTest

final class CornStarzUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testMainMenuAppears() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["CornStarz"].exists)
    }
}
