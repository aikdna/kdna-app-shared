import Foundation

/// Read-only DTO for the runtime CLI 0.1 workspace-attachment status shape.
///
/// This package does not own the record or its schema. Apps obtain this value
/// from the exact runtime CLI and must send every mutation back to that CLI.
public struct KDNAWorkspaceAssetReference: Codable, Equatable, Sendable {
    public let id: String
    public let version: String
    public let digest: String
    public let snapshot: String
}

public enum KDNAWorkspaceAttachmentState: String, Codable, Equatable, Sendable {
    case enabled
    case disabled
}

public struct KDNAWorkspaceAttachmentScope: Codable, Equatable, Sendable {
    public let kind: String
    public let appliesTo: [String]
    public let doesNotApplyTo: [String]

    enum CodingKeys: String, CodingKey {
        case kind
        case appliesTo = "applies_to"
        case doesNotApplyTo = "does_not_apply_to"
    }
}

public struct KDNAWorkspaceAttachmentHistoryItem: Codable, Equatable, Sendable {
    public let asset: KDNAWorkspaceAssetReference
    public let replacedAt: String

    enum CodingKeys: String, CodingKey {
        case asset
        case replacedAt = "replaced_at"
    }
}

public struct KDNAWorkspaceAttachment: Codable, Equatable, Sendable, Identifiable {
    public let attachmentID: String
    public let asset: KDNAWorkspaceAssetReference
    public let state: KDNAWorkspaceAttachmentState
    public let role: String
    public let scope: KDNAWorkspaceAttachmentScope
    public let resolutionPolicy: String
    public let approvedAt: String
    public let updatePolicy: String
    public let history: [KDNAWorkspaceAttachmentHistoryItem]

    public var id: String { attachmentID }

    enum CodingKeys: String, CodingKey {
        case attachmentID = "attachment_id"
        case asset
        case state
        case role
        case scope
        case resolutionPolicy = "resolution_policy"
        case approvedAt = "approved_at"
        case updatePolicy = "update_policy"
        case history
    }
}

public struct KDNAWorkspaceAttachmentRecord: Codable, Equatable, Sendable {
    public struct Workspace: Codable, Equatable, Sendable {
        public let rootMarker: String

        enum CodingKeys: String, CodingKey {
            case rootMarker = "root_marker"
        }
    }

    public let documentType: String
    public let schemaVersion: String
    public let workspace: Workspace
    public let attachments: [KDNAWorkspaceAttachment]

    enum CodingKeys: String, CodingKey {
        case documentType = "document_type"
        case schemaVersion = "schema_version"
        case workspace
        case attachments
    }
}

public enum KDNAWorkspaceAttachmentStatusError: Error, Equatable, LocalizedError, Sendable {
    case outputTooLarge
    case malformedJSON
    case unsupportedShape

    public var errorDescription: String? {
        switch self {
        case .outputTooLarge:
            return "The runtime CLI returned an oversized workspace status."
        case .malformedJSON, .unsupportedShape:
            return "The runtime CLI returned an unsupported workspace status."
        }
    }
}

/// Fail-closed decoder for the exact bounded status JSON emitted by the
/// runtime CLI. Unknown fields are rejected instead of silently ignored by
/// `Codable`.
public enum KDNAWorkspaceAttachmentStatusDecoder {
    private static let maximumBytes = 1_048_576
    private static let maximumAttachments = 1_024
    private static let maximumScopeTerms = 256
    private static let maximumTextLength = 4_096

    public static func decode(_ data: Data) throws -> KDNAWorkspaceAttachmentRecord? {
        guard data.count <= maximumBytes else {
            throw KDNAWorkspaceAttachmentStatusError.outputTooLarge
        }
        let value: Any
        do {
            value = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        } catch {
            throw KDNAWorkspaceAttachmentStatusError.malformedJSON
        }
        if value is NSNull { return nil }
        guard validateRecord(value) else {
            throw KDNAWorkspaceAttachmentStatusError.unsupportedShape
        }
        do {
            return try JSONDecoder().decode(KDNAWorkspaceAttachmentRecord.self, from: data)
        } catch {
            throw KDNAWorkspaceAttachmentStatusError.unsupportedShape
        }
    }

    private static func validateRecord(_ value: Any) -> Bool {
        guard let record = dictionary(value),
              exactKeys(record, ["document_type", "schema_version", "workspace", "attachments"]),
              record["document_type"] as? String == "kdna.workspace-attachments",
              record["schema_version"] as? String == "0.1.0",
              let workspace = dictionary(record["workspace"]),
              exactKeys(workspace, ["root_marker"]),
              workspace["root_marker"] as? String == ".kdna/attachments.json",
              let attachments = record["attachments"] as? [Any],
              attachments.count <= maximumAttachments
        else { return false }

        var attachmentIDs = Set<String>()
        for attachment in attachments {
            guard validateAttachment(attachment),
                  let attachmentID = dictionary(attachment)?["attachment_id"] as? String,
                  attachmentIDs.insert(attachmentID).inserted
            else { return false }
        }
        return true
    }

