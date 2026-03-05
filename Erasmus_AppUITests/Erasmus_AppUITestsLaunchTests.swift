// Erasmus_AppUITestsLaunchTests.swift
import XCTest

final class ErasmusUITestsLaunch: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIApplication().launch()
    }

    func testLaunch() throws {
        let app = XCUIApplication()
        XCTAssertTrue(app.exists, "La app se lanzó correctamente")
    }
}
