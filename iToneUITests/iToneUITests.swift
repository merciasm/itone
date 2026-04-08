//
//  iToneUITests.swift
//  iToneUITests
//
//

import XCTest

final class iToneUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    @MainActor
    func testSplashToSongsView() throws {
        let app = XCUIApplication()
        app.launch()

        // Wait for splash screen to disappear (max 2 seconds)
        let songsNavTitle = app.navigationBars["Songs"]
        let songsNavTitleExists = songsNavTitle.waitForExistence(timeout: 2.0)
        XCTAssertTrue(songsNavTitleExists, "Songs navigation title should appear after splash screen")
    }

    @MainActor
    func testSearchFieldAppearsAndResponds() throws {
        let app = XCUIApplication()
        app.launch()

        let songsNavTitle = app.navigationBars["Songs"]
        XCTAssertTrue(songsNavTitle.waitForExistence(timeout: 2.0))

        // Tap the magnifying glass toolbar button to reveal the custom search bar
        let searchButton = app.navigationBars.buttons["magnifyingglass"]
        XCTAssertTrue(searchButton.exists, "Search button should exist in toolbar")
        searchButton.tap()

        let searchField = app.textFields["Search"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 2.0), "Search text field should appear after tapping search button")

        searchField.tap()
        searchField.typeText("Beatles")
        // Wait for UI to update
        sleep(1)
        XCTAssertTrue(searchField.value as? String == "Beatles", "Search field should contain the typed text")
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
