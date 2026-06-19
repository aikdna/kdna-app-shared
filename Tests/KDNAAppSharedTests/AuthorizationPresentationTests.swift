import XCTest
@testable import KDNAAppShared

final class AuthorizationPresentationTests: XCTestCase {
    func testReadyPlanPresentation() {
        let presentation = KDNAAuthorizationPresentation.from(loadPlan: .init(
            assetTitle: "Writing",
            state: "ready",
            requiredAction: "none",
            canLoadNow: true,
            issueCodes: ["KDNA_OK"]
        ))

        XCTAssertEqual(presentation.assetTitle, "Writing")
        XCTAssertEqual(presentation.statusText, "Ready to load")
        XCTAssertEqual(presentation.severity, .ready)
        XCTAssertEqual(presentation.systemImageName, "checkmark.seal")
        XCTAssertNil(presentation.primaryActionTitle)
        XCTAssertTrue(presentation.canLoadNow)
    }

    func testPasswordPlanPresentation() {
        let presentation = KDNAAuthorizationPresentation.from(loadPlan: .init(
            state: "needs_password",
            requiredAction: "enter_password",
            canLoadNow: false,
            issueCodes: ["KDNA_AUTH_PASSWORD_REQUIRED"]
        ))

        XCTAssertEqual(presentation.statusText, "Password required")
        XCTAssertEqual(presentation.severity, .attention)
        XCTAssertEqual(presentation.primaryActionTitle, "Enter Password")
        XCTAssertFalse(presentation.canLoadNow)
    }

    func testRemotePlanPresentation() {
        let presentation = KDNAAuthorizationPresentation.from(loadPlan: .init(
            state: "needs_runtime",
            requiredAction: "connect_runtime",
            canLoadNow: false,
            issueCodes: ["KDNA_REMOTE_NOT_SUPPORTED"]
        ))

        XCTAssertEqual(presentation.statusText, "Remote runtime required")
        XCTAssertEqual(presentation.primaryActionTitle, "Connect Runtime")
        XCTAssertFalse(presentation.canLoadNow)
    }

    func testInvalidPlanIncludesFirstIssueCode() {
        let presentation = KDNAAuthorizationPresentation.from(loadPlan: .init(
            state: "invalid",
            requiredAction: "block",
            canLoadNow: false,
            issueCodes: ["KDNA_INTEGRITY_SIGNATURE_FAILED"]
        ))

        XCTAssertEqual(presentation.statusText, "Invalid KDNA asset")
        XCTAssertEqual(presentation.detailText, "Core reported KDNA_INTEGRITY_SIGNATURE_FAILED.")
        XCTAssertEqual(presentation.severity, .blocked)
    }
}
