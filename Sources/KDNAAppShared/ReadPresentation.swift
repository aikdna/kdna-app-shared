import Foundation
import KDNACore

/// Existing app display severity. This is never a protocol or permission state.
public enum KDNAAuthorizationPresentationSeverity: String, Codable, Equatable, Sendable {
    case ready
    case attention
    case blocked
    case informational
}

/// Whether the supplied response includes a disclosed Read body. This describes
/// presentation data; it cannot be used as a loading or execution capability.
public enum KDNAReadPresentationContent: String, Codable, Equatable, Sendable {
    case available
    case withheld
    case unavailable
}

/// Exact observed state strings from a public Read envelope. Missing states
/// remain nil rather than being promoted to an approval or inferred result.
public struct KDNAReadPresentationStates: Codable, Equatable, Sendable {
    public let core: String?
    public let interpretation: String?
    public let writer: String?
    public let confirmation: String?
    public let readPermission: String?
    public let actionAuthorization: String?

    fileprivate init(_ value: KDNAValue) {
        core = KDNAReadPresentation.text(value["core"])
        interpretation = KDNAReadPresentation.text(value["interpretation"])
        writer = KDNAReadPresentation.text(value["writer"])
        confirmation = KDNAReadPresentation.text(value["confirmation"])
        readPermission = KDNAReadPresentation.text(value["read_permission"])
        actionAuthorization = KDNAReadPresentation.text(value["action_authorization"])
    }
}

/// A content-neutral display adapter for values returned by public
/// KDNARead.readBytes/readFile/readSnapshot. It does not parse assets or wire
/// JSON, authenticate the caller's value, grant access, or create model context.
/// Callers retain the actual Read result and its trusted host boundary.
public struct KDNAReadPresentation: Codable, Equatable, Sendable {
    public let assetTitle: String?
    public let resultChannel: String?
    public let readStatus: String?
    public let statusText: String
    public let detailText: String
    public let severity: KDNAAuthorizationPresentationSeverity
    public let systemImageName: String
    public let content: KDNAReadPresentationContent
    public let requestID: String?
    public let assetID: String?
    public let assetVersion: String?
    public let snapshotID: String?
    public let assetDigest: String?
    public let contentDigest: String?
    public let evidenceDigest: String?
    public let selectedJudgmentID: String?
    public let diagnosticCodes: [String]
    public let diagnosticReason: String?
    public let delivery: String?
    public let observedStates: KDNAReadPresentationStates

    /// Maps display fields only. A ready label refers to this supplied Read
    /// response, never permission to reuse content, execute actions or load a
    /// runtime. Unsupported or mixed result shapes cannot yield ready display.
    public static func from(readResult result: KDNAValue, assetTitle: String? = nil) -> KDNAReadPresentation {
        guard case .object(let fields) = result,
              Set(fields.keys) == Set(["channel", "envelope", "admission_rejection", "control", "transport_failure"].map { KDNAKey($0) }),
              let channel = text(result["channel"]) else { return unsupported(assetTitle) }
        let member: String
        switch channel {
        case "read_envelope": member = "envelope"
        case "admission_rejection": member = "admission_rejection"
        case "no_body_control": member = "control"
        case "transport_failure": member = "transport_failure"
        default: return unsupported(assetTitle, channel: channel)
        }
        guard case .object = result[member], ["envelope", "admission_rejection", "control", "transport_failure"].filter({ $0 != member }).allSatisfy({ result[$0] == .null }) else {
            return unsupported(assetTitle, channel: channel)
        }
        let value = result[member]
        switch channel {
        case "read_envelope":
            guard hasEnvelopeDisplayShape(value),
                  let tuple = try? KDNACore.versionTuple(), value["contract"] == tuple["read"],
                  let requestID = text(value["request_id"]), value["status"] == "ready" || value["status"] == "rejected" else {
                return unsupported(assetTitle, channel: channel)
            }
            let states = KDNAReadPresentationStates(value["states"])
            let codes = value["diagnostics"].list.compactMap { text($0["code"]) }
            if value["status"] == "ready" {
                guard case .object = value["content"], value["tuple"] == tuple,
                      states.core == "valid", states.interpretation == "complete", states.readPermission == "allowed",
                      states.actionAuthorization == "not_evaluated", states.writer != nil, states.confirmation != nil,
                      value["receipt"]["delivery"] == "delivered", value["receipt"]["request_id"] == value["request_id"],
                      value["receipt"]["snapshot_id"] == value["snapshot_id"],
                      text(value["digests"]["A"]["observed"]) != nil, text(value["digests"]["C"]["observed"]) != nil,
                      text(value["digests"]["E"]["observed"]) != nil,
                      text(value["asset"]["asset_id"]) != nil, text(value["asset"]["asset_version"]) != nil,
                      text(value["snapshot_id"]) != nil else { return unsupported(assetTitle, channel: channel) }
                return KDNAReadPresentation(
                    assetTitle: assetTitle, resultChannel: channel, readStatus: "ready",
                    statusText: "Read content available", detailText: "The host allowed disclosure of this response. No action authorization is implied.",
                    severity: .ready, systemImageName: "doc.text", content: .available,
                    requestID: requestID, assetID: text(value["asset"]["asset_id"]), assetVersion: text(value["asset"]["asset_version"]),
                    snapshotID: text(value["snapshot_id"]), assetDigest: text(value["digests"]["A"]["observed"]),
                    contentDigest: text(value["digests"]["C"]["observed"]), evidenceDigest: text(value["digests"]["E"]["observed"]),
                    selectedJudgmentID: text(value["content"]["selected"]["judgment_id"]), diagnosticCodes: codes,
                    diagnosticReason: nil, delivery: text(value["receipt"]["delivery"]), observedStates: states)
            }
            guard value["content"] == .null else { return unsupported(assetTitle, channel: channel) }
            return noContent(assetTitle, channel: channel, readStatus: "rejected", statusText: "Read did not disclose content",
                             detail: rejectionDetail(codes.first), severity: .blocked, image: "doc.badge.ellipsis", content: .withheld,
                             requestID: requestID, codes: codes, delivery: text(value["receipt"]["delivery"]), states: states)
        case "admission_rejection":
            guard let code = text(value["code"]) else { return unsupported(assetTitle, channel: channel) }
            return noContent(assetTitle, channel: channel, statusText: "Read request rejected",
                             detail: "The request was rejected before content disclosure.", severity: .blocked,
                             image: "exclamationmark.circle", content: .withheld,
                             requestID: correlatedID(value["correlation"]), codes: [code], reason: text(value["diagnostic"]["reason"]))
        case "no_body_control":
            guard let code = text(value["code"]), value["body_bytes"] == 0 else { return unsupported(assetTitle, channel: channel) }
            return noContent(assetTitle, channel: channel, statusText: "Response body withheld",
                             detail: "The Read operation returned a control result without a body.", severity: .attention,
                             image: "doc.badge.ellipsis", content: .withheld,
                             requestID: correlatedID(value["correlation"]), codes: [code], reason: text(value["semantic_cause"]))
        case "transport_failure":
            guard let code = text(value["code"]), value["delivery"] == "not_confirmed" else { return unsupported(assetTitle, channel: channel) }
            return noContent(assetTitle, channel: channel, statusText: "Read delivery unconfirmed",
                             detail: "Delivery was not confirmed. This result contains no disclosed Read body.", severity: .attention,
                             image: "network.slash", content: .unavailable,
                             requestID: correlatedID(value["correlation"]), codes: [code], reason: text(value["semantic_cause"]),
                             delivery: text(value["delivery"]))
        default: return unsupported(assetTitle, channel: channel)
        }
    }

