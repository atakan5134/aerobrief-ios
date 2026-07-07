import SwiftUI

struct RouteSummaryView: View {
    let flightPlan: FlightPlan

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Route string card
                if let route = flightPlan.route {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Full Route", systemImage: "map")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)
                        Text(route)
                            .font(.system(.footnote, design: .monospaced))
                            .textSelection(.enabled)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                // Waypoints
                if !flightPlan.waypoints.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Waypoints (\(flightPlan.waypoints.count))", systemImage: "mappin.and.ellipse")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)
                        WaypointTrack(waypoints: flightPlan.waypoints)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                // FIRs
                if !flightPlan.firs.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("FIRs Crossed", systemImage: "globe.europe.africa")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)
                        FlexWrap(items: flightPlan.firs) { fir in
                            Text(fir)
                                .font(.caption.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.blue.opacity(0.12))
                                .foregroundColor(.blue)
                                .clipShape(Capsule())
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                // Airways
                if !flightPlan.airways.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Airways", systemImage: "arrow.triangle.swap")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)
                        Text(flightPlan.airways.joined(separator: "  ·  "))
                            .font(.footnote)
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                // Fuel
                FuelCard(fuelSummary: flightPlan.fuelSummary)
            }
            .padding()
        }
        .navigationTitle("Route & Fuel")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Waypoint track
private struct WaypointTrack: View {
    let waypoints: [String]
    private let columns = [GridItem(.adaptive(minimum: 70), spacing: 6)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 6) {
            ForEach(Array(waypoints.enumerated()), id: \.offset) { idx, wp in
                HStack(spacing: 3) {
                    if idx > 0 {
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Text(wp)
                        .font(.system(.caption, design: .monospaced).bold())
                        .foregroundColor(idx == 0 || idx == waypoints.count - 1 ? .accentColor : .primary)
                }
            }
        }
    }
}

// MARK: - Fuel card
private struct FuelCard: View {
    let fuelSummary: FuelSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Fuel Summary (\(fuelSummary.unit))", systemImage: "fuelpump.fill")
                .font(.subheadline.bold())
                .foregroundColor(.secondary)

            VStack(spacing: 0) {
                fuelRow("Block Fuel", fuelSummary.blockFuel, isHighlight: true)
                Divider().padding(.leading)
                fuelRow("Trip Fuel", fuelSummary.tripFuel)
                Divider().padding(.leading)
                fuelRow("Contingency", fuelSummary.contingencyFuel)
                Divider().padding(.leading)
                fuelRow("Alternate", fuelSummary.alternateFuel)
                Divider().padding(.leading)
                fuelRow("Final Reserve", fuelSummary.finalReserveFuel)
            }
            .background(Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func fuelRow(_ label: String, _ value: Double?, isHighlight: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(isHighlight ? .subheadline.bold() : .subheadline)
                .foregroundColor(isHighlight ? .primary : .secondary)
            Spacer()
            Text(value.map { "\(Int($0))" } ?? "—")
                .font(isHighlight ? .title3.bold() : .subheadline)
                .foregroundColor(isHighlight ? .accentColor : .primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

// MARK: - Simple flow wrap (reusable)
private struct FlexWrap<Item: Hashable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content

    var body: some View {
        // Simple wrapping using VStack + HStack approach
        let rows = buildRows()
        VStack(alignment: .leading, spacing: 6) {
            ForEach(rows.indices, id: \.self) { i in
                HStack(spacing: 6) {
                    ForEach(rows[i], id: \.self) { item in
                        content(item)
                    }
                }
            }
        }
    }

    private func buildRows() -> [[Item]] {
        var rows: [[Item]] = [[]]
        var current = 0
        let perRow = 4
        for (i, item) in items.enumerated() {
            if i > 0 && i % perRow == 0 {
                rows.append([])
                current += 1
            }
            rows[current].append(item)
        }
        return rows
    }
}
