import Foundation
import XCTest
import KDNACore
import KDNAAppShared

final class ReadPresentationTests: XCTestCase {
    private func asset() throws -> Data {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "scale-1", withExtension: "kdna", subdirectory: "Fixtures"))
        return try Data(contentsOf: url)
    }

    private func request(_ bytes: Data, budget: Int = 1_000_000) throws -> KDNAValue {
        let view = try XCTUnwrap(KDNACore.admitBytes(bytes).snapshot).inspect()
        return ["request_id": "request:display", "tuple": try KDNACore.versionTuple(),
                "budget_bytes": .number(Double(budget)), "mode": "exact_selection",
                "selection": ["asset_id": view["asset"]["asset_id"], "asset_version": view["asset"]["asset_version"],
                              "judgment_id": view["ir"]["catalog"].list[0]["judgment_id"]], "handle": nil]
    }

    private func control(_ limit: Int = 4096) -> KDNATrustedReadControlProvider {
        KDNATrustedReadControlProvider { ["admission_response_limit_bytes": .number(Double(limit))] }
    }

    private func host(deny: Bool = false, delivered: Bool = true) -> KDNATrustedHostReadProvider {
        KDNATrustedHostReadProvider(observe: { request, snapshot in
            let view = snapshot.inspect()
            return ["host_id": "host:display", "host_epoch": "epoch:display", "decision_id": "decision:display",
                    "request_id": request["request_id"], "snapshot_id": view["snapshot_id"],
                    "A": view["digests"]["A"]["observed"], "C": view["digests"]["C"]["observed"],
                    "scope": .array(view["ir"]["nodes"].list.map { $0["id"] }),
                    "issued_at": 900, "expires_at": 2000, "current_ms": 1000,
                    "decision": deny ? "deny" : "allow", "policy_id": "policy:display"]
        }, deliver: { _ in delivered })
    }

    func testActualReadReadyKeepsExactIdentityAndUnevaluatedAuthority() async throws {
        let bytes = try asset()
        let raw = await KDNARead.readBytes(bytes, request: try request(bytes), control: control(), host: host())
        XCTAssertEqual(raw["envelope"]["status"].text, "ready")
        let view = KDNAReadPresentation.from(readResult: raw, assetTitle: "原文 e\u{301} 😀")
        XCTAssertEqual(view.content, .available)
        XCTAssertEqual(view.severity, .ready)
        XCTAssertEqual(view.assetTitle, "原文 e\u{301} 😀")
        XCTAssertEqual(view.requestID, raw["envelope"]["request_id"].text)
        XCTAssertEqual(view.assetID, raw["envelope"]["asset"]["asset_id"].text)
        XCTAssertEqual(view.assetVersion, raw["envelope"]["asset"]["asset_version"].text)
        XCTAssertEqual(view.snapshotID, raw["envelope"]["snapshot_id"].text)
        XCTAssertEqual(view.assetDigest, raw["envelope"]["digests"]["A"]["observed"].text)
        XCTAssertEqual(view.contentDigest, raw["envelope"]["digests"]["C"]["observed"].text)
        XCTAssertEqual(view.evidenceDigest, raw["envelope"]["digests"]["E"]["observed"].text)
        XCTAssertEqual(view.selectedJudgmentID, raw["envelope"]["content"]["selected"]["judgment_id"].text)
        XCTAssertEqual(view.observedStates.actionAuthorization, "not_evaluated")
        XCTAssertEqual(view.observedStates.writer, raw["envelope"]["states"]["writer"].text)
        XCTAssertEqual(view.observedStates.confirmation, raw["envelope"]["states"]["confirmation"].text)
        XCTAssertEqual(view.delivery, "delivered")
        XCTAssertTrue(view.detailText.contains("No action authorization"))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(view)) as? [String: Any])
        XCTAssertNil(json["canLoadNow"])
        XCTAssertNil(json["primaryActionTitle"])
        XCTAssertNil(json["runtimeCapsule"])
    }

    func testActualMissingHostAndDeniedHostWithholdContent() async throws {
        let bytes = try asset()
        for (provider, code) in [(nil as KDNATrustedHostReadProvider?, "READ_HOST_CONTEXT_UNTRUSTED"), (host(deny: true), "READ_HOST_DENIED")] {
            let raw = await KDNARead.readBytes(bytes, request: try request(bytes), control: control(), host: provider)
            XCTAssertEqual(raw["envelope"]["status"].text, "rejected")
            let view = KDNAReadPresentation.from(readResult: raw)
            XCTAssertEqual(view.readStatus, "rejected")
            XCTAssertEqual(view.content, .withheld)
            XCTAssertEqual(view.diagnosticCodes, [code])
            XCTAssertNil(view.assetID)
            XCTAssertNil(view.selectedJudgmentID)
            XCTAssertEqual(view.delivery, "not_delivered")
            XCTAssertEqual(view.observedStates.actionAuthorization, "not_evaluated")
        }
    }

    func testActualAdmissionBudgetControlAndTransportAreDistinct() async throws {
        let bytes = try asset()
        var invalid = try request(bytes)
        invalid["extra_field"] = true
        let rejection = await KDNARead.readBytes(bytes, request: invalid, control: control(), host: host())
        let admissionView = KDNAReadPresentation.from(readResult: rejection)
        XCTAssertEqual(admissionView.resultChannel, "admission_rejection")
        XCTAssertEqual(admissionView.diagnosticCodes, ["READ_INPUT_INVALID"])
        XCTAssertEqual(admissionView.diagnosticReason, "unknown_field")
        XCTAssertEqual(admissionView.requestID, "request:display")
        XCTAssertEqual(admissionView.content, .withheld)

        let small = await KDNARead.readBytes(bytes, request: try request(bytes, budget: 0), control: control(), host: host())
        let controlView = KDNAReadPresentation.from(readResult: small)
        XCTAssertEqual(controlView.resultChannel, "no_body_control")
        XCTAssertEqual(controlView.diagnosticCodes, ["READ_RESPONSE_BUDGET_TOO_SMALL"])
        XCTAssertEqual(controlView.diagnosticReason, "READ_BUDGET_INSUFFICIENT")
        XCTAssertEqual(controlView.content, .withheld)
        XCTAssertNil(controlView.assetID)

        let failed = await KDNARead.readBytes(bytes, request: try request(bytes), control: control(), host: host(delivered: false))
        let transportView = KDNAReadPresentation.from(readResult: failed)
        XCTAssertEqual(transportView.resultChannel, "transport_failure")
        XCTAssertEqual(transportView.diagnosticCodes, ["READ_TRANSPORT_FAILURE"])
        XCTAssertEqual(transportView.content, .unavailable)
        XCTAssertEqual(transportView.delivery, "not_confirmed")
        XCTAssertNil(transportView.assetID)
    }

    func testActualVersionAndInvalidAssetRejectionsDoNotBecomeReady() async throws {
        let bytes = try asset()
        var mixed = try request(bytes)
        mixed["tuple"]["core"] = "kdna.core/old"
        let version = await KDNARead.readBytes(bytes, request: mixed, control: control(), host: host())
        let versionView = KDNAReadPresentation.from(readResult: version)
        XCTAssertEqual(versionView.readStatus, "rejected")
        XCTAssertEqual(versionView.diagnosticCodes, ["READ_MIXED_VERSION_TUPLE"])
        let invalid = await KDNARead.readBytes(Data("invalid asset".utf8), request: try request(bytes), control: control(), host: host())
        let invalidView = KDNAReadPresentation.from(readResult: invalid)
        XCTAssertEqual(invalidView.readStatus, "rejected")
        XCTAssertEqual(invalidView.content, .withheld)
        XCTAssertFalse(invalidView.diagnosticCodes.isEmpty)
    }

    func testUnsupportedAndContradictoryDisplayInputsCannotBeReady() async throws {
        let bytes = try asset()
        let ready = await KDNARead.readBytes(bytes, request: try request(bytes), control: control(), host: host())
        var inputs: [KDNAValue] = [
            ["state": "blocked", "canLoadNow": true, "requiredAction": "none"],
            .null,
            ["channel": "future_read", "envelope": nil, "admission_rejection": nil, "control": nil, "transport_failure": nil]
        ]
        var mixed = ready
        mixed["control"] = ["code": "READ_RESPONSE_BUDGET_TOO_SMALL", "body_bytes": 0]
        inputs.append(mixed)
        var old = ready
        old["envelope"]["contract"] = "kdna.read/old"
        inputs.append(old)
        var authority = ready
        authority["envelope"]["states"]["action_authorization"] = "allowed"
        inputs.append(authority)
        var failedDelivery = ready
        failedDelivery["envelope"]["receipt"]["delivery"] = "not_confirmed"
        inputs.append(failedDelivery)
        for input in inputs {
            let view = KDNAReadPresentation.from(readResult: input)
            XCTAssertEqual(view.content, .unavailable)
            XCTAssertEqual(view.severity, .blocked)
            XCTAssertNil(view.assetID)
        }
    }

    private func actualReady() async throws -> KDNAValue {
        let bytes = try asset()
        let result = await KDNARead.readBytes(bytes, request: try request(bytes), control: control(), host: host())
        let display = KDNAReadPresentation.from(readResult: result)
        XCTAssertEqual(display.severity, .ready)
        XCTAssertEqual(display.content, .available)
        return result
    }

    private func without(_ field: String, in value: KDNAValue) -> KDNAValue {
        guard case .object(var fields) = value else { return value }
        fields.removeValue(forKey: KDNAKey(field))
        return .object(fields)
    }

    private func assertUnavailable(_ value: KDNAValue, file: StaticString = #filePath, line: UInt = #line) {
        let display = KDNAReadPresentation.from(readResult: value)
        XCTAssertEqual(display.severity, .blocked, file: file, line: line)
        XCTAssertEqual(display.content, .unavailable, file: file, line: line)
        XCTAssertNil(display.assetID, file: file, line: line)
    }

    func testMissingReadyDigestsCannotDisplayAvailable() async throws {
        var result = try await actualReady()
        result["envelope"] = without("digests", in: result["envelope"])
        assertUnavailable(result)
    }

    func testMissingReadyWriterCannotDisplayAvailable() async throws {
        var result = try await actualReady()
        result["envelope"]["states"] = without("writer", in: result["envelope"]["states"])
        assertUnavailable(result)
    }

    func testMissingReadyConfirmationCannotDisplayAvailable() async throws {
        var result = try await actualReady()
        result["envelope"]["states"] = without("confirmation", in: result["envelope"]["states"])
        assertUnavailable(result)
    }

    func testForeignReadyReceiptCannotDisplayAvailable() async throws {
        let ready = try await actualReady()
        for field in ["request_id", "snapshot_id"] {
            var result = ready
            result["envelope"]["receipt"][field] = "foreign:display"
            assertUnavailable(result)
        }
    }

    func testMixedLegacyReadyEnvelopeCannotDisplayAvailable() async throws {
        var result = try await actualReady()
        result["envelope"]["canLoadNow"] = true
        assertUnavailable(result)
    }
}
