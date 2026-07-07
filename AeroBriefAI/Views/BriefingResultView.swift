import SwiftUI

struct BriefingResultView: View {
    @ObservedObject var viewModel: BriefingFlowViewModel
    let briefing: Briefing

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                flightHeroCard
                riskScoreCard
                warningCountRow
                navigationCards
                remarksSection
            }
            .padding()
        }
        .navigationTitle(briefing.flightPlan.flightNumber ?? "Briefing")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("New Briefing") { viewModel.reset() }
            }
        }
    }

    // MARK: - Hero
    private var flightHeroCard: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center) {
                VStack(spacing: 2) {
                    Text(briefing.flightPlan.departureAirport ?? "???")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Text(briefing.flightPlan.estimatedDepartureTime ?? "--")
                        .font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                VStack(spacing: 4) {
                    Image(systemName: "airplane").font(.title2).foregroundColor(.accentColor)
                    Text(briefing.flightPlan.flightNumber ?? "").font(.caption.bold())
                    if let fl = briefing.flightPlan.flightLevel {
                        Text("FL\(fl)").font(.caption2).foregroundColor(.secondary)
                    }
                }
                Spacer()
                VStack(spacing: 2) {
                    Text(briefing.flightPlan.destinationAirport ?? "???")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Text(briefing.flightPlan.estimatedArrivalTime ?? "--")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            Divider()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    InfoChip(icon: "airplane.circle", label: briefing.selectedAircraftType)
                    if let reg = briefing.flightPlan.aircraftRegistration {
                        InfoChip(icon: "tag", label: reg)
                    }
                    if let cs = briefing.flightPlan.callsign {
                        InfoChip(icon: "radio", label: cs)
                    }
                    ForEach(briefing.flightPlan.alternateAirports, id: \.self) { alt in
                        InfoChip(icon: "arrow.triangle.2.circlepath", label: "ALTN: \(alt)")
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Risk Ring
    private var riskScoreCard: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle().stroke(riskColor.opacity(0.2), lineWidth: 10).frame(width: 80, height: 80)
                Circle()
                    .trim(from: 0, to: CGFloat(briefing.riskScore) / 100)
                    .stroke(riskColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.8), value: briefing.riskScore)
                VStack(spacing: 1) {
                    Text("\(briefing.riskScore)").font(.title2.bold()).foregroundColor(riskColor)
                    Text("/100").font(.caption2).foregroundColor(.secondary)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Risk Score").font(.headline)
                Text(riskLabel).font(.subheadline).foregroundColor(riskColor)
                Text("\(briefing.warnings.count) warning\(briefing.warnings.count == 1 ? "" : "s") identified")
                    .font(.caption).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Severity Count Row
    private var warningCountRow: some View {
        let counts = Dictionary(grouping: briefing.warnings, by: \.severity)
        return HStack(spacing: 8) {
            ForEach([WarningSeverity.critical, .important, .review, .info], id: \.self) { sev in
                let n = counts[sev]?.count ?? 0
                VStack(spacing: 4) {
                    Text("\(n)").font(.title3.bold()).foregroundColor(n > 0 ? sev.color : .secondary)
                    Text(sev.rawValue.prefix(4).capitalized).font(.caption2).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 10)
                .background(n > 0 ? sev.color.opacity(0.1) : Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(n > 0 ? sev.color.opacity(0.4) : Color.clear, lineWidth: 1))
            }
        }
    }

    // MARK: - Nav Cards
    private var navigationCards: some View {
        VStack(spacing: 10) {
            NavCard(title: "Warning Dashboard",
                    subtitle: "\(briefing.warnings.count) warnings · score \(briefing.riskScore)",
                    icon: "exclamationmark.triangle.fill", color: riskColor) {
                WarningDashboardView(briefing: briefing)
            }
            NavCard(title: "Airport Weather",
                    subtitle: "\(briefing.weather.count) airport(s) — METAR · TAF · D-ATIS",
                    icon: "cloud.sun.rain", color: .cyan) {
                AirportWeatherView(weather: briefing.weather, atis: briefing.atis)
            }
            NavCard(title: "NOTAMs",
                    subtitle: "\(briefing.notams.flatMap(\.notams).count) NOTAM(s) · \(briefing.notams.count) airport(s)",
                    icon: "doc.text.magnifyingglass", color: .purple) {
                NotamListView(notamGroups: briefing.notams,
                             aircraftType: briefing.selectedAircraftType)
            }
            NavCard(title: "Route Summary",
                    subtitle: "\(briefing.flightPlan.waypoints.count) waypoints · \(briefing.flightPlan.airways.count) airways",
                    icon: "point.3.connected.trianglepath.dotted", color: .green) {
                RouteSummaryView(flightPlan: briefing.flightPlan)
            }
            if !briefing.sigmets.isEmpty {
                NavCard(title: "SIGMETs on Route",
                        subtitle: sigmetSubtitle,
                        icon: "cloud.bolt.rain.fill", color: .red) {
                    SigmetMapView(sigmets: briefing.sigmets, routePoints: briefing.flightPlan.routePoints)
                }
            }
        }
    }

    private var sigmetSubtitle: String {
        let confirmed = briefing.sigmets.filter { $0.timeOverlap == true }.count
        if confirmed > 0 {
            return "\(confirmed) confirmed on this flight's timing · \(briefing.sigmets.count) total"
        }
        return "\(briefing.sigmets.count) report(s) in route FIRs"
    }

    // MARK: - Remarks
    private var remarksSection: some View {
        VStack(spacing: 10) {
            if !briefing.flightPlan.dispatcherRemarks.isEmpty {
                RemarkCard(title: "Dispatcher Remarks", icon: "person.text.rectangle",
                           items: briefing.flightPlan.dispatcherRemarks, color: .orange)
            }
            if !briefing.flightPlan.operationalRemarks.isEmpty {
                RemarkCard(title: "Operational Remarks", icon: "list.clipboard",
                           items: briefing.flightPlan.operationalRemarks, color: .blue)
            }
            if !briefing.flightPlan.melCdlRemarks.isEmpty {
                RemarkCard(title: "MEL / CDL", icon: "wrench.and.screwdriver",
                           items: briefing.flightPlan.melCdlRemarks, color: .red)
            }
        }
    }

    private var riskColor: Color {
        switch briefing.riskScore {
        case 60...: return .red
        case 30..<60: return .orange
        default: return .green
        }
    }
    private var riskLabel: String {
        switch briefing.riskScore {
        case 75...: return "HIGH RISK — Review all items"
        case 50..<75: return "ELEVATED — Check criticals"
        case 25..<50: return "MODERATE — Items need attention"
        default: return "LOW — Routine review"
        }
    }
}

// MARK: - Reusable chips & cards (used across views)
struct InfoChip: View {
    let icon: String; let label: String
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.caption2)
            Text(label).font(.caption.bold())
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(Color(.tertiarySystemBackground)).clipShape(Capsule())
        .foregroundColor(.secondary)
    }
}

struct NavCard<D: View>: View {
    let title: String; let subtitle: String; let icon: String; let color: Color
    @ViewBuilder let destination: () -> D
    var body: some View {
        NavigationLink(destination: destination()) {
            HStack(spacing: 14) {
                Image(systemName: icon).font(.title2).foregroundColor(color).frame(width: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline).foregroundColor(.primary)
                    Text(subtitle).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

struct RemarkCard: View {
    let title: String; let icon: String; let items: [String]; let color: Color
    @State private var expanded = false
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button { withAnimation { expanded.toggle() } } label: {
                HStack {
                    Label(title, systemImage: icon).font(.subheadline.bold()).foregroundColor(color)
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary).font(.caption)
                }
                .padding()
            }
            if expanded {
                Divider().padding(.horizontal)
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(items, id: \.self) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•").foregroundColor(color)
                            Text(item).font(.footnote)
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
