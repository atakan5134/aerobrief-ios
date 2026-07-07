import XCTest
@testable import AeroBriefAI

/// A stand-in backend so we can exercise BriefingFlowViewModel's state
/// machine without any network access.
private final class MockBriefingService: BriefingServicing {
    var detectResult: Result<AircraftType?, Error> = .success(nil)
    var uploadResult: Result<Briefing, Error>?

    func detectAircraftType(pdfData: Data, fileName: String) async throws -> AircraftType? {
        try detectResult.get()
    }

    func uploadBriefing(pdfData: Data, fileName: String, aircraftType: AircraftType, windLimits: WindLimits) async throws -> Briefing {
        guard let uploadResult else { fatalError("uploadResult not configured for this test") }
        return try uploadResult.get()
    }

    func fetchBriefing(id: String) async throws -> Briefing {
        fatalError("not used in these tests")
    }

    func fetchWarnings(briefingId: String) async throws -> WarningDashboard {
        fatalError("not used in these tests")
    }
}

private enum TestError: Error, LocalizedError {
    case connection
    var errorDescription: String? { "Could not connect to the server." }
}

@MainActor
final class BriefingFlowViewModelTests: XCTestCase {
    private func makeBriefing() -> Briefing {
        Briefing(
            id: "b1", status: "complete", selectedAircraftType: "B777", sourceFilename: "ofp.pdf",
            createdAt: "2026-07-07T00:00:00Z", riskScore: 10,
            flightPlan: FlightPlan(
                flightNumber: "TK1", callsign: nil, aircraftRegistration: nil, aircraftType: "B777",
                departureAirport: "LTFM", destinationAirport: "EGLL", alternateAirports: [],
                route: nil, waypoints: [], airways: [], firs: [],
                estimatedDepartureTime: nil, estimatedArrivalTime: nil, flightLevel: nil,
                fuelSummary: FuelSummary(blockFuel: nil, tripFuel: nil, contingencyFuel: nil,
                                         alternateFuel: nil, finalReserveFuel: nil, unit: "kg"),
                dispatcherRemarks: [], operationalRemarks: [], melCdlRemarks: []
            ),
            warnings: [], notams: [], weather: [:], atis: []
        )
    }

    func testSuccessfulAnalysisReachesResultStep() async {
        let service = MockBriefingService()
        service.uploadResult = .success(makeBriefing())
        let viewModel = BriefingFlowViewModel(service: service)

        viewModel.selectPDFWithAircraft(data: Data([0x25, 0x50, 0x44, 0x46]), fileName: "ofp.pdf", aircraft: .b777)

        // selectPDFWithAircraft kicks off an unstructured Task; give it a
        // beat to complete on the main actor.
        for _ in 0..<50 where viewModel.step != .result {
            await Task.yield()
        }

        XCTAssertEqual(viewModel.step, .result)
        XCTAssertEqual(viewModel.briefing?.id, "b1")
        XCTAssertNil(viewModel.errorMessage)
    }

    /// This is the regression case for the "unable to connect to server"
    /// bug: a network failure must surface a user-visible error and return
    /// the user to the upload step, never leave them stuck on a spinner.
    func testFailedAnalysisSurfacesErrorAndReturnsToUpload() async {
        let service = MockBriefingService()
        service.uploadResult = .failure(TestError.connection)
        let viewModel = BriefingFlowViewModel(service: service)

        viewModel.selectPDFWithAircraft(data: Data([0x25, 0x50, 0x44, 0x46]), fileName: "ofp.pdf", aircraft: .a320)

        for _ in 0..<50 where viewModel.errorMessage == nil {
            await Task.yield()
        }

        XCTAssertEqual(viewModel.step, .upload)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("Could not connect to the server.") ?? false)
    }

    func testResetClearsAllState() {
        let viewModel = BriefingFlowViewModel(service: MockBriefingService())
        viewModel.selectedPDFData = Data([1, 2, 3])
        viewModel.selectedPDFName = "ofp.pdf"
        viewModel.selectedAircraft = .a350
        viewModel.errorMessage = "boom"

        viewModel.reset()

        XCTAssertEqual(viewModel.step, .upload)
        XCTAssertNil(viewModel.selectedPDFData)
        XCTAssertNil(viewModel.selectedPDFName)
        XCTAssertNil(viewModel.selectedAircraft)
        XCTAssertNil(viewModel.errorMessage)
    }
}
