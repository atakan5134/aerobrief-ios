import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct UploadBriefingView: View {
    @ObservedObject var viewModel: BriefingFlowViewModel
    @EnvironmentObject var settings: AppSettings

    @State private var isPickingFile = false
    @State private var pickerError: String?
    @State private var selectedAircraft: AircraftType = .b777
    @State private var autoDetect = true

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Hero
                heroHeader

                // Aircraft type selector
                aircraftTypeSection

                // Upload button
                uploadSection

                // Footer disclaimer
                disclaimerFooter
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 20)
        }
        .fileImporter(isPresented: $isPickingFile, allowedContentTypes: [.pdf]) { result in
            switch result {
            case .success(let url): handlePickedFile(url)
            case .failure(let error): pickerError = error.localizedDescription
            }
        }
    }

    // MARK: - Sub-views

    private var heroHeader: some View {
        VStack(spacing: 10) {
            Image(systemName: "airplane.departure")
                .font(.system(size: 56))
                .foregroundStyle(
                    LinearGradient(colors: [.accentColor, .accentColor.opacity(0.6)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )

            Text("AeroBrief AI")
                .font(.largeTitle.bold())

            Text("Aircraft-aware NOTAM & weather briefing from your OFP PDF")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private var aircraftTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Aircraft Type", systemImage: "airplane")
                    .font(.headline)
                Spacer()
                Toggle("Auto-detect", isOn: $autoDetect)
                    .toggleStyle(.switch)
                    .font(.caption)
                    .labelsHidden()
                Text("Auto-detect")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if autoDetect {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.accentColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Aircraft type will be read from your OFP PDF automatically.")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Text("You can confirm or change it before analysis starts.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.accentColor.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                // Manual picker
                VStack(spacing: 8) {
                    // Quick grid — 3 per row
                    let cols = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
                    LazyVGrid(columns: cols, spacing: 8) {
                        ForEach(AircraftType.allCases) { type in
                            Button {
                                selectedAircraft = type
                            } label: {
                                VStack(spacing: 3) {
                                    Text(type.rawValue)
                                        .font(.subheadline.bold())
                                    Text(type.category)
                                        .font(.caption2)
                                        .foregroundColor(selectedAircraft == type ? .white.opacity(0.85) : .secondary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(selectedAircraft == type ? Color.accentColor : Color(.secondarySystemBackground))
                                .foregroundColor(selectedAircraft == type ? .white : .primary)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedAircraft == type ? Color.accentColor : Color.clear, lineWidth: 1.5)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Selected type detail
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.accentColor)
                        Text("\(selectedAircraft.rawValue)  ·  \(selectedAircraft.displayName)  ·  \(selectedAircraft.category)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(14)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var uploadSection: some View {
        VStack(spacing: 12) {
            if let pickerError {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.red)
                    Text(pickerError).font(.footnote).foregroundColor(.red)
                }
                .padding(12)
                .background(Color.red.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Button {
                pickerError = nil
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                isPickingFile = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "doc.badge.plus")
                        .font(.title3.bold())
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Upload Flight Plan PDF")
                            .font(.headline)
                        Text(autoDetect
                             ? "Aircraft type will be detected automatically"
                             : "Will analyze as \(selectedAircraft.rawValue) — \(selectedAircraft.displayName)")
                            .font(.caption)
                            .opacity(0.85)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption.bold())
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)

            Text("Tap to select an Operational Flight Plan PDF from Files")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var disclaimerFooter: some View {
        Text("AeroBrief AI assists with briefing review. It does not replace official dispatch, EFB, Jeppesen, Lido, or company systems.")
            .font(.caption2)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8)
    }

    // MARK: - File handling

    private func handlePickedFile(_ url: URL) {
        pickerError = nil
        Task {
            do {
                let data = try await Self.readData(from: url)
                if autoDetect {
                    // Let backend detect aircraft type from the PDF
                    viewModel.selectPDF(data: data, fileName: url.lastPathComponent)
                } else {
                    // User already chose the type — skip detection, go straight to analysis
                    viewModel.selectPDFWithAircraft(data: data, fileName: url.lastPathComponent, aircraft: selectedAircraft)
                }
            } catch {
                pickerError = "Failed to read PDF: \(error.localizedDescription)"
            }
        }
    }

    /// Reads the picked file off the main actor. OFP PDFs can be several MB,
    /// so synchronous disk I/O here would otherwise briefly freeze the UI.
    private static func readData(from url: URL) async throws -> Data {
        try await Task.detached(priority: .userInitiated) {
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            defer { if didStartAccessing { url.stopAccessingSecurityScopedResource() } }
            return try Data(contentsOf: url)
        }.value
    }
}
