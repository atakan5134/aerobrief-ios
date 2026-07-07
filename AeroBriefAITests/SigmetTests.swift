import XCTest
@testable import AeroBriefAI

/// Tests for the Sigmet model's decoding (matches the backend's snake_case
/// dict shape from sigmet_service.py / sigmet_correlator.py) and for
/// Briefing's backward-compatible handling of the "sigmets" field.
final class SigmetTests: XCTestCase {
    private let fullSigmetJSON = """
    {
        "fir": "EGTT",
        "fir_name": "LONDON",
        "hazard": "TURB",
        "qualifier": "SEV",
        "phenomenon": "Severe Turbulence",
        "raw_text": "EGTT SIGMET 1 VALID 071100/071300 SEV TURB FCST FL280/380",
        "valid_from": "2026-07-07T11:00:00Z",
        "valid_to": "2026-07-07T13:00:00Z",
        "base_ft": 28000,
        "top_ft": 38000,
        "polygon": [{"lat": 51.0, "lon": -1.0}, {"lat": 52.0, "lon": 0.5}, {"lat": 50.5, "lon": 1.0}],
        "on_route": true,
        "time_overlap": true,
        "estimated_elapsed_minutes": 100,
        "estimated_flight_time": "01:40",
        "estimated_utc": "2026-07-07T11:10:00Z",
        "altitude_overlap": true,
        "source": "aviationweather.gov"
    }
    """

    func testDecodesFullSigmetFromBackendShape() throws {
        let sigmet = try JSONDecoder().decode(Sigmet.self, from: Data(fullSigmetJSON.utf8))
        XCTAssertEqual(sigmet.fir, "EGTT")
        XCTAssertEqual(sigmet.firName, "LONDON")
        XCTAssertEqual(sigmet.hazard, "TURB")
        XCTAssertEqual(sigmet.qualifier, "SEV")
        XCTAssertEqual(sigmet.polygon.count, 3)
        XCTAssertEqual(sigmet.polygon.first?.lat, 51.0)
        XCTAssertEqual(sigmet.estimatedFlightTime, "01:40")
        XCTAssertEqual(sigmet.timeOverlap, true)
        XCTAssertTrue(sigmet.isConfirmedOnRoute)
    }

    func testDecodesSigmetWithNullTimingFields() throws {
        let json = """
        {
            "fir": "LFFF", "fir_name": null, "hazard": "TURB", "qualifier": null,
            "phenomenon": "Severe Turbulence", "raw_text": "...",
            "valid_from": null, "valid_to": null, "base_ft": null, "top_ft": null,
            "polygon": [], "on_route": true, "time_overlap": null,
            "estimated_elapsed_minutes": null, "estimated_flight_time": null,
            "estimated_utc": null, "altitude_overlap": null, "source": "mock"
        }
        """
        let sigmet = try JSONDecoder().decode(Sigmet.self, from: Data(json.utf8))
        XCTAssertNil(sigmet.timeOverlap)
        XCTAssertFalse(sigmet.isConfirmedOnRoute)
        XCTAssertTrue(sigmet.polygon.isEmpty)
    }

    /// Regression test: briefings saved before the backend had a "sigmets"
    /// field must still decode, with sigmets defaulting to empty.
    func testBriefingDecodesWithoutSigmetsKeyForBackwardCompatibility() throws {
        let json = """
        {
            "id": "b1", "status": "COMPLETE", "selectedAircraftType": "B777",
            "sourceFilename": "ofp.pdf", "createdAt": "2026-07-07T00:00:00Z", "riskScore": 10,
            "flightPlan": {
                "flightNumber": "TK1", "callsign": null, "aircraftRegistration": null,
                "aircraftType": "B777", "departureAirport": "LTFM", "destinationAirport": "EGLL",
                "alternateAirports": [], "route": null, "waypoints": [], "airways": [], "firs": [],
                "estimatedDepartureTime": null, "estimatedArrivalTime": null, "flightLevel": null,
                "fuelSummary": {"blockFuel": null, "tripFuel": null, "contingencyFuel": null,
                                "alternateFuel": null, "finalReserveFuel": null, "unit": "kg"},
                "dispatcherRemarks": [], "operationalRemarks": [], "melCdlRemarks": []
            },
            "warnings": [], "notams": [], "weather": {}, "atis": []
        }
        """
        let briefing = try JSONDecoder().decode(Briefing.self, from: Data(json.utf8))
        XCTAssertEqual(briefing.id, "b1")
        XCTAssertTrue(briefing.sigmets.isEmpty)
    }
}
