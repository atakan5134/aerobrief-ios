import SwiftUI

struct AnalyzingView: View {
    let aircraftType: AircraftType?
    var statusText: String = "Analyzing briefing..."

    @State private var currentStep = 0

    private let steps: [(String, String)] = [
        ("doc.text.magnifyingglass", "Parsing OFP PDF"),
        ("airplane.circle", "Detecting aircraft type"),
        ("cloud.sun.rain", "Fetching METAR / TAF"),
        ("exclamationmark.triangle", "Processing NOTAMs"),
        ("checkmark.shield", "Generating warnings"),
    ]

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 100, height: 100)
                Image(systemName: "airplane")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundColor(.accentColor)
                    .symbolEffect(.pulse, isActive: true)
            }

            VStack(spacing: 6) {
                Text(statusText)
                    .font(.title3.bold())
                if let ac = aircraftType {
                    Text("Aircraft: \(ac.rawValue)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(steps.enumerated()), id: \.offset) { idx, step in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(stepBackground(idx))
                                .frame(width: 32, height: 32)
                            if idx < currentStep {
                                Image(systemName: "checkmark")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                            } else if idx == currentStep {
                                ProgressView()
                                    .scaleEffect(0.6)
                                    .tint(.white)
                            } else {
                                Image(systemName: step.0)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Text(step.1)
                            .font(.subheadline)
                            .foregroundColor(idx <= currentStep ? .primary : .secondary)
                            .fontWeight(idx == currentStep ? .semibold : .regular)
                        Spacer()
                    }
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
                }
            }
            .padding(20)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 32)

            Spacer()
        }
        .onAppear { startProgress() }
    }

    private func stepBackground(_ idx: Int) -> Color {
        if idx < currentStep { return .green }
        if idx == currentStep { return .accentColor }
        return Color(.systemGray4)
    }

    private func startProgress() {
        let delays: [Double] = [0, 0.7, 1.5, 2.4, 3.4]
        for (idx, delay) in delays.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation { currentStep = idx }
            }
        }
    }
}
