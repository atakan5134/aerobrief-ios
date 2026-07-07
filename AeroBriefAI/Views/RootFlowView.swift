import SwiftUI

struct RootFlowView: View {
    @EnvironmentObject var settings: AppSettings
    @StateObject private var viewModel: BriefingFlowViewModel

    init() {
        _viewModel = StateObject(wrappedValue: BriefingFlowViewModel(service: BriefingService(client: APIClient(baseURL: URL(string: "https://aerobrief-backend-production.up.railway.app")!))))
    }

    var body: some View {
        NavigationStack {
            stepContent
                .onChange(of: settings.maxHeadwind)  { _, _ in syncWindLimits() }
                .onChange(of: settings.maxCrosswind) { _, _ in syncWindLimits() }
                .onChange(of: settings.maxTailwind)  { _, _ in syncWindLimits() }
                .onAppear { syncWindLimits() }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink { SettingsView() } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
        }
        .sheet(isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            ErrorSheet(
                message: viewModel.errorMessage ?? "",
                canRetry: viewModel.selectedPDFData != nil && viewModel.selectedAircraft != nil,
                onRetry: {
                    viewModel.errorMessage = nil
                    Task { await viewModel.analyze() }
                },
                onDismiss: {
                    viewModel.errorMessage = nil
                    viewModel.reset()
                }
            )
            .presentationDetents([.medium])
        }
        .onAppear {
            viewModel.updateService(settings.makeBriefingService())
            viewModel.defaultAircraftType = settings.defaultAircraftType
        }
        .onChange(of: settings.backendURLString) { _, _ in
            viewModel.updateService(settings.makeBriefingService())
        }
        .onChange(of: settings.defaultAircraftType) { _, newValue in
            viewModel.defaultAircraftType = newValue
        }
    }

    private func syncWindLimits() {
        viewModel.windLimits = WindLimits(
            maxHeadwind:  settings.maxHeadwind,
            maxCrosswind: settings.maxCrosswind,
            maxTailwind:  settings.maxTailwind
        )
    }

    @ViewBuilder
    private var stepContent: some View {
        ZStack {
            switch viewModel.step {
            case .upload:
                UploadBriefingView(viewModel: viewModel)
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case .detectingType:
                AnalyzingView(aircraftType: nil, statusText: "Detecting aircraft type…")
                    .transition(.opacity)
            case .selectAircraft:
                AircraftSelectionView(viewModel: viewModel)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .analyzing:
                AnalyzingView(aircraftType: viewModel.selectedAircraft)
                    .transition(.opacity)
            case .result:
                if let briefing = viewModel.briefing {
                    BriefingResultView(viewModel: viewModel, briefing: briefing)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .opacity
                        ))
                } else {
                    AnalyzingView(aircraftType: viewModel.selectedAircraft)
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.step)
    }
}

// MARK: - Error Sheet

private struct ErrorSheet: View {
    let message: String
    let canRetry: Bool
    let onRetry: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.12))
                    .frame(width: 72, height: 72)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.red)
            }

            VStack(spacing: 8) {
                Text("Analysis Failed")
                    .font(.title3.bold())
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            VStack(spacing: 12) {
                if canRetry {
                    Button(action: onRetry) {
                        Label("Try Again", systemImage: "arrow.clockwise")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                Button(action: onDismiss) {
                    Text("Start Over")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .padding()
    }
}