    private static func validateAttachment(_ value: Any) -> Bool {
        guard let attachment = dictionary(value),
              exactKeys(attachment, [
                  "attachment_id", "asset", "state", "role", "scope",
                  "resolution_policy", "approved_at", "update_policy", "history",
              ]),
              let attachmentID = attachment["attachment_id"] as? String,
              matches(attachmentID, pattern: #"^att_[0-9a-f]{24}$"#),
              validateAsset(attachment["asset"]),
              let state = attachment["state"] as? String,
              ["enabled", "disabled"].contains(state),
              boundedText(attachment["role"]),
              validateScope(attachment["scope"]),
              attachment["resolution_policy"] as? String == "load_when_clear_ask_when_ambiguous",
              validTimestamp(attachment["approved_at"]),
              attachment["update_policy"] as? String == "explicit_switch_only",
              let history = attachment["history"] as? [Any],
              history.count <= maximumAttachments
        else { return false }

        return history.allSatisfy(validateHistoryItem)
    }

    private static func validateAsset(_ value: Any?) -> Bool {
        guard let asset = dictionary(value),
              exactKeys(asset, ["id", "version", "digest", "snapshot"]),
              boundedText(asset["id"]),
              boundedText(asset["version"]),
              let digest = asset["digest"] as? String,
              matches(digest, pattern: #"^sha256:[0-9a-f]{64}$"#),
              let snapshot = asset["snapshot"] as? String,
              snapshot == "assets/sha256-\(digest.dropFirst("sha256:".count)).kdna"
        else { return false }
        return true
    }

    private static func validateScope(_ value: Any?) -> Bool {
        guard let scope = dictionary(value),
              exactKeys(scope, ["kind", "applies_to", "does_not_apply_to"]),
              scope["kind"] as? String == "workspace",
              let appliesTo = scope["applies_to"] as? [Any],
              let doesNotApplyTo = scope["does_not_apply_to"] as? [Any],
              validTerms(appliesTo), validTerms(doesNotApplyTo)
        else { return false }
        return true
    }

    private static func validateHistoryItem(_ value: Any) -> Bool {
        guard let item = dictionary(value),
              exactKeys(item, ["asset", "replaced_at"]),
              validateAsset(item["asset"]),
              validTimestamp(item["replaced_at"])
        else { return false }
        return true
    }

    private static func validTerms(_ values: [Any]) -> Bool {
        guard values.count <= maximumScopeTerms else { return false }
        var normalized = Set<String>()
        for value in values {
            guard boundedText(value), let text = value as? String else { return false }
            let key = text
                .split(whereSeparator: { $0.isWhitespace })
                .joined(separator: " ")
                .lowercased()
            guard normalized.insert(key).inserted else { return false }
        }
        return true
    }

    private static func validTimestamp(_ value: Any?) -> Bool {
        guard let timestamp = value as? String,
              matches(timestamp, pattern: #"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$"#)
        else { return false }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: timestamp) != nil
    }

    private static func boundedText(_ value: Any?) -> Bool {
        guard let text = value as? String,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return false }
        return text.utf16.count <= maximumTextLength
    }

    private static func dictionary(_ value: Any?) -> [String: Any]? {
        value as? [String: Any]
    }

    private static func exactKeys(_ value: [String: Any], _ expected: Set<String>) -> Bool {
        Set(value.keys) == expected
    }

    private static func matches(_ value: String, pattern: String) -> Bool {
        value.range(of: pattern, options: .regularExpression) != nil
    }
}

public enum KDNAWorkspaceAttachmentAction: String, Codable, Equatable, CaseIterable, Sendable {
    case enable
    case disable
    case switchExactFile
    case rollback
    case removeRelation
}

/// UI-ready, content-neutral state. It never contains a judgment projection or
/// an entitlement secret.
public struct KDNAWorkspaceAttachmentPresentation: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let identity: String
    public let digest: String
    public let state: KDNAWorkspaceAttachmentState
    public let stateText: String
    public let role: String
    public let appliesToText: String
    public let doesNotApplyToText: String
    public let reasonText: String
    public let actions: [KDNAWorkspaceAttachmentAction]
    public let accessibilitySummary: String

    public static func from(
        attachment: KDNAWorkspaceAttachment
    ) -> KDNAWorkspaceAttachmentPresentation {
        let identity = "\(attachment.asset.id)@\(attachment.asset.version)"
        let stateText = attachment.state == .enabled ? "Enabled" : "Disabled"
        let applies = attachment.scope.appliesTo.joined(separator: ", ")
        let excludes = attachment.scope.doesNotApplyTo.joined(separator: ", ")
        var actions: [KDNAWorkspaceAttachmentAction] = [
            attachment.state == .enabled ? .disable : .enable,
            .switchExactFile,
        ]
        if !attachment.history.isEmpty { actions.append(.rollback) }
        actions.append(.removeRelation)
        let reason = "Approved workspace relation; task applicability remains Host-controlled."
        return KDNAWorkspaceAttachmentPresentation(
            id: attachment.attachmentID,
            identity: identity,
            digest: attachment.asset.digest,
            state: attachment.state,
            stateText: stateText,
            role: attachment.role,
            appliesToText: applies.isEmpty ? "None" : applies,
            doesNotApplyToText: excludes.isEmpty ? "None" : excludes,
            reasonText: reason,
            actions: actions,
            accessibilitySummary: "\(identity), \(stateText). Role: \(attachment.role). Applies to: \(applies.isEmpty ? "none" : applies). Does not apply to: \(excludes.isEmpty ? "none" : excludes)."
        )
    }
}
