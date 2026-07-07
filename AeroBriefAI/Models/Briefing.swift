import Foundation

struct FuelSummary: Codable {
    let blockFuel: Double?
    let tripFuel: Double?
    let contingencyFuel: Double?
    let alternateFuel: Double?
    let finalReserveFuel: Double?
    let unit: String
}

/// A single waypoint or FIR-boundary crossing from the OFP's detailed route
/// table, with real coordinates and cumulative elapsed time since
/// departure — enough to draw the actual flight path on a map. Not every
/// OFP format has this table (see backend's ofp_route_table.py), so this
/// can be empty even for a successfully analyzed briefing.
struct RoutePoint: Codable, Identifiable {
    let ident: String
    let lat: Double
    let lon: Double
    let acctMinutes: Int?
    let remtMinutes: Int?
    let isFirBoundary: Bool
    let fir: String?

    var id: String { "\(ident)-\(lat)-\(lon)" }
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
    let routePoints: [RoutePoint]

    enum CodingKeys: String, CodingKey {
        case flightNumber, callsign, aircraftRegistration, aircraftType
        case departureAirport, destinationAirport, alternateAirports, route
        case waypoints, airways, firs, estimatedDepartureTime, estimatedArrivalTime
        case flightLevel, fuelSummary, dispatcherRemarks, operationalRemarks
        case melCdlRemarks, routePoints
    }

    init(flightNumber: String?, callsign: String?, aircraftRegistration: String?, aircraftType: String?,
         departureAirport: String?, destinationAirport: String?, alternateAirports: [String],
         route: String?, waypoints: [String], airways: [String], firs: [String],
         estimatedDepartureTime: String?, estimatedArrivalTime: String?, flightLevel: String?,
         fuelSummary: FuelSummary, dispatcherRemarks: [String], operationalRemarks: [String],
         melCdlRemarks: [String], routePoints: [RoutePoint] = []) {
        self.flightNumber = flightNumber
        self.callsign = callsign
        self.aircraftRegistration = aircraftRegistration
        self.aircraftType = aircraftType
        self.departureAirport = departureAirport
        self.destinationAirport = destinationAirport
        self.alternateAirports = alternateAirports
        self.route = route
        self.waypoints = waypoints
        self.airways = airways
        self.firs = firs
        self.estimatedDepartureTime = estimatedDepartureTime
        self.estimatedArrivalTime = estimatedArrivalTime
        self.flightLevel = flightLevel
        self.fuelSummary = fuelSummary
        self.dispatcherRemarks = dispatcherRemarks
        self.operationalRemarks = operationalRemarks
        self.melCdlRemarks = melCdlRemarks
        self.routePoints = routePoints
    }

    // Custom decoding so briefings saved before "routePoints" existed on the
    // backend still decode fine (defaults to empty, same pattern as
    // Briefing's "sigmets" backward-compatibility handling below).
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        flightNumber = try c.decodeIfPresent(String.self, forKey: .flightNumber)
        callsign = try c.decodeIfPresent(String.self, forKey: .callsign)
        aircraftRegistration = try c.decodeIfPresent(String.self, forKey: .aircraftRegistration)
        aircraftType = try c.decodeIfPresent(String.self, forKey: .aircraftType)
        departureAirport = try c.decodeIfPresent(String.self, forKey: .departureAirport)
        destinationAirport = try c.decodeIfPresent(String.self, forKey: .destinationAirport)
        alternateAirports = try c.decode([String].self, forKey: .alternateAirports)
        route = try c.decodeIfPresent(String.self, forKey: .route)
        waypoints = try c.decode([String].self, forKey: .waypoints)
        airways = try c.decode([String].self, forKey: .airways)
        firs = try c.decode([String].self, forKey: .firs)
        estimatedDepartureTime = try c.decodeIfPresent(String.self, forKey: .estimatedDepartureTime)
        estimatedArrivalTime = try c.decodeIfPresent(String.self, forKey: .estimatedArrivalTime)
        flightLevel = try c.decodeIfPresent(String.self, forKey: .flightLevel)
        fuelSummary = try c.decode(FuelSummary.self, forKey: .fuelSummary)
        dispatcherRemarks = try c.decode([String].self, forKey: .dispatcherRemarks)
        operationalRemarks = try c.decode([String].self, forKey: .operationalRemarks)
        melCdlRemarks = try c.decode([String].self, forKey: .melCdlRemarks)
        routePoints = try c.decodeIfPresent([RoutePoint].self, forKey: .routePoints) ?? []
    }
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
    let sigmets: [Sigmet]

    enum CodingKeys: String, CodingKey {
        case id, status, selectedAircraftType, sourceFilename, createdAt, riskScore
        case flightPlan, warnings, notams, weather, atis, sigmets
    }

    init(id: String, status: String, selectedAircraftType: String, sourceFilename: String?,
         createdAt: String, riskScore: Int, flightPlan: FlightPlan, warnings: [BriefingWarning],
         notams: [AirportNotams], weather: [String: AirportWeather], atis: [AtisReport],
         sigmets: [Sigmet] = []) {
        self.id = id
        self.status = status
        self.selectedAircraftType = selectedAircraftType
        self.sourceFilename = sourceFilename
        self.createdAt = createdAt
        self.riskScore = riskScore
        self.flightPlan = flightPlan
        self.warnings = warnings
        self.notams = notams
        self.weather = weather
        self.atis = atis
        self.sigmets = sigmets
    }

    // Custom decoding so older cached briefings (saved before the "sigmets"
    // field existed on the backend) still decode fine — sigmets defaults to
    // empty rather than failing the whole briefing.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        status = try c.decode(String.self, forKey: .status)
        selectedAircraftType = try c.decode(String.self, forKey: .selectedAircraftType)
        sourceFilename = try c.decodeIfPresent(String.self, forKey: .sourceFilename)
        createdAt = try c.decode(String.self, forKey: .createdAt)
        riskScore = try c.decode(Int.self, forKey: .riskScore)
        flightPlan = try c.decode(FlightPlan.self, forKey: .flightPlan)
        warnings = try c.decode([BriefingWarning].self, forKey: .warnings)
        notams = try c.decode([AirportNotams].self, forKey: .notams)
        weather = try c.decode([String: AirportWeather].self, forKey: .weather)
        atis = try c.decode([AtisReport].self, forKey: .atis)
        sigmets = try c.decodeIfPresent([Sigmet].self, forKey: .sigmets) ?? []
    }
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
