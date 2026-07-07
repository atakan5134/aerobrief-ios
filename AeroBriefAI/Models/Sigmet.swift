import Foundation

/// A single lat/lon vertex of a SIGMET polygon.
struct GeoPoint: Codable, Hashable {
    let lat: Double
    let lon: Double
}

/// A SIGMET (Significant Meteorological Information) report that is
/// relevant to the flight's route, enriched by the backend with an
/// estimate of *when* during the flight the aircraft is expected to be
/// inside the affected FIR (derived from the OFP's EET field).
struct Sigmet: Codable, Identifiable {
    let fir: String
    let firName: String?
    let hazard: String
    let qualifier: String?
    let phenomenon: String
    let rawText: String
    let validFrom: String?
    let validTo: String?
    let baseFt: Double?
    let topFt: Double?
    let polygon: [GeoPoint]
    let onRoute: Bool
    let timeOverlap: Bool?
    let estimatedElapsedMinutes: Int?
    let estimatedFlightTime: String?
    let estimatedUtc: String?
    let altitudeOverlap: Bool?
    let locationConfirmed: Bool?
    let source: String

    var id: String { fir + phenomenon + (validFrom ?? "") + (estimatedFlightTime ?? "") }

    /// True only when the backend could confirm the flight will actually be
    /// inside this FIR while the SIGMET is valid. `nil`/false-but-unknown
    /// cases (no EET timing available) still show the report, just without
    /// a hard "you will fly through this" claim.
    var isConfirmedOnRoute: Bool {
        timeOverlap == true
    }

    enum CodingKeys: String, CodingKey {
        case fir
        case firName = "fir_name"
        case hazard, qualifier, phenomenon
        case rawText = "raw_text"
        case validFrom = "valid_from"
        case validTo = "valid_to"
        case baseFt = "base_ft"
        case topFt = "top_ft"
        case polygon
        case onRoute = "on_route"
        case timeOverlap = "time_overlap"
        case estimatedElapsedMinutes = "estimated_elapsed_minutes"
        case estimatedFlightTime = "estimated_flight_time"
        case estimatedUtc = "estimated_utc"
        case altitudeOverlap = "altitude_overlap"
        case locationConfirmed = "location_confirmed"
        case source
    }
}
