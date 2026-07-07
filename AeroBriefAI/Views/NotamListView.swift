import SwiftUI

// MARK: - Filter mode

enum NotamFilter: String, CaseIterable, Identifiable {
    case relevant  = "Aircraft-relevant"
    case critical  = "Critical"
    case important = "Important"
    case all       = "All"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .relevant:  return "airplane.circle.fill"
        case .critical:  return "exclamationmark.triangle.fill"
        case .important: return "exclamationmark.circle.fill"
        case .all:       return "list.bullet"
        }
    }
}

// MARK: - Main view

struct NotamListView: View {
    let notamGroups: [AirportNotams]
    let aircraftType: String?           // e.g. "B777" — shown in header

    @State private var filter: NotamFilter = .relevant
    @State private var searchText = ""

    // Counts for filter chips
    private var criticalCount: Int {
        notamGroups.flatMap(\.notams).filter { $0.aircraftRelevance == "CRITICAL" }.count
    }
    private var importantCount: Int {
        notamGroups.flatMap(\.notams).filter { $0.aircraftRelevance == "IMPORTANT" }.count
    }
    private var relevantCount: Int {
        notamGroups.flatMap(\.notams).filter {
            let r = $0.aircraftRelevance ?? ""
            return r == "CRITICAL" || r == "IMPORTANT" || r == "REVIEW"
        }.count
    }
    private var totalCount: Int {
        notamGroups.flatMap(\.notams).count
    }

    private var filtered: [AirportNotams] {
        notamGroups.compactMap { group in
            var notams = group.notams

            // Apply relevance filter
            switch filter {
            case .relevant:
                notams = notams.filter {
                    let r = $0.aircraftRelevance ?? "INFO"
                    return r == "CRITICAL" || r == "IMPORTANT" || r == "REVIEW"
                }
            case .critical:
                notams = notams.filter { $0.aircraftRelevance == "CRITICAL" }
            case .important:
                notams = notams.filter {
                    $0.aircraftRelevance == "CRITICAL" || $0.aircraftRelevance == "IMPORTANT"
                }
            case .all:
                break
            }

            // Apply search
            if !searchText.isEmpty {
                notams = notams.filter { $0.rawText.localizedCaseInsensitiveContains(searchText) }
            }

            guard !notams.isEmpty else { return nil }
            return AirportNotams(airport: group.airport, notams: notams)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Aircraft relevance header bar
            if let ac = aircraftType {
                relevanceHeader(ac: ac)
            }

            // Filter chips
            filterBar

            // NOTAM list
            List {
                ForEach(filtered, id: \.airport) { group in
                    Section {
                        ForEach(group.notams) { notam in
                            NotamRow(notam: notam, showRelevanceBadge: filter == .all)
                        }
                    } header: {
                        airportHeader(group: group)
                    }
                }

                if filtered.isEmpty {
                    emptyState
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle("NOTAMs")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search NOTAMs…")
    }

    // MARK: Sub-views

    private func relevanceHeader(ac: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "airplane.circle.fill")
                .foregroundColor(.accentColor)
            Text("\(ac)-relevant NOTAMs: \(relevantCount) of \(totalCount)")
                .font(.subheadline.bold())
            Spacer()
            if criticalCount > 0 {
                Text("\(criticalCount) CRITICAL")
                    .font(.caption.bold())
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground))
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(NotamFilter.allCases) { f in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) { filter = f }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: f.systemImage).font(.caption)
                            Text(f.rawValue).font(.subheadline)
                            Text(countLabel(f))
                                .font(.caption.bold())
                                .padding(.horizontal, 5).padding(.vertical, 1)
                                .background(filter == f ? Color.white.opacity(0.25) : Color(.tertiarySystemBackground))
                                .clipShape(Capsule())
                        }
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(filter == f ? Color.accentColor : Color(.secondarySystemBackground))
                        .foregroundColor(filter == f ? .white : .primary)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }

    private func countLabel(_ f: NotamFilter) -> String {
        switch f {
        case .relevant:  return "\(relevantCount)"
        case .critical:  return "\(criticalCount)"
        case .important: return "\(criticalCount + importantCount)"
        case .all:       return "\(totalCount)"
        }
    }

    private func airportHeader(group: AirportNotams) -> some View {
        let critCount = group.notams.filter { $0.aircraftRelevance == "CRITICAL" }.count
        let impCount  = group.notams.filter { $0.aircraftRelevance == "IMPORTANT" }.count
        return HStack(spacing: 6) {
            Image(systemName: "mappin.and.ellipse").foregroundColor(.purple)
            Text(group.airport).font(.headline)
            Spacer()
            if critCount > 0 {
                Text("\(critCount)✕").font(.caption.bold()).foregroundColor(.red)
            }
            if impCount > 0 {
                Text("\(impCount)✕").font(.caption.bold()).foregroundColor(.orange)
            }
            Text("\(group.notams.count)").font(.caption).foregroundColor(.secondary)
        }
    }

    private var emptyState: some View {
        Section {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.shield")
                    .font(.largeTitle).foregroundColor(.green)
                Text("No NOTAMs match this filter")
                    .font(.headline)
                Text("Try 'All' to see every NOTAM in the plan.")
                    .font(.subheadline).foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
        }
    }
}

