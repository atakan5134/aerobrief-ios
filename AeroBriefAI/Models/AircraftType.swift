import Foundation

enum AircraftType: String, CaseIterable, Codable, Identifiable {
    case b737 = "B737"
    case a320 = "A320"
    case a321 = "A321"
    case b777 = "B777"
    case b787 = "B787"
    case a330 = "A330"
    case a350 = "A350"
    case e190 = "E190"
    case a220 = "A220"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .b737: return "Boeing 737"
        case .a320: return "Airbus A320"
        case .a321: return "Airbus A321"
        case .b777: return "Boeing 777"
        case .b787: return "Boeing 787 Dreamliner"
        case .a330: return "Airbus A330"
        case .a350: return "Airbus A350"
        case .e190: return "Embraer E190"
        case .a220: return "Airbus A220"
        }
    }

    var category: String {
        switch self {
        case .b737, .a320, .a321: return "Short/Medium Haul"
        case .e190, .a220: return "Regional"
        case .b787, .a330, .a350: return "Wide-body Long-haul"
        case .b777: return "Heavy Wide-body"
        }
    }
}
