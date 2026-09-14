import Foundation
import XCTest
import KDNAAppShared

final class WorkspaceAuthorityBoundaryTests: XCTestCase {
    func testLegacyRelationshipApprovalDateDoesNotBecomeReadOrActionPermission() throws {
        let digest = String(repeating: "a", count: 64)
        for state in ["enabled", "disabled"] {
            let value: [String: Any] = [
                "document_type": "kdna.workspace-attachments", "schema_version": "0.1.0",
                "workspace": ["root_marker": ".kdna/attachments.json"],
                "attachments": [[
                    "attachment_id": "att_0123456789abcdef01234567",
                    "asset": ["id": "kdna:example:display", "version": "1.0.0",
                              "digest": "sha256:" + digest, "snapshot": "assets/sha256-" + digest + ".kdna"],
                    "state": state, "role": "review",
                    "scope": ["kind": "workspace", "applies_to": ["review"], "does_not_apply_to": []],
                    "resolution_policy": "load_when_clear_ask_when_ambiguous",
                    "approved_at": "2026-07-22T00:00:00.000Z",
                    "update_policy": "explicit_switch_only", "history": []
                ]]
            ]
            let record = try XCTUnwrap(KDNAWorkspaceAttachmentStatusDecoder.decode(JSONSerialization.data(withJSONObject: value)))
            let view = KDNAWorkspaceAttachmentPresentation.from(attachment: try XCTUnwrap(record.attachments.first))
            XCTAssertEqual(view.reasonText, "Workspace relation recorded")
            XCTAssertEqual(view.identity, "kdna:example:display@1.0.0")
            XCTAssertEqual(view.digest, "sha256:" + digest)
            XCTAssertEqual(view.actions, [state == "enabled" ? .disable : .enable, .switchExactFile, .removeRelation])
            let output = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(view)) as? [String: Any])
            XCTAssertNil(output["canLoadNow"])
            XCTAssertNil(output["readPermission"])
            XCTAssertNil(output["actionAuthorization"])
        }
    }
}
