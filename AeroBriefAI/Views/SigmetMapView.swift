import SwiftUI
import MapKit

/// Shows SIGMETs relevant to the flight's route on a map, each annotated
/// with the estimated flight-hour at which the aircraft is expected to be
/// inside that FIR (derived from the OFP's EET field on the backend).
struct SigmetMapView: View {
    let sigmets: [Sigmet]
    /// The flight's actual route, when the OFP had a detailed waypoint
    /// table (see backend's ofp_route_table.py). Empty for OFP formats
    /// without that table — the SIGMET areas still render without it.
    var routePoints: [RoutePoint] = []

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedSigmetID: String?

    var body: some View {
        Group {
            if sigmets.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    map
                        .frame(height: 300)
                    Divider()
                    list
                }
            }
        }
        .navigationTitle("SIGMETs on Route")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { fitAll() }
    }

    // MARK: - Map

    private var routeCoordinates: [CLLocationCoordinate2D] {
        routePoints.map { CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lon) }
    }

    private var map: some View {
        Map(position: $cameraPosition, selection: $selectedSigmetID) {
            if routeCoordinates.count >= 2 {
                MapPolyline(coordinates: routeCoordinates)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [1, 6]))
            }

            ForEach(sigmets) { sigmet in
                let coords = sigmet.polygon.map {
                    CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lon)
                }
                if coords.count >= 3 {
                    MapPolygon(coordinates: coords)
                        .foregroundStyle(color(for: sigmet).opacity(selectedSigmetID == sigmet.id ? 0.45 : 0.22))
                        .stroke(color(for: sigmet), lineWidth: selectedSigmetID == sigmet.id ? 3 : 2)

                    if let centroid = centroid(of: coords) {
                        Annotation(sigmet.phenomenon, coordinate: centroid) {
                            annotationBadge(for: sigmet)
                        }
                        .tag(sigmet.id)
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
    }

    private func annotationBadge(for sigmet: Sigmet) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon(for: sigmet))
                .font(.caption)
                .foregroundColor(.white)
                .padding(7)
                .background(color(for: sigmet))
                .clipShape(Circle())
                .overlay(Circle().stroke(.white, lineWidth: 1.5))
            if let eta = sigmet.estimatedFlightTime {
                Text("+\(eta)")
                    .font(.caption2.bold())
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(.thinMaterial)
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - List

    private var list: some View {
        List {
            Section {
                ForEach(sigmets) { sigmet in
                    SigmetRow(sigmet: sigmet)
                        .contentShape(Rectangle())
                        .onTapGesture { focus(on: sigmet) }
                        .listRowBackground(
                            selectedSigmetID == sigmet.id ? Color.accentColor.opacity(0.12) : nil
                        )
                }
            } footer: {
                Text("Estimated flight-hour timing requires an OFP with an EET field. When unavailable, SIGMETs are still shown because their FIR is on the route, but timing can't be confirmed.")
            }
        }
        .listStyle(.plain)
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No SIGMETs on Route",
            systemImage: "checkmark.circle",
            description: Text("No significant meteorological reports were found for the FIRs along this route.")
        )
    }

    // MARK: - Helpers

    private func color(for sigmet: Sigmet) -> Color {
        if sigmet.timeOverlap == true { return .red }
        if sigmet.timeOverlap == false { return .gray }
        return .orange
    }

    private func icon(for sigmet: Sigmet) -> String {
        let hazard = sigmet.hazard.uppercased()
        if hazard.contains("VA") || hazard.contains("VOLCAN") { return "mountain.2.fill" }
        if hazard.contains("TS") { return "cloud.bolt.fill" }
        if hazard.contains("ICE") || hazard.contains("ICING") { return "snowflake" }
        if hazard.contains("TURB") { return "wind" }
        return "exclamationmark.triangle.fill"
    }

    private func centroid(of coords: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D? {
        guard !coords.isEmpty else { return nil }
        let lat = coords.map(\.latitude).reduce(0, +) / Double(coords.count)
        let lon = coords.map(\.longitude).reduce(0, +) / Double(coords.count)
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    private func fitAll() {
        // Prefer the full route (it's the more complete picture) when
        // available; fall back to just the SIGMET polygons otherwise.
        let sigmetCoords = sigmets.flatMap { $0.polygon }.map {
            CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lon)
        }
        let allCoords = routeCoordinates.isEmpty ? sigmetCoords : routeCoordinates + sigmetCoords
        guard let region = boundingRegion(for: allCoords) else { return }
        cameraPosition = .region(region)
    }

    private func focus(on sigmet: Sigmet) {
        selectedSigmetID = sigmet.id
        let coords = sigmet.polygon.map { CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lon) }
        if let region = boundingRegion(for: coords) {
            withAnimation { cameraPosition = .region(region) }
        }
    }

    private func boundingRegion(for coords: [CLLocationCoordinate2D]) -> MKCoordinateRegion? {
        guard !coords.isEmpty else { return nil }
        let lats = coords.map(\.latitude)
        let lons = coords.map(\.longitude)
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max() else { return nil }
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.6, 2.0),
            longitudeDelta: max((maxLon - minLon) * 1.6, 2.0)
        )
        return MKCoordinateRegion(center: center, span: span)
    }
}

// MARK: - Row

private struct SigmetRow: View {
    let sigmet: Sigmet

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(sigmet.phenomenon).font(.subheadline.bold())
                Spacer()
                statusBadge
            }
            HStack(spacing: 10) {
                Label(sigmet.fir, systemImage: "square.grid.2x2")
                if let base = sigmet.baseFt, let top = sigmet.topFt {
                    Label("FL\(Int(base / 100))–FL\(Int(top / 100))", systemImage: "arrow.up.arrow.down")
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)

            if let eta = sigmet.estimatedFlightTime {
                Text("Aircraft estimated in this FIR at +\(eta) after departure")
                    .font(.caption)
                    .foregroundColor(sigmet.timeOverlap == true ? .red : .secondary)
            }

            if sigmet.locationConfirmed == true {
                Label("Route track crosses this exact area", systemImage: "checkmark.seal.fill")
                    .font(.caption2.bold())
                    .foregroundColor(.red)
            }

            Text(sigmet.rawText)
                .font(.caption2.monospaced())
                .foregroundColor(.secondary)
                .lineLimit(3)
        }
        .padding(.vertical, 4)
    }

    private var statusBadge: some View {
        Group {
            if sigmet.timeOverlap == true {
                Text("ON ROUTE").font(.caption2.bold()).foregroundColor(.white)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.red).clipShape(Capsule())
            } else if sigmet.timeOverlap == false {
                Text("TIMING CLEAR").font(.caption2.bold()).foregroundColor(.secondary)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color(.tertiarySystemBackground)).clipShape(Capsule())
            } else {
                Text("FIR ON ROUTE").font(.caption2.bold()).foregroundColor(.white)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.orange).clipShape(Capsule())
            }
        }
    }
}
