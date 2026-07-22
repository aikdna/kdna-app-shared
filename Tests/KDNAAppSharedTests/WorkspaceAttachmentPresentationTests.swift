import XCTest
@testable import KDNAAppShared

final class WorkspaceAttachmentPresentationTests: XCTestCase {
    func testDecodesExactStatusAndBuildsVisibleControls() throws {
        let record = try XCTUnwrap(KDNAWorkspaceAttachmentStatusDecoder.decode(validRecordData()))
        let attachment = try XCTUnwrap(record.attachments.first)
        let presentation = KDNAWorkspaceAttachmentPresentation.from(attachment: attachment)

        XCTAssertEqual(record.documentType, "kdna.workspace-attachments")
        XCTAssertEqual(presentation.identity, "kdna:example:review@1.0.0")
        XCTAssertEqual(presentation.stateText, "Enabled")
        XCTAssertEqual(presentation.role, "deployment-review")
        XCTAssertEqual(presentation.appliesToText, "deployment review")
        XCTAssertEqual(presentation.doesNotApplyToText, "poetry")
        XCTAssertEqual(
            presentation.actions,
            [.disable, .switchExactFile, .rollback, .removeRelation]
        )
        XCTAssertTrue(presentation.accessibilitySummary.contains("deployment-review"))
    }

    func testDisabledAttachmentOffersEnableWithoutRollbackWhenHistoryIsEmpty() throws {
        var value = try XCTUnwrap(
            JSONSerialization.jsonObject(with: validRecordData()) as? [String: Any]
        )
        var attachments = try XCTUnwrap(value["attachments"] as? [[String: Any]])
        attachments[0]["state"] = "disabled"
        attachments[0]["history"] = []
        value["attachments"] = attachments

        let data = try JSONSerialization.data(withJSONObject: value)
        let record = try XCTUnwrap(KDNAWorkspaceAttachmentStatusDecoder.decode(data))
        let presentation = KDNAWorkspaceAttachmentPresentation.from(
            attachment: try XCTUnwrap(record.attachments.first)
        )

        XCTAssertEqual(presentation.stateText, "Disabled")
        XCTAssertEqual(presentation.actions, [.enable, .switchExactFile, .removeRelation])
    }

    func testAcceptsNullAsNoWorkspaceRecord() throws {
        XCTAssertNil(try KDNAWorkspaceAttachmentStatusDecoder.decode(Data("null".utf8)))
    }

    func testRejectsUnknownFieldsAndDigestMismatchedSnapshots() throws {
        var extended = try XCTUnwrap(
            JSONSerialization.jsonObject(with: validRecordData()) as? [String: Any]
        )
        extended["global_assets"] = []
        XCTAssertThrowsError(
            try KDNAWorkspaceAttachmentStatusDecoder.decode(
                JSONSerialization.data(withJSONObject: extended)
            )
        ) { error in
            XCTAssertEqual(error as? KDNAWorkspaceAttachmentStatusError, .unsupportedShape)
        }

        var mismatched = try XCTUnwrap(
            JSONSerialization.jsonObject(with: validRecordData()) as? [String: Any]
        )
        var attachments = try XCTUnwrap(mismatched["attachments"] as? [[String: Any]])
        var asset = try XCTUnwrap(attachments[0]["asset"] as? [String: Any])
        asset["snapshot"] = "assets/sha256-not-the-digest.kdna"
        attachments[0]["asset"] = asset
        mismatched["attachments"] = attachments
        XCTAssertThrowsError(
            try KDNAWorkspaceAttachmentStatusDecoder.decode(
                JSONSerialization.data(withJSONObject: mismatched)
            )
        )
    }

    func testRejectsDuplicateAttachmentIdentitiesAndOversizedOutput() throws {
        var duplicate = try XCTUnwrap(
            JSONSerialization.jsonObject(with: validRecordData()) as? [String: Any]
        )
        let attachments = try XCTUnwrap(duplicate["attachments"] as? [[String: Any]])
        duplicate["attachments"] = [attachments[0], attachments[0]]
        XCTAssertThrowsError(
            try KDNAWorkspaceAttachmentStatusDecoder.decode(
                JSONSerialization.data(withJSONObject: duplicate)
            )
        )

        XCTAssertThrowsError(
            try KDNAWorkspaceAttachmentStatusDecoder.decode(Data(repeating: 0x20, count: 1_048_577))
        ) { error in
            XCTAssertEqual(error as? KDNAWorkspaceAttachmentStatusError, .outputTooLarge)
        }
    }

    private func validRecordData() -> Data {
        let digest = "sha256:" + String(repeating: "a", count: 64)
        let value: [String: Any] = [
            "document_type": "kdna.workspace-attachments",
            "schema_version": "0.1.0",
            "workspace": ["root_marker": ".kdna/attachments.json"],
            "attachments": [[
                "attachment_id": "att_0123456789abcdef01234567",
                "asset": [
                    "id": "kdna:example:review",
                    "version": "1.0.0",
                    "digest": digest,
                    "snapshot": "assets/sha256-\(String(repeating: "a", count: 64)).kdna",
                ],
                "state": "enabled",
                "role": "deployment-review",
                "scope": [
                    "kind": "workspace",
                    "applies_to": ["deployment review"],
                    "does_not_apply_to": ["poetry"],
                ],
                "resolution_policy": "load_when_clear_ask_when_ambiguous",
                "approved_at": "2026-07-22T00:00:00.000Z",
                "update_policy": "explicit_switch_only",
                "history": [[
                    "asset": [
                        "id": "kdna:example:review",
                        "version": "0.9.0",
                        "digest": digest,
                        "snapshot": "assets/sha256-\(String(repeating: "a", count: 64)).kdna",
                    ],
                    "replaced_at": "2026-07-21T00:00:00.000Z",
                ]],
            ]],
        ]
        return try! JSONSerialization.data(withJSONObject: value)
    }
}
