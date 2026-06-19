import Foundation

/// Display severity for app UI. This is intentionally not a protocol state.
public enum KDNAAuthorizationPresentationSeverity: String, Codable, Equatable, Sendable {
    case ready
    case attention
    case blocked
    case informational
}

/// A presentation-only snapshot of a Core LoadPlan.
///
/// `kdna-app-shared` must not define LoadPlan protocol facts. KDNA Chat and
/// KDNA Studio should build this value from `KDNACore.KDNALoadPlan` once the
/// corresponding Core release exposes that type.
public struct KDNALoadPlanPresentationInput: Codable, Equatable, Sendable {
    public var assetTitle: String?
    public var state: String
    public var requiredAction: String
    public var canLoadNow: Bool
    public var issueCodes: [String]

    public init(
        assetTitle: String? = nil,
        state: String,
        requiredAction: String,
        canLoadNow: Bool,
        issueCodes: [String] = []
    ) {
        self.assetTitle = assetTitle
        self.state = state
        self.requiredAction = requiredAction
        self.canLoadNow = canLoadNow
        self.issueCodes = issueCodes
    }
}

public struct KDNAAuthorizationPresentation: Codable, Equatable, Sendable {
    public var assetTitle: String?
    public var statusText: String
    public var detailText: String
    public var severity: KDNAAuthorizationPresentationSeverity
    public var systemImageName: String
    public var primaryActionTitle: String?
    public var canLoadNow: Bool

    public init(
        assetTitle: String? = nil,
        statusText: String,
        detailText: String,
        severity: KDNAAuthorizationPresentationSeverity,
        systemImageName: String,
        primaryActionTitle: String? = nil,
        canLoadNow: Bool
    ) {
        self.assetTitle = assetTitle
        self.statusText = statusText
        self.detailText = detailText
        self.severity = severity
        self.systemImageName = systemImageName
        self.primaryActionTitle = primaryActionTitle
        self.canLoadNow = canLoadNow
    }

    public static func from(loadPlan input: KDNALoadPlanPresentationInput) -> KDNAAuthorizationPresentation {
        let state = normalized(input.state)
        let requiredAction = normalized(input.requiredAction)
        let issues = Set(input.issueCodes.map(normalized))

        if input.canLoadNow {
            if state == "offline_grace" || issues.contains("kdna_auth_offline_grace_active") {
                return KDNAAuthorizationPresentation(
                    assetTitle: input.assetTitle,
                    statusText: "Offline grace active",
                    detailText: "This KDNA can load now, but the entitlement should be synced when the network is available.",
                    severity: .informational,
                    systemImageName: "clock.badge.checkmark",
                    primaryActionTitle: "Sync",
                    canLoadNow: true
                )
            }

            return KDNAAuthorizationPresentation(
                assetTitle: input.assetTitle,
                statusText: "Ready to load",
                detailText: "Core authorized this KDNA for the current runtime.",
                severity: .ready,
                systemImageName: "checkmark.seal",
                canLoadNow: true
            )
        }

        if state == "needs_password" || requiredAction == "enter_password" || issues.contains("kdna_auth_password_required") {
            return blocked(
                input,
                statusText: "Password required",
                detailText: "Enter the asset password before loading this KDNA.",
                systemImageName: "lock",
                primaryActionTitle: "Enter Password",
                severity: .attention
            )
        }

        if state == "needs_license" || requiredAction == "install_receipt" || issues.contains("kdna_auth_entitlement_required") {
            return blocked(
                input,
                statusText: "License required",
                detailText: "Install a valid local receipt before loading this KDNA.",
                systemImageName: "key",
                primaryActionTitle: "Install License",
                severity: .attention
            )
        }

        if state == "needs_account" || requiredAction == "sign_in_or_activate" || issues.contains("kdna_auth_account_required") {
            return blocked(
                input,
                statusText: "Account required",
                detailText: "Sign in or activate this device before loading this KDNA.",
                systemImageName: "person.crop.circle.badge.exclamationmark",
                primaryActionTitle: "Sign In",
                severity: .attention
            )
        }

        if state == "needs_org_auth" || issues.contains("kdna_auth_org_required") {
            return blocked(
                input,
                statusText: "Organization authorization required",
                detailText: "Use an authorized organization account before loading this KDNA.",
                systemImageName: "building.2.crop.circle",
                primaryActionTitle: "Sign In",
                severity: .attention
            )
        }

        if state == "needs_runtime" || requiredAction == "connect_runtime" || issues.contains("kdna_auth_remote_runtime_required") || issues.contains("kdna_remote_not_supported") {
            return blocked(
                input,
                statusText: "Remote runtime required",
                detailText: "This KDNA is recognized, but it cannot be loaded by the local runtime.",
                systemImageName: "network.badge.shield.half.filled",
                primaryActionTitle: "Connect Runtime",
                severity: .attention
            )
        }

        if state == "expired" || issues.contains("kdna_auth_expired") || issues.contains("kdna_auth_offline_grace_expired") {
            return blocked(
                input,
                statusText: "Entitlement expired",
                detailText: "Sync or install a current entitlement before loading this KDNA.",
                systemImageName: "calendar.badge.exclamationmark",
                primaryActionTitle: "Sync",
                severity: .blocked
            )
        }

        if state == "revoked" || issues.contains("kdna_auth_revoked") {
            return blocked(
                input,
                statusText: "Access revoked",
                detailText: "Core blocked this KDNA because the entitlement has been revoked.",
                systemImageName: "xmark.seal",
                severity: .blocked
            )
        }

        if state == "invalid" || requiredAction == "block" {
            return blocked(
                input,
                statusText: "Invalid KDNA asset",
                detailText: detailText(forFirstIssueCodeIn: input.issueCodes) ?? "Core rejected this KDNA for runtime loading.",
                systemImageName: "exclamationmark.triangle",
                severity: .blocked
            )
        }

        return blocked(
            input,
            statusText: "Action required",
            detailText: "Core requires another step before this KDNA can load.",
            systemImageName: "exclamationmark.circle",
            primaryActionTitle: requiredAction == "none" ? nil : title(fromAction: requiredAction),
            severity: .attention
        )
    }

    private static func blocked(
        _ input: KDNALoadPlanPresentationInput,
        statusText: String,
        detailText: String,
        systemImageName: String,
        primaryActionTitle: String? = nil,
        severity: KDNAAuthorizationPresentationSeverity
    ) -> KDNAAuthorizationPresentation {
        KDNAAuthorizationPresentation(
            assetTitle: input.assetTitle,
            statusText: statusText,
            detailText: detailText,
            severity: severity,
            systemImageName: systemImageName,
            primaryActionTitle: primaryActionTitle,
            canLoadNow: false
        )
    }

    private static func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private static func title(fromAction action: String) -> String? {
        let words = action
            .split(separator: "_")
            .map { word in word.prefix(1).uppercased() + word.dropFirst() }
        return words.isEmpty ? nil : words.joined(separator: " ")
    }

    private static func detailText(forFirstIssueCodeIn issueCodes: [String]) -> String? {
        guard let first = issueCodes.first else { return nil }
        return "Core reported \(first)."
    }
}
