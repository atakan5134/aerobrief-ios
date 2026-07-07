import Foundation
import SwiftUI

enum WarningSeverity: String, Codable, CaseIterable {
    case critical = "CRITICAL"
    case important = "IMPORTANT"
    case review = "REVIEW"
    case info = "INFO"

    var color: Color {
        switch self {
        case .critical: return .red
        case .important: return .orange
        case .review: return .yellow
        case .info: return .blue
        }
    }

    var sortWeight: Int {
        switch self {
        case .critical: return 4
        case .important: return 3
        case .review: return 2
        case .info: return 1
        }
    }
}

enum WarningCategory: String, Codable, CaseIterable {
    case runway = "RUNWAY"
    case navaid = "NAVAID"
    case taxi = "TAXI"
    case weather = "WEATHER"
    case airspace = "AIRSPACE"
    case etops = "ETOPS"
    case fuel = "FUEL"
    case atis = "ATIS"
    case performance = "PERFORMANCE"
    case melCdl = "MEL_CDL"
    case security = "SECURITY"
    case general = "GENERAL"

    var systemImage: String {
        switch self {
        case .runway: return "airplane.departure"
        case .navaid: return "antenna.radiowaves.left.and.right"
        case .taxi: return "arrow.triangle.turn.up.right.diamond"
        case .weather: return "cloud.bolt.rain"
        case .airspace: return "globe"
        case .etops: return "airplane.circle"
        case .fuel: return "fuelpump"
        case .atis: return "waveform"
        case .performance: return "gauge.with.dots.needle.67percent"
        case .melCdl: return "wrench.and.screwdriver"
        case .security: return "shield.lefthalf.filled"
        case .general: return "exclamationmark.circle"
        }
    }
}

struct BriefingWarning: Codable, Identifiable {
    var id: String { (rawReference ?? title) + severity.rawValue + (airport ?? "") }
    let category: WarningCategory
    let severity: WarningSeverity
    let title: String
    let message: String
    let source: String
    let airport: String?
    let rawReference: String?
}

struct WarningDashboard: Codable {
    let briefingId: String
    let riskScore: Int
    let totalWarnings: Int
    let criticalCount: Int
    let importantCount: Int
    let reviewCount: Int
    let infoCount: Int
    let warnings: [BriefingWarning]
}
