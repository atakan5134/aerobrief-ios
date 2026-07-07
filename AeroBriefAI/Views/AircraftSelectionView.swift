import SwiftUI

struct AircraftSelectionView: View {
    @ObservedObject var viewModel: BriefingFlowViewModel

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Select Aircraft Type")
                    .font(.title2.bold())
                    .padding(.horizontal)

                if let fileName = viewModel.selectedPDFName {
                    Label(fileName, systemImage: "doc.fill")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }

                // Auto-detect result banner
                if let detected = viewModel.detectedAircraft {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Auto-detected: \(detected.rawValue)")
                                .font(.subheadline.bold())
                            Text("Tap to confirm, or choose a different type below.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button {
                            viewModel.selectAircraft(detected)
                        } label: {
                            Text("Confirm")
                                .font(.subheadline.bold())
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                } else {
                    Text("Could not detect aircraft type automatically. Please select one:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(AircraftType.allCases) { type in
                        Button {
                            viewModel.selectAircraft(type)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(type.rawValue)
                                        .font(.headline)
                                    if type == viewModel.detectedAircraft {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.caption)
                                    }
                                }
                                Text(type.displayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(type.category)
                                    .font(.caption2)
                                    .foregroundColor(.accentColor)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(
                                type == viewModel.detectedAircraft
                                    ? Color.green.opacity(0.12)
                                    : Color(.secondarySystemBackground)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(type == viewModel.detectedAircraft ? Color.green : Color.clear, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Aircraft Type")
    }
}
