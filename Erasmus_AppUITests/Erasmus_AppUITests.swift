// Erasmus_AppUITests.swift
import XCTest

final class ErasmusUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIApplication().launch()
    }

    func testExample() throws {
        let app = XCUIApplication()
        XCTAssertTrue(app.exists, "La app se lanzó correctamente")
    }
}
