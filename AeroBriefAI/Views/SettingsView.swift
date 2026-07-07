import SwiftUI

private struct WindLimitRow: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let unit: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.subheadline)
                Spacer()
                Text("\(value) \(unit)")
                    .font(.subheadline.monospacedDigit())
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                    .frame(minWidth: 52, alignment: .trailing)
            }
            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { value = Int($0.rounded()) }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: 1
            )
            .tint(color)
        }
        .padding(.vertical, 4)
    }
}

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var avwxKeyVisible = false

    var body: some View {
        Form {
            // MARK: Backend
            Section {
                TextField("Backend URL", text: $settings.backendURLString)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
            } header: {
                Text("Backend")
            } footer: {
                Text("Default: aerobrief-backend-production.up.railway.app — change only if you're running your own backend.")
                    .font(.caption)
            }

            // MARK: D-ATIS / Weather
            Section {
                HStack {
                    if avwxKeyVisible {
                        TextField("AVWX API Key", text: $settings.avwxApiKey)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    } else {
                        SecureField("AVWX API Key", text: $settings.avwxApiKey)
                            .autocorrectionDisabled()
                    }
                    Button {
                        avwxKeyVisible.toggle()
                    } label: {
                        Image(systemName: avwxKeyVisible ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                if settings.avwxApiKey.isEmpty {
                    Link("Get a free AVWX API key →", destination: URL(string: "https://avwx.rest/account/create")!)
                        .font(.caption)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                        Text("D-ATIS live fetch enabled").font(.caption).foregroundColor(.green)
                    }
                }
            } header: {
                Text("D-ATIS (avwx.rest)")
            } footer: {
                Text("Enter your free AVWX token to enable live D-ATIS. Without a key, mock data is used. METAR/TAF always fetched live from aviationweather.gov (no key needed).")
                    .font(.caption)
            }

            // MARK: Defaults
            Section("Defaults") {
                Picker("Fallback Aircraft Type", selection: $settings.defaultAircraftType) {
                    ForEach(AircraftType.allCases) { type in
                        Text("\(type.rawValue) — \(type.displayName)").tag(type)
                    }
                }
            }

            // MARK: Wind Limits
            Section {
                WindLimitRow(
                    label: "Max Headwind",
                    value: $settings.maxHeadwind,
                    range: 20...80,
                    unit: "kt",
                    color: .blue
                )
                WindLimitRow(
                    label: "Max Crosswind",
                    value: $settings.maxCrosswind,
                    range: 10...50,
                    unit: "kt",
                    color: .orange
                )
                WindLimitRow(
                    label: "Max Tailwind",
                    value: $settings.maxTailwind,
                    range: 5...25,
                    unit: "kt",
                    color: .red
                )
            } header: {
                Text("Wind Limits")
            } footer: {
                Text("Applied to all runway wind component calculations. Warnings are generated when actual wind exceeds these values.")
                    .font(.caption)
            }

            // MARK: Disclaimer
            Section {
                Text("AeroBrief AI assists pilots in reviewing briefings. It does not replace official dispatch, EFB, Jeppesen, Lido, or company systems.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Settings")
    }
}
