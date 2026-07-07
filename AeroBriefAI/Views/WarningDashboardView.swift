import SwiftUI

struct WarningDashboardView: View {
    let briefing: Briefing
    @State private var selectedSeverity: WarningSeverity?
    @State private var selectedCategory: WarningCategory?

    private var filtered: [BriefingWarning] {
        briefing.warnings
            .filter { selectedSeverity == nil || $0.severity == selectedSeverity }
            .filter { selectedCategory == nil || $0.category == selectedCategory }
            .sorted { $0.severity.sortWeight > $1.severity.sortWeight }
    }

    var body: some View {
        VStack(spacing: 0) {
            summaryHeader
            Divider()
            filterBar
            Divider()

            if filtered.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.shield").font(.largeTitle).foregroundColor(.green)
                    Text("No warnings for selected filter").foregroundColor(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filtered) { warning in
                            WarningCardView(warning: warning)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Warnings")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Summary header
    private var summaryHeader: some View {
        HStack(spacing: 16) {
            // Mini ring
            ZStack {
                Circle().stroke(riskColor.opacity(0.2), lineWidth: 6).frame(width: 52, height: 52)
                Circle()
                    .trim(from: 0, to: CGFloat(briefing.riskScore) / 100)
                    .stroke(riskColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 52, height: 52)
                    .rotationEffect(.degrees(-90))
                Text("\(briefing.riskScore)").font(.subheadline.bold()).foregroundColor(riskColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Risk Score \(briefing.riskScore)/100").font(.headline)
                Text("\(briefing.warnings.count) warnings").font(.caption).foregroundColor(.secondary)
            }

            Spacer()

            // Severity mini bars
            HStack(spacing: 6) {
                ForEach([WarningSeverity.critical, .important, .review, .info], id: \.self) { sev in
                    let n = briefing.warnings.filter { $0.severity == sev }.count
                    VStack(spacing: 2) {
                        Text("\(n)").font(.caption.bold()).foregroundColor(sev.color)
                        Text(String(sev.rawValue.prefix(1))).font(.caption2).foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
    }

    // MARK: - Severity + Category filter bars
    private var filterBar: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(title: "All", isSelected: selectedSeverity == nil) { selectedSeverity = nil }
                    ForEach(WarningSeverity.allCases, id: \.self) { sev in
                        let n = briefing.warnings.filter { $0.severity == sev }.count
                        FilterChip(title: "\(sev.rawValue.prefix(4)) (\(n))",
                                   color: sev.color, isSelected: selectedSeverity == sev) {
                            selectedSeverity = selectedSeverity == sev ? nil : sev
                        }
                    }
                }
                .padding(.horizontal).padding(.vertical, 8)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(title: "All Categories", isSelected: selectedCategory == nil) { selectedCategory = nil }
                    ForEach(usedCategories, id: \.self) { cat in
                        FilterChip(title: cat.rawValue.replacingOccurrences(of: "_", with: " "),
                                   color: .accentColor, isSelected: selectedCategory == cat) {
                            selectedCategory = selectedCategory == cat ? nil : cat
                        }
                    }
                }
                .padding(.horizontal).padding(.bottom, 8)
            }
        }
    }

    private var usedCategories: [WarningCategory] {
        Array(Set(briefing.warnings.map(\.category))).sorted { $0.rawValue < $1.rawValue }
    }

    private var riskColor: Color {
        switch briefing.riskScore {
        case 60...: return .red
        case 30..<60: return .orange
        default: return .green
        }
    }
}

private struct FilterChip: View {
    let title: String
    var color: Color = .accentColor
    let isSelected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.bold())
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(isSelected ? color.opacity(0.2) : Color(.secondarySystemBackground))
                .foregroundColor(isSelected ? color : .secondary)
                .clipShape(Capsule())
        }
    }
}
