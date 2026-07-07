import XCTest
@testable import AeroBriefAI

final class AircraftTypeTests: XCTestCase {
    func testEveryCaseHasANonEmptyDisplayName() {
        for type in AircraftType.allCases {
            XCTAssertFalse(type.displayName.isEmpty, "\(type.rawValue) has an empty displayName")
        }
    }

    func testCategoryGrouping() {
        XCTAssertEqual(AircraftType.b737.category, "Short/Medium Haul")
        XCTAssertEqual(AircraftType.a320.category, "Short/Medium Haul")
        XCTAssertEqual(AircraftType.a321.category, "Short/Medium Haul")
        XCTAssertEqual(AircraftType.e190.category, "Regional")
        XCTAssertEqual(AircraftType.a220.category, "Regional")
        XCTAssertEqual(AircraftType.b787.category, "Wide-body Long-haul")
        XCTAssertEqual(AircraftType.a330.category, "Wide-body Long-haul")
        XCTAssertEqual(AircraftType.a350.category, "Wide-body Long-haul")
        XCTAssertEqual(AircraftType.b777.category, "Heavy Wide-body")
    }

    func testRawValueRoundTrips() {
        for type in AircraftType.allCases {
            XCTAssertEqual(AircraftType(rawValue: type.rawValue), type)
        }
    }

    func testUnknownRawValueReturnsNil() {
        XCTAssertNil(AircraftType(rawValue: "CONCORDE"))
    }
}