// MARK: - NOTAM Row

private struct NotamRow: View {
    let notam: Notam
    let showRelevanceBadge: Bool
    @State private var expanded = false

    private var relevanceColor: Color {
        switch notam.aircraftRelevance {
        case "CRITICAL":   return .red
        case "IMPORTANT":  return .orange
        case "REVIEW":     return .yellow
        case "NOT_RELEVANT": return Color(.systemGray4)
        default:           return .accentColor
        }
    }

    private var relevanceSeverity: WarningSeverity {
        switch notam.aircraftRelevance {
        case "CRITICAL":  return .critical
        case "IMPORTANT": return .important
        case "REVIEW":    return .review
        default:          return .info
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Colored left border strip
            HStack(alignment: .top, spacing: 10) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(relevanceColor)
                    .frame(width: 3)
                    .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 5) {
                    // Header row
                    HStack(alignment: .top) {
                        Text(notam.id)
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                        Spacer(minLength: 6)
                        SeverityBadge(severity: relevanceSeverity)
                    }

                    // NOTAM text
                    Text(notam.rawText)
                        .font(.subheadline)
                        .lineLimit(expanded ? nil : 2)
                        .fixedSize(horizontal: false, vertical: expanded)

                    // Relevance reason chip
                    if let reason = notam.relevanceReason,
                       notam.aircraftRelevance != "NOT_RELEVANT" {
                        HStack(spacing: 4) {
                            Image(systemName: "airplane").font(.caption2)
                            Text(reason)
                                .font(.caption2)
                                .lineLimit(2)
                        }
                        .foregroundColor(relevanceColor)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(relevanceColor.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }

                    // Expanded: validity
                    if expanded {
                        HStack(spacing: 12) {
                            if !notam.effectiveFrom.isEmpty {
                                Label(String(notam.effectiveFrom.prefix(10)), systemImage: "calendar")
                            }
                            if !notam.effectiveTo.isEmpty {
                                Label(String(notam.effectiveTo.prefix(10)), systemImage: "calendar.badge.checkmark")
                            }
                            if let fir = notam.fir, !fir.isEmpty {
                                Label(fir, systemImage: "globe")
                            }
                        }
                        .font(.caption2).foregroundColor(.secondary)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
            .padding(.vertical, 6)
        }
        .contentShape(Rectangle())
        .onTapGesture { withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() } }
        // Dim NOT_RELEVANT rows slightly
        .opacity(notam.aircraftRelevance == "NOT_RELEVANT" ? 0.45 : 1.0)
    }
}

// MARK: - Legacy severity estimator (kept for fallback)

enum NotamSeverityEstimator {
    static func estimate(_ text: String) -> WarningSeverity {
        let t = text.uppercased()
        if t.contains("CLSD") || t.contains("CLOSED") || t.contains("RFFS") ||
           t.contains("JAMMING") || t.contains("SPOOFING") || t.contains("FZRA") ||
           t.contains("BRAKING ACTION POOR") { return .critical }
        if t.contains("U/S") || t.contains("NOT AVBL") || t.contains("RVR") ||
           t.contains("CONTAMINATED") || t.contains("SNOWBANK") { return .important }
        if t.contains("RESTRICTED") || t.contains("REDUCED") || t.contains("LIMITED") { return .review }
        return .info
    }
}
