import XCTest
@testable import AeroBriefAI

final class WarningModelTests: XCTestCase {
    // MARK: - Notam.relevanceRank

    func testNotamRelevanceRankOrdering() {
        func notam(_ relevance: String?) -> Notam {
            Notam(id: UUID().uuidString, airport: "LTFM", rawText: "x",
                  effectiveFrom: "", effectiveTo: "", fir: nil,
                  aircraftRelevance: relevance, relevanceReason: nil)
        }

        XCTAssertEqual(notam("CRITICAL").relevanceRank, 0)
        XCTAssertEqual(notam("IMPORTANT").relevanceRank, 1)
        XCTAssertEqual(notam("REVIEW").relevanceRank, 2)
        XCTAssertEqual(notam("INFO").relevanceRank, 3)
        XCTAssertEqual(notam("NOT_RELEVANT").relevanceRank, 4)
        XCTAssertEqual(notam(nil).relevanceRank, 4)

        // More relevant NOTAMs should sort first.
        let notams = [notam("INFO"), notam("CRITICAL"), notam("REVIEW")]
        let sorted = notams.sorted { $0.relevanceRank < $1.relevanceRank }
        XCTAssertEqual(sorted.map(\.aircraftRelevance), ["CRITICAL", "REVIEW", "INFO"])
    }

    // MARK: - WarningSeverity.sortWeight

    func testWarningSeveritySortWeightOrdering() {
        let ordered = WarningSeverity.allCases.sorted { $0.sortWeight > $1.sortWeight }
        XCTAssertEqual(ordered, [.critical, .important, .review, .info])
    }

    // MARK: - BriefingWarning.id

    func testBriefingWarningIdIsStableAndDistinguishesBySeverityAndAirport() {
        func warning(severity: WarningSeverity, airport: String?, ref: String? = "REF1") -> BriefingWarning {
            BriefingWarning(category: .runway, severity: severity, title: "Closed",
                             message: "Runway closed", source: "NOTAM", airport: airport, rawReference: ref)
        }

        let a = warning(severity: .critical, airport: "LTFM")
        let b = warning(severity: .important, airport: "LTFM")
        let c = warning(severity: .critical, airport: "LTBA")

        XCTAssertNotEqual(a.id, b.id, "Different severities should not collide")
        XCTAssertNotEqual(a.id, c.id, "Different airports should not collide")
        XCTAssertEqual(a.id, warning(severity: .critical, airport: "LTFM").id, "Same inputs should be stable")
    }
}
