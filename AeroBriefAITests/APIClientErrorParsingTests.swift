import XCTest
@testable import AeroBriefAI

/// Regression tests for the friendly-error-message layer added after we
/// noticed raw backend error bodies (JSON/HTML) were being shown directly
/// to pilots on failure. See Services/APIClient.swift.
final class APIClientErrorParsingTests: XCTestCase {
    func testStringDetailIsUsedVerbatim() {
        let json = Data(#"{"detail": "PDF could not be parsed."}"#.utf8)
        XCTAssertEqual(friendlyServerMessage(status: 400, data: json), "PDF could not be parsed.")
    }

    func testValidationErrorArrayIsJoined() {
        let json = Data(#"""
        {"detail": [
            {"loc": ["body", "file"], "msg": "field required", "type": "value_error.missing"},
            {"loc": ["body", "aircraftType"], "msg": "invalid aircraft type", "type": "value_error"}
        ]}
        """#.utf8)
        let message = friendlyServerMessage(status: 422, data: json)
        XCTAssertTrue(message.contains("field required"))
        XCTAssertTrue(message.contains("invalid aircraft type"))
    }

    func testUnparsableBodyFallsBackToFriendlyStatusMessage() {
        let html = Data("<html><body>502 Bad Gateway</body></html>".utf8)
        XCTAssertEqual(
            friendlyServerMessage(status: 502, data: html),
            "The backend is having trouble processing this briefing. Please try again shortly."
        )
    }

    func testEmptyBodyFallsBackPerStatusCode() {
        XCTAssertEqual(
            friendlyServerMessage(status: 404, data: Data()),
            "The backend endpoint wasn't found. Check your Backend URL in Settings."
        )
        XCTAssertEqual(
            friendlyServerMessage(status: 429, data: Data()),
            "Too many requests — please wait a moment and try again."
        )
    }

    func testUnknownStatusCodeStillProducesAReadableMessage() {
        let message = friendlyServerMessage(status: 418, data: Data())
        XCTAssertEqual(message, "Server error (418). Please try again.")
    }
}
