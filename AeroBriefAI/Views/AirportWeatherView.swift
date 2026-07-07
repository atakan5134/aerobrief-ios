import SwiftUI

struct AirportWeatherView: View {
    let weather: [String: AirportWeather]
    let atis: [AtisReport]

    var body: some View {
        List {
            ForEach(weather.keys.sorted(), id: \.self) { airport in
                if let bundle = weather[airport] {
                    Section {
                        MetarCard(metar: bundle.metar)
                        TafCard(taf: bundle.taf)
                        if let report = atis.first(where: { $0.airport == airport }) {
                            AtisCard(report: report)
                        }
                    } header: {
                        HStack {
                            Image(systemName: "mappin.and.ellipse").foregroundColor(.accentColor)
                            Text(airport).font(.headline)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Weather")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - METAR Card
private struct MetarCard: View {
    let metar: Metar
    @State private var showRaw = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("METAR", systemImage: "thermometer.and.liquid.waves")
                    .font(.caption.bold()).foregroundColor(.cyan)
                Spacer()
                Text(metar.observedAt.prefix(16)).font(.caption2).foregroundColor(.secondary)
            }

            // Parsed chips
            let tokens = MetarParser.parse(metar.rawText)
            FlowLayout(spacing: 6) {
                ForEach(tokens) { token in
                    WeatherTokenChip(token: token)
                }
            }

            // Raw toggle
            Button { withAnimation { showRaw.toggle() } } label: {
                Label(showRaw ? "Hide raw" : "Show raw METAR", systemImage: "text.alignleft")
                    .font(.caption2).foregroundColor(.secondary)
            }
            if showRaw {
                Text(metar.rawText)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.secondary)
                    .transition(.opacity)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - TAF Card
private struct TafCard: View {
    let taf: Taf
    @State private var showRaw = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("TAF", systemImage: "calendar.badge.clock").font(.caption.bold()).foregroundColor(.blue)
                Spacer()
                Text("Valid \(taf.validFrom.prefix(10)) → \(taf.validTo.prefix(10))")
                    .font(.caption2).foregroundColor(.secondary)
            }
            Button { withAnimation { showRaw.toggle() } } label: {
                Label(showRaw ? "Hide raw" : "Show TAF", systemImage: "text.alignleft")
                    .font(.caption2).foregroundColor(.secondary)
            }
            if showRaw {
                Text(taf.rawText)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.secondary)
                    .transition(.opacity)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - D-ATIS Card
private struct AtisCard: View {
    let report: AtisReport
    @State private var showRaw = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("D-ATIS", systemImage: "waveform").font(.caption.bold()).foregroundColor(.purple)
                Text("Info \(report.letter)").font(.caption.bold())
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.purple.opacity(0.15)).clipShape(Capsule())
                Spacer()
                Text(report.issuedAt.prefix(16)).font(.caption2).foregroundColor(.secondary)
            }
            Button { withAnimation { showRaw.toggle() } } label: {
                Label(showRaw ? "Hide raw" : "Show ATIS text", systemImage: "text.alignleft")
                    .font(.caption2).foregroundColor(.secondary)
            }
            if showRaw {
                Text(report.rawText)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.secondary)
                    .transition(.opacity)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - METAR Parser
struct MetarToken: Identifiable {
    let id = UUID()
    let label: String
    let value: String
    let color: Color
}

enum MetarParser {
    static func parse(_ raw: String) -> [MetarToken] {
        var tokens: [MetarToken] = []
        let text = raw.uppercased()

        // Wind
        if let m = text.range(of: #"\d{3}\d{2}(G\d{2,3})?KT"#, options: .regularExpression) {
            tokens.append(.init(label: "Wind", value: String(text[m]), color: .blue))
        }
        // Visibility
        if let m = text.range(of: #"\b\d{4}\b"#, options: .regularExpression) {
            let vis = String(text[m])
            let n = Int(vis) ?? 9999
            tokens.append(.init(label: "Vis", value: "\(vis)m", color: n < 1500 ? .red : n < 5000 ? .orange : .green))
        }
        // Phenomena
        let phenomena: [(String, String, Color)] = [
            ("TSRA", "TSRA", .red), ("TS", "TS", .red), ("+RA", "+RA", .orange),
            ("-RA", "-RA", .blue), ("RA", "RA", .blue), ("SN", "SN", .cyan),
            ("FZRA", "FZRA", .red), ("FG", "FG", .orange), ("BR", "BR", .yellow),
            ("CB", "CB", .red), ("TEMPO", "TEMPO", .orange)
        ]
        for (key, label, color) in phenomena where text.contains(key) {
            tokens.append(.init(label: label, value: "", color: color))
        }
        // Ceiling
        if let m = text.range(of: #"(BKN|OVC)\d{3}"#, options: .regularExpression) {
            let s = String(text[m])
            let ft = (Int(s.dropFirst(3)) ?? 0) * 100
            tokens.append(.init(label: "Ceil", value: "\(ft)ft", color: ft < 500 ? .red : ft < 1500 ? .orange : .green))
        }
        // QNH
        if let m = text.range(of: #"Q\d{4}"#, options: .regularExpression) {
            tokens.append(.init(label: "QNH", value: String(text[m].dropFirst()), color: .primary))
        }

        return tokens.isEmpty ? [MetarToken(label: "METAR", value: raw, color: .secondary)] : tokens
    }
}

private struct WeatherTokenChip: View {
    let token: MetarToken
    var body: some View {
        HStack(spacing: 3) {
            Text(token.label).font(.caption2).foregroundColor(.secondary)
            if !token.value.isEmpty {
                Text(token.value).font(.caption.bold()).foregroundColor(token.color)
            } else {
                Circle().fill(token.color).frame(width: 6, height: 6)
                Text(token.label).font(.caption.bold()).foregroundColor(token.color)
            }
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(token.color.opacity(0.08))
        .clipShape(Capsule())
    }
}

// MARK: - Flow Layout (wrapping HStack)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0, maxY: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 { y += rowH + spacing; x = 0; rowH = 0 }
            rowH = max(rowH, size.height)
            x += size.width + spacing
            maxY = y + rowH
        }
        return CGSize(width: width, height: maxY)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX { y += rowH + spacing; x = bounds.minX; rowH = 0 }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            rowH = max(rowH, size.height); x += size.width + spacing
        }
    }
}
