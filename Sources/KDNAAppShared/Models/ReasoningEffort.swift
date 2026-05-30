import Foundation

public enum ReasoningEffort: String, Codable, CaseIterable, Sendable {
    case off
    case low
    case medium
    case high
    case extraHigh

    public var displayName: String {
        switch self {
        case .off: "Off"
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        case .extraHigh: "Extra High"
        }
    }

    public var openAIReasoningEffortValue: String {
        switch self {
        case .off: "none"
        case .low: "low"
        case .medium: "medium"
        case .high: "high"
        case .extraHigh: "xhigh"
        }
    }

    public var openRouterReasoningEffortValue: String {
        switch self {
        case .off: "none"
        case .low: "low"
        case .medium: "medium"
        case .high: "high"
        case .extraHigh: "xhigh"
        }
    }

    public var anthropicThinkingBudgetTokens: Int? {
        switch self {
        case .off:
            return nil
        case .low:
            return 1024
        case .medium:
            return 4096
        case .high:
            return 16384
        case .extraHigh:
            return 32768
        }
    }

    public var openRouterMaxTokens: Int? {
        switch self {
        case .off:
            return nil
        case .low:
            return 2048
        case .medium:
            return 8192
        case .high:
            return 16384
        case .extraHigh:
            return 32768
        }
    }

    public static func fromProviderValue(_ value: String) -> ReasoningEffort? {
        switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "none", "off":
            return .off
        case "low":
            return .low
        case "medium":
            return .medium
        case "high":
            return .high
        case "xhigh", "extra_high", "extra-high":
            return .extraHigh
        default:
            return nil
        }
    }
}

public struct GenerationSettings: Codable, Sendable, Equatable {
    public var temperature: Float
    public var reasoningEffort: ReasoningEffort

    init(temperature: Float, reasoningEffort: ReasoningEffort = .off) {
        self.temperature = temperature
        self.reasoningEffort = reasoningEffort
    }
}
