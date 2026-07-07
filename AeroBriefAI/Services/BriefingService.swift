import Foundation

/// Abstraction over the AeroBrief AI backend so views/viewmodels never talk to
/// URLSession directly. TODO: add a caching/offline-first decorator once
/// PostgreSQL-backed persistence lands on the backend.
struct WindLimits {
    var maxHeadwind: Int  = 50
    var maxCrosswind: Int = 25
    var maxTailwind: Int  = 15
}

protocol BriefingServicing {
    func detectAircraftType(pdfData: Data, fileName: String) async throws -> AircraftType?
    func uploadBriefing(pdfData: Data, fileName: String, aircraftType: AircraftType, windLimits: WindLimits) async throws -> Briefing
    func fetchBriefing(id: String) async throws -> Briefing
    func fetchWarnings(briefingId: String) async throws -> WarningDashboard
}

final class BriefingService: BriefingServicing {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func detectAircraftType(pdfData: Data, fileName: String) async throws -> AircraftType? {
        struct DetectResponse: Decodable { let detectedType: String? }
        let response: DetectResponse = try await client.uploadMultipart(
            "/briefings/detect-aircraft",
            fileData: pdfData,
            fileName: fileName,
            mimeType: "application/pdf",
            fields: [:]
        )
        guard let raw = response.detectedType else { return nil }
        return AircraftType(rawValue: raw)
    }

    func uploadBriefing(pdfData: Data, fileName: String, aircraftType: AircraftType, windLimits: WindLimits) async throws -> Briefing {
        try await client.uploadMultipart(
            "/briefings/upload",
            fileData: pdfData,
            fileName: fileName,
            mimeType: "application/pdf",
            fields: [
                "aircraftType":  aircraftType.rawValue,
                "maxHeadwind":   "\(windLimits.maxHeadwind)",
                "maxCrosswind":  "\(windLimits.maxCrosswind)",
                "maxTailwind":   "\(windLimits.maxTailwind)",
            ]
        )
    }

    func fetchBriefing(id: String) async throws -> Briefing {
        try await client.get("/briefings/\(id)")
    }

    func fetchWarnings(briefingId: String) async throws -> WarningDashboard {
        try await client.get("/briefings/\(briefingId)/warnings")
    }
}
