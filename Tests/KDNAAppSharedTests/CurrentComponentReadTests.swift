import Foundation
import XCTest
import KDNACore
import KDNAAppShared

final class CurrentComponentReadTests: XCTestCase {
    private func asset(_ name: String) throws -> Data {
        let url = try XCTUnwrap(Bundle.module.url(forResource: name, withExtension: "kdna", subdirectory: "Fixtures/Components"))
        return try Data(contentsOf: url)
    }
    private let control = KDNATrustedReadControlProvider { ["admission_response_limit_bytes": 4096] }
    private func host() -> KDNATrustedHostReadProvider {
        KDNATrustedHostReadProvider(observe: { request, snapshot in
            let view = snapshot.inspect()
            return ["host_id": "host:app-shared-components", "host_epoch": "epoch:local", "decision_id": "decision:local",
                    "request_id": request["request_id"], "snapshot_id": view["snapshot_id"],
                    "A": view["digests"]["A"]["observed"], "C": view["digests"]["C"]["observed"],
                    "scope": .array(view["ir"]["nodes"].list.map { $0["id"] }), "issued_at": 900,
                    "expires_at": 2000, "current_ms": 1000, "decision": "allow", "policy_id": "policy:local-only"]
        }, deliver: { _ in true })
    }
    private func request(_ view: KDNAValue, judgment: KDNAValue) throws -> KDNAValue {
        ["request_id": "request:app-shared-components", "tuple": try KDNACore.versionTuple(), "budget_bytes": 1_000_000,
         "mode": "exact_selection", "selection": ["asset_id": view["asset"]["asset_id"],
         "asset_version": view["asset"]["asset_version"], "judgment_id": judgment], "handle": nil]
    }
    private func read(_ name: String) async throws -> KDNAValue {
        let bytes = try asset(name), view = try XCTUnwrap(KDNACore.admitBytes(bytes).snapshot).inspect()
        return await KDNARead.readBytes(bytes, request: try request(view, judgment: view["ir"]["catalog"].list[0]["judgment_id"]), control: control, host: host())
    }
    func testCurrentContractAndThreeProducerFormsUseActualPublicRead() async throws {
        let tuple = try KDNACore.versionTuple()
        XCTAssertEqual(tuple["core"], "kdna.core/0.3.0")
        XCTAssertEqual(tuple["ir"], "kdna.canonical-ir/0.2.0")
        XCTAssertEqual(tuple["read"], "kdna.read/0.2.0")
        XCTAssertEqual(try KDNACore.componentSemanticsContract()["definition_digest"], "sha256:3087cd19542e72322aec19b3015c916d2cfb074fa42e3fd76b3756bb4f097de3")
        for name in ["ordinary", "taxonomy", "differential"] {
            let bytes = try asset(name), core = try XCTUnwrap(KDNACore.admitBytes(bytes).snapshot).inspect()
            for item in core["ir"]["catalog"].list {
                let raw = await KDNARead.readBytes(bytes, request: try request(core, judgment: item["judgment_id"]), control: control, host: host())
                XCTAssertEqual(raw["envelope"]["status"], "ready")
                let before = raw, display = KDNAReadPresentation.from(readResult: raw, assetTitle: "原文 e\u{301} 😀")
                XCTAssertEqual(display.content, .available)
                XCTAssertEqual(display.assetID, core["asset"]["asset_id"].text)
                XCTAssertEqual(display.selectedJudgmentID, item["judgment_id"].text)
                XCTAssertEqual(display.observedStates.actionAuthorization, "not_evaluated")
                XCTAssertEqual(display.observedStates.writer, raw["envelope"]["states"]["writer"].text)
                XCTAssertEqual(display.observedStates.confirmation, raw["envelope"]["states"]["confirmation"].text)
                XCTAssertEqual(raw, before)
                let closure = raw["envelope"]["content"]["closure"].list
                let mandatory = try XCTUnwrap(core["ir"]["mandatory_closures"].list.first { $0["selection"]["judgment_id"] == item["judgment_id"] })["node_ids"].list
                XCTAssertEqual(closure.map { $0["id"] }, mandatory)
                for node in closure { XCTAssertEqual(core["ir"]["nodes"].list.first { $0["id"] == node["id"] }, node) }
                let encoded = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(display)) as? [String: Any])
                for field in ["closure", "method", "supported_components", "canLoadNow", "runtimeCapsule", "primaryActionTitle"] { XCTAssertNil(encoded[field]) }
            }
        }
    }
    func testAbsentAndDeclaredEmptyRemainSeparateInRetainedRead() async throws {
        let absent = try await read("no-method"), declared = try await read("declared-empty"), presence = try await read("presence-only")
        let methods = [absent, declared, presence].map { $0["envelope"]["content"]["closure"].list.filter { $0["role"] == "method" } }
        XCTAssertEqual(methods[0].count, 0)
        XCTAssertEqual(methods[1].count, 1)
        XCTAssertEqual(methods[2].count, 1)
        XCTAssertEqual(methods[1][0]["value"]["declaration_presence"], ["components_state": "declared", "bindings_state": "declared"])
        XCTAssertEqual(methods[2][0]["value"]["declaration_presence"], ["components_state": "undeclared", "bindings_state": "declared"])
        for raw in [absent, declared, presence] { XCTAssertEqual(KDNAReadPresentation.from(readResult: raw).content, .available) }
    }
    func testAllFiniteComponentBodiesStayInPublicReadClosure() async throws {
        let raw = try await read("full-trio")
        let method = try XCTUnwrap(raw["envelope"]["content"]["closure"].list.first { $0["role"] == "method" })
        let values = method["value"]["component_interpretations"].list
        XCTAssertEqual(Set(values.map { $0["component_type"].text }), Set(["taxonomy", "candidate-set", "discriminator-set"]))
        for value in values {
            XCTAssertEqual(value["status"], "supported")
            XCTAssertNotEqual(value["body"], .null)
            XCTAssertNotEqual(value["authored_content"], .null)
            XCTAssertEqual(value["definition_digest"], try KDNACore.componentSemanticsContract()["definition_digest"])
        }
        XCTAssertEqual(KDNAReadPresentation.from(readResult: raw).content, .available)
    }
    func testActualComponentFailureRemainsBlockedAndOldTupleCannotBeReady() async throws {
        let good = try asset("no-method"), view = try XCTUnwrap(KDNACore.admitBytes(good).snapshot).inspect()
        let request = try request(view, judgment: view["ir"]["catalog"].list[0]["judgment_id"])
        let invalid = try asset("wrong-D")
        XCTAssertNil(KDNACore.admitBytes(invalid).snapshot)
        XCTAssertEqual(KDNACore.admitBytes(invalid).result["reason"], "READ_COMPONENT_DECLARATION_INVALID")
        let rejected = await KDNARead.readBytes(invalid, request: request, control: control, host: host())
        let display = KDNAReadPresentation.from(readResult: rejected)
        XCTAssertEqual(display.content, .withheld)
        XCTAssertEqual(display.diagnosticCodes, ["READ_COMPONENT_DECLARATION_INVALID"])
        XCTAssertEqual(display.observedStates.core, "valid")
        XCTAssertEqual(display.observedStates.interpretation, "blocked")
        XCTAssertNil(display.selectedJudgmentID)
        var old = request
        old["tuple"]["core"] = "kdna.core/0.2.0"
        old["tuple"]["ir"] = "kdna.canonical-ir/0.1.0"
        old["tuple"]["read"] = "kdna.read/0.1.0"
        let oldResult = await KDNARead.readBytes(good, request: old, control: control, host: host())
        XCTAssertEqual(KDNAReadPresentation.from(readResult: oldResult).diagnosticCodes, ["READ_MIXED_VERSION_TUPLE"])
        XCTAssertEqual(KDNAReadPresentation.from(readResult: oldResult).content, .withheld)
        var spoof = try await read("no-method")
        spoof["envelope"]["contract"] = "kdna.read/0.1.0"
        XCTAssertEqual(KDNAReadPresentation.from(readResult: spoof).content, .unavailable)
    }
}
