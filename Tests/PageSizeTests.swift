// PageSizeTests.swift
import XCTest
@testable import Erasmus_App

final class PageSizeTests: XCTestCase {
    func test_default_is_positive_and_reasonable() {
        XCTAssertGreaterThan(PageSize.default, 0)
        XCTAssertLessThanOrEqual(PageSize.default, 100, "Page size demasiado grande aumentaría costes de Firestore")
    }

    func test_messages_larger_than_default() {
        // Es razonable cargar más mensajes que posts porque pesan menos
        XCTAssertGreaterThanOrEqual(PageSize.messages, PageSize.default)
    }

    func test_user_posts_reasonable() {
        XCTAssertGreaterThan(PageSize.userPosts, 0)
        XCTAssertLessThanOrEqual(PageSize.userPosts, 100)
    }
}
