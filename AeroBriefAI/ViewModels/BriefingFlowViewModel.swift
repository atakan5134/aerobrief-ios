import Foundation
import SwiftUI
import UIKit

enum BriefingFlowStep {
    case upload
    case detectingType   // brief spinner while backend detects aircraft type
    case selectAircraft  // shown only when auto-detect fails
    case analyzing
    case result
}

@MainActor
final class BriefingFlowViewModel: ObservableObject {
    @Published var step: BriefingFlowStep = .upload
    @Published var selectedPDFData: Data?
    @Published var selectedPDFName: String?
    @Published var selectedAircraft: AircraftType?
    @Published var detectedAircraft: AircraftType?   // filled by auto-detect
    @Published var briefing: Briefing?
    @Published var errorMessage: String?

    private var service: BriefingServicing
    var windLimits: WindLimits = WindLimits()
    var defaultAircraftType: AircraftType = .a320

    init(service: BriefingServicing) {
        self.service = service
    }

    func updateService(_ service: BriefingServicing) {
        self.service = service
    }

    func selectPDF(data: Data, fileName: String) {
        selectedPDFData = data
        selectedPDFName = fileName
        errorMessage = nil
        Task { await detectAircraftType() }
    }

    /// Called when the user has already chosen an aircraft type on the home screen.
    /// Skips detection and goes straight to analysis.
    func selectPDFWithAircraft(data: Data, fileName: String, aircraft: AircraftType) {
        selectedPDFData = data
        selectedPDFName = fileName
        selectedAircraft = aircraft
        detectedAircraft = nil
        errorMessage = nil
        Task { await analyze() }
    }

    func selectAircraft(_ type: AircraftType) {
        selectedAircraft = type
        Task { await analyze() }
    }

    func analyze() async {
        guard let data = selectedPDFData, let name = selectedPDFName, let aircraft = selectedAircraft else {
            errorMessage = "Missing PDF or aircraft selection."
            return
        }
        step = .analyzing
        errorMessage = nil
        do {
            let result = try await service.uploadBriefing(pdfData: data, fileName: name, aircraftType: aircraft, windLimits: windLimits)
            briefing = result
            step = .result
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } catch {
            errorMessage = "Analysis failed: \(error.localizedDescription)"
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            step = .upload
        }
    }

    func reset() {
        step = .upload
        selectedPDFData = nil
        selectedPDFName = nil
        selectedAircraft = nil
        detectedAircraft = nil
        briefing = nil
        errorMessage = nil
    }

    // MARK: - Private

    private func detectAircraftType() async {
        guard let data = selectedPDFData, let name = selectedPDFName else { return }
        step = .detectingType

        do {
            let detected = try await service.detectAircraftType(pdfData: data, fileName: name)
            detectedAircraft = detected
            // Use detected type if available, otherwise fall back to user's default.
            selectedAircraft = detected ?? defaultAircraftType
            await analyze()
        } catch {
            // Network failure — use default and proceed rather than blocking the user.
            detectedAircraft = nil
            selectedAircraft = defaultAircraftType
            await analyze()
        }
    }
}
