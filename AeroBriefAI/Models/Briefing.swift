import Foundation

struct FuelSummary: Codable {
    let blockFuel: Double?
    let tripFuel: Double?
    let contingencyFuel: Double?
    let alternateFuel: Double?
    let finalReserveFuel: Double?
    let unit: String
}

struct FlightPlan: Codable {
    let flightNumber: String?
    let callsign: String?
    let aircraftRegistration: String?
    let aircraftType: String?
    let departureAirport: String?
    let destinationAirport: String?
    let alternateAirports: [String]
    let route: String?
    let waypoints: [String]
    let airways: [String]
    let firs: [String]
    let estimatedDepartureTime: String?
    let estimatedArrivalTime: String?
    let flightLevel: String?
    let fuelSummary: FuelSummary
    let dispatcherRemarks: [String]
    let operationalRemarks: [String]
    let melCdlRemarks: [String]
}

struct Briefing: Codable, Identifiable {
    let id: String
    let status: String
    let selectedAircraftType: String
    let sourceFilename: String?
    let createdAt: String
    let riskScore: Int
    let flightPlan: FlightPlan
    let warnings: [BriefingWarning]
    let notams: [AirportNotams]
    let weather: [String: AirportWeather]
    let atis: [AtisReport]
}

struct AirportNotams: Codable {
    let airport: String
    let notams: [Notam]
}

struct Notam: Codable, Identifiable {
    var id: String
    let airport: String
    let rawText: String
    let effectiveFrom: String
    let effectiveTo: String
    let fir: String?
    let aircraftRelevance: String?   // "CRITICAL" | "IMPORTANT" | "REVIEW" | "INFO" | "NOT_RELEVANT"
    let relevanceReason: String?     // human-readable explanation

    enum CodingKeys: String, CodingKey {
        case id, airport, fir
        case rawText = "raw_text"
        case effectiveFrom = "effective_from"
        case effectiveTo = "effective_to"
        case aircraftRelevance = "aircraft_relevance"
        case relevanceReason = "relevance_reason"
    }

    /// Relevance as a sortable integer (lower = more relevant)
    var relevanceRank: Int {
        switch aircraftRelevance {
        case "CRITICAL":    return 0
        case "IMPORTANT":   return 1
        case "REVIEW":      return 2
        case "INFO":        return 3
        default:            return 4  // NOT_RELEVANT or nil
        }
    }
}

struct AirportWeather: Codable {
    let metar: Metar
    let taf: Taf
}

struct Metar: Codable {
    let airport: String
    let rawText: String
    let observedAt: String

    enum CodingKeys: String, CodingKey {
        case airport
        case rawText = "raw_text"
        case observedAt = "observed_at"
    }
}

struct Taf: Codable {
    let airport: String
    let rawText: String
    let issuedAt: String
    let validFrom: String
    let validTo: String

    enum CodingKeys: String, CodingKey {
        case airport
        case rawText = "raw_text"
        case issuedAt = "issued_at"
        case validFrom = "valid_from"
        case validTo = "valid_to"
    }
}

struct AtisReport: Codable, Identifiable {
    var id: String { airport }
    let airport: String
    let letter: String
    let rawText: String
    let issuedAt: String

    enum CodingKeys: String, CodingKey {
        case airport, letter
        case rawText = "raw_text"
        case issuedAt = "issued_at"
    }
}