    // This finite top-level shape guard prevents mixed legacy display inputs.
    // It does not validate content, recompute digests, or authenticate a result.
    private static func hasEnvelopeDisplayShape(_ value: KDNAValue) -> Bool {
        guard case .object(let fields) = value else { return false }
        return Set(fields.keys) == Set([
            "assessment", "asset", "budget", "content", "contract", "diagnostics",
            "digests", "omissions", "receipt", "request_id", "snapshot_id", "states", "status", "tuple"
        ].map { KDNAKey($0) })
    }

    fileprivate static func text(_ value: KDNAValue) -> String? {
        guard case .string(let string) = value, !string.isEmpty else { return nil }
        return string
    }
    private static func correlatedID(_ value: KDNAValue) -> String? {
        value["state"] == "validated" ? text(value["request_id"]) : nil
    }
    private static func rejectionDetail(_ code: String?) -> String {
        switch code {
        case "READ_HOST_CONTEXT_UNTRUSTED": return "A trusted host decision was not available for this read."
        case "READ_HOST_DENIED": return "The host denied this read."
        case "READ_BUDGET_INSUFFICIENT": return "The response budget was insufficient for the requested content."
        case "READ_CORE_INVALID": return "Core did not admit the supplied asset."
        default: return "The Read result contains no disclosed content. Inspect its diagnostic codes for the reported reason."
        }
    }
    private static func unsupported(_ title: String?, channel: String? = nil) -> KDNAReadPresentation {
        noContent(title, channel: channel, statusText: "Unsupported Read result",
                  detail: "This value cannot be mapped to the current public Read presentation. No permission is inferred.",
                  severity: .blocked, image: "questionmark.circle", content: .unavailable)
    }
    private static func noContent(
        _ title: String?, channel: String?, readStatus: String? = nil, statusText: String, detail: String,
        severity: KDNAAuthorizationPresentationSeverity, image: String, content: KDNAReadPresentationContent,
        requestID: String? = nil, codes: [String] = [], reason: String? = nil, delivery: String? = nil,
        states: KDNAReadPresentationStates = KDNAReadPresentationStates(.null)
    ) -> KDNAReadPresentation {
        KDNAReadPresentation(assetTitle: title, resultChannel: channel, readStatus: readStatus,
                             statusText: statusText, detailText: detail, severity: severity, systemImageName: image,
                             content: content, requestID: requestID, assetID: nil, assetVersion: nil, snapshotID: nil,
                             assetDigest: nil, contentDigest: nil, evidenceDigest: nil, selectedJudgmentID: nil,
                             diagnosticCodes: codes, diagnosticReason: reason, delivery: delivery, observedStates: states)
    }
}
