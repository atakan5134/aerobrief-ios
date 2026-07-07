import SwiftUI
import UIKit

struct SeverityBadge: View {
    let severity: WarningSeverity
    var body: some View {
        Text(severity.rawValue)
            .font(.caption2.bold())
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(severity.color.opacity(0.18))
            .foregroundColor(severity.color)
            .clipShape(Capsule())
    }
}

struct WarningCardView: View {
    let warning: BriefingWarning
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row — always visible
            HStack(alignment: .top, spacing: 0) {
                // Severity left bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(warning.severity.color)
                    .frame(width: 4)
                    .padding(.trailing, 12)

                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .top) {
                        Image(systemName: warning.category.systemImage)
                            .font(.subheadline)
                            .foregroundColor(warning.severity.color)
                        Text(warning.title)
                            .font(.subheadline.bold())
                        Spacer()
                        SeverityBadge(severity: warning.severity)
                    }

                    HStack(spacing: 10) {
                        Label(warning.source, systemImage: "doc.text")
                        if let airport = warning.airport {
                            Label(airport, systemImage: "mappin.and.ellipse")
                        }
                        if let ref = warning.rawReference {
                            Label(ref, systemImage: "number")
                        }
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
            }
            .padding()
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
                if warning.severity == .critical {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                } else if warning.severity == .important {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }

            // Expanded detail
            if expanded {
                Divider().padding(.horizontal)
                Text(warning.message)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(warning.severity.color.opacity(expanded ? 0.5 : 0.15), lineWidth: 1)
        )
    }
}
