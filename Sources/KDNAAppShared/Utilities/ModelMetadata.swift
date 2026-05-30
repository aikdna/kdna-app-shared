import Foundation

/// Pricing information for a model
public struct PricingInfo: Codable {
    public let inputPer1M: Double?          // cost per 1M input tokens (USD)
    public let outputPer1M: Double?         // cost per 1M output tokens (USD)
    public let source: String               // "openai-api", "anthropic-api", "groq-api", "documentation"
    public let lastFetchedDate: Date        // when we last verified this price
    
    public init(inputPer1M: Double?, outputPer1M: Double?, source: String) {
        self.inputPer1M = inputPer1M
        self.outputPer1M = outputPer1M
        self.source = source
        self.lastFetchedDate = Date()
    }
}

/// Source of metadata
public enum MetadataSource: String, Codable {
    case apiResponse          // extracted from provider API response
    case providerDocumentation // manually sourced from official docs
    case cachedStale          // cached but >30 days old (show warning)
    case unknown              // couldn't fetch
}

/// Cost level for display
public enum CostLevel: String, Codable {
    case cheap = "cheap"           // <$1/1M input
    case standard = "standard"     // $1-$10/1M input
    case expensive = "expensive"   // >$10/1M input
}

/// Latency estimate
public enum LatencyLevel: String, Codable {
    case fast = "fast"
    case medium = "medium"
    case slow = "slow"
}

/// Complete metadata for a model
public struct ModelMetadata: Codable {
    public let modelId: String
    public let provider: String
    public let pricing: PricingInfo?
    public let maxContextTokens: Int?
    public let capabilities: [String]       // ["vision", "reasoning", "function-calling"]
    public let supportedParameters: [String]? // Raw provider params when available (e.g. OpenRouter `supported_parameters`)
    public let defaultReasoningEffort: String?
    public let supportedReasoningEfforts: [String]?
    public let supportedReasoningEffortDescriptions: [String: String]?
    public let latency: LatencyLevel?
    public let costLevel: CostLevel?
    public let lastUpdated: Date
    public let source: MetadataSource

    public init(
        modelId: String,
        provider: String,
        pricing: PricingInfo?,
        maxContextTokens: Int?,
        capabilities: [String],
        supportedParameters: [String]? = nil,
        defaultReasoningEffort: String? = nil,
        supportedReasoningEfforts: [String]? = nil,
        supportedReasoningEffortDescriptions: [String: String]? = nil,
        latency: LatencyLevel?,
        costLevel: CostLevel?,
        lastUpdated: Date,
        source: MetadataSource
    ) {
        self.modelId = modelId
        self.provider = provider
        self.pricing = pricing
        self.maxContextTokens = maxContextTokens
        self.capabilities = capabilities
        self.supportedParameters = supportedParameters
        self.defaultReasoningEffort = defaultReasoningEffort
        self.supportedReasoningEfforts = supportedReasoningEfforts
        self.supportedReasoningEffortDescriptions = supportedReasoningEffortDescriptions
        self.latency = latency
        self.costLevel = costLevel
        self.lastUpdated = lastUpdated
        self.source = source
    }
    
    /// Check if metadata is stale (>30 days old)
    public var isStale: Bool {
        let daysSince = Calendar.current.dateComponents([.day], from: lastUpdated, to: Date()).day ?? 0
        return daysSince > 30
    }
    
    /// Get display-friendly cost indicator
    public var costIndicator: String {
        switch costLevel {
        case .cheap:
            return "$"
        case .standard:
            return "$$"
        case .expensive:
            return "$$$"
        case .none:
            return "—"
        }
    }
    
    /// Check if pricing data is available
    public var hasPricing: Bool {
        return pricing != nil && (pricing?.inputPer1M != nil || pricing?.outputPer1M != nil)
    }
    
    // MARK: - Capability Helpers
    
    /// Check if model has a specific capability
    public func hasCapability(_ capability: String) -> Bool {
        return capabilities.contains(capability)
    }
    
    /// Check if model has reasoning capability
    public var hasReasoning: Bool {
        return hasCapability("reasoning")
    }
    
    /// Check if model has vision capability
    public var hasVision: Bool {
        return hasCapability("vision")
    }
    
    /// Check if model has function calling capability
    public var hasFunctionCalling: Bool {
        return hasCapability("function-calling")
    }

    public var suggestedReasoningEffort: ReasoningEffort? {
        guard let defaultReasoningEffort else { return nil }
        return ReasoningEffort.fromProviderValue(defaultReasoningEffort)
    }
}

/// Convenience initializers for hardcoded pricing data
extension PricingInfo {
    /// Groq pricing (typically free)
    public static let groqFree = PricingInfo(
        inputPer1M: 0.0,
        outputPer1M: 0.0,
        source: "documentation"
    )
}

// MARK: - Helper for self-hosted/free models

extension ModelMetadata {
    /// Create free model metadata for self-hosted providers
    public static func freeSelfHosted(modelId: String, provider: String, context: Int?, capabilities: [String] = []) -> ModelMetadata {
        return ModelMetadata(
            modelId: modelId,
            provider: provider,
            pricing: PricingInfo(inputPer1M: 0.0, outputPer1M: 0.0, source: "self-hosted"),
            maxContextTokens: context,
            capabilities: capabilities,
            latency: nil,
            costLevel: .cheap,
            lastUpdated: Date(),
            source: .providerDocumentation
        )
    }
    
    // MARK: - Model Name Formatting
    
    public struct FormattedModelName {
        public let displayName: String
        public let provider: String?
        
        public var fullName: String {
            if let provider = provider {
                return "\(displayName) (\(provider))"
            }
            return displayName
        }
    }
    
    /// Formats a model ID into structured components for display
    public static func formatModelComponents(modelId: String, provider: String? = nil) -> FormattedModelName {
        // Split by "/" if OpenRouter-style format
        let parts = modelId.split(separator: "/")
        let modelName: String
        let providerPrefix: String?
        
        if parts.count == 2 {
            providerPrefix = String(parts[0])
            modelName = String(parts[1])
        } else {
            providerPrefix = provider
            modelName = modelId
        }
        
        let formatted = Self.formatModelName(modelName)
        let providerDisplay = providerPrefix.map { Self.mapProviderName($0).uppercased() }
        
        return FormattedModelName(displayName: formatted, provider: providerDisplay)
    }
    
    /// Formats a model ID into a human-readable display name
    /// Example: "x-ai/grok-code-fast-1" → "Grok Code Fast 1 (XAI)"
    public static func formatModelDisplayName(modelId: String, provider: String? = nil) -> String {
        return formatModelComponents(modelId: modelId, provider: provider).fullName
    }

    public static func modelNamespaceID(from modelId: String) -> String? {
        let parts = modelId.split(separator: "/", maxSplits: 1)
        guard parts.count == 2 else { return nil }
        return String(parts[0])
    }

    public static func providerDisplayName(for providerId: String) -> String {
        mapProviderName(providerId)
    }

    public static func modelNamespaceDisplayName(from modelId: String) -> String? {
        guard let namespace = modelNamespaceID(from: modelId) else { return nil }
        return providerDisplayName(for: namespace)
    }

    public static func groupModelIDsByNamespace(modelIds: [String]) -> [(namespaceDisplayName: String, modelIds: [String])] {
        var buckets: [String: [String]] = [:]

        for modelId in modelIds {
            let namespace = modelNamespaceDisplayName(from: modelId) ?? "OTHER"
            buckets[namespace, default: []].append(modelId)
        }

        return buckets
            .map { (namespaceDisplayName: $0.key, modelIds: $0.value.sorted()) }
            .sorted { lhs, rhs in
                if lhs.namespaceDisplayName == "OTHER" { return false }
                if rhs.namespaceDisplayName == "OTHER" { return true }
                return lhs.namespaceDisplayName < rhs.namespaceDisplayName
            }
    }
    
    private static func formatModelName(_ modelName: String) -> String {
        let name = modelName
        
        // Known model name mappings for cleaner display
        let knownModels: [String: String] = [
            "gpt-4o": "GPT-4o",
            "gpt-4o-mini": "GPT-4o Mini",
            "gpt-4-turbo": "GPT-4 Turbo",
            "gpt-4": "GPT-4",
            "gpt-3.5-turbo": "GPT-3.5 Turbo",
            "claude-3-5-sonnet": "Claude 3.5 Sonnet",
            "claude-3-5-haiku": "Claude 3.5 Haiku",
            "claude-3-opus": "Claude 3 Opus",
            "claude-3-sonnet": "Claude 3 Sonnet",
            "claude-3-haiku": "Claude 3 Haiku",
            "claude-sonnet-4": "Claude Sonnet 4",
            "claude-4-sonnet": "Claude Sonnet 4",
            "claude-opus-4": "Claude Opus 4",
            "claude-4-opus": "Claude Opus 4",
            "claude-haiku-4": "Claude Haiku 4",
            "claude-4-haiku": "Claude Haiku 4",
            "gemini-1.5-pro": "Gemini 1.5 Pro",
            "gemini-1.5-flash": "Gemini 1.5 Flash",
            "gemini-2.0-flash": "Gemini 2.0 Flash",
            "gemini-pro": "Gemini Pro",
            "llama-3.1-70b": "Llama 3.1 70B",
            "llama-3.1-8b": "Llama 3.1 8B",
            "llama-3-70b": "Llama 3 70B",
            "llama-3-8b": "Llama 3 8B",
            "mixtral-8x7b": "Mixtral 8x7B",
            "mistral-large": "Mistral Large",
            "mistral-medium": "Mistral Medium",
            "mistral-small": "Mistral Small",
            "deepseek-chat": "DeepSeek Chat",
            "deepseek-coder": "DeepSeek Coder",
            "deepseek-r1": "DeepSeek R1",
            "grok-2": "Grok 2",
            "grok-beta": "Grok Beta",
            "o1-preview": "O1 Preview",
            "o1-mini": "O1 Mini",
            "o1": "O1",
            "o3": "O3",
            "o3-mini": "O3 Mini",
        ]
        
        // Check for exact or prefix match first (case-insensitive)
        let lowerName = name.lowercased()
        let sortedKnownModelKeys = knownModels.keys.sorted { $0.count > $1.count }
        for key in sortedKnownModelKeys {
            let lowerKey = key.lowercased()
            guard let value = knownModels[key] else { continue }

            if lowerName == lowerKey {
                return value
            }

            guard lowerName.hasPrefix(lowerKey), name.count > key.count else { continue }
            let suffix = String(name.dropFirst(key.count))
            guard suffix.hasPrefix("-") || suffix.hasPrefix("@") else { continue }

            let suffixValue = String(suffix.dropFirst())
            if suffixValue.isEmpty {
                return value
            }

            return formatKnownModelDisplay(baseDisplayName: value, suffix: suffixValue)
        }
        
        // Generic formatting: convert kebab-case/snake_case to Title Case
        // But preserve version numbers and special tokens
        let tokens = name
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
        
        let formatted = tokens.map { token -> String in
            let str = String(token)
            
            // Keep version numbers as-is (e.g., "3.5", "4o", "8x7b")
            if str.first?.isNumber == true || str.contains(".") {
                return str
            }
            
            // Keep size indicators uppercase (e.g., "70B", "8B")
            if str.hasSuffix("b") || str.hasSuffix("B"), let _ = Int(str.dropLast()) {
                return str.uppercased()
            }
            
            // Capitalize normally
            return str.capitalized
        }.joined(separator: " ")
        
        return formatted
    }

    private static func formatKnownModelDisplay(baseDisplayName: String, suffix: String) -> String {
        let normalizedSuffix = suffix.replacingOccurrences(of: "_", with: "-")
        let suffixTokens = normalizedSuffix.split(separator: "-").map(String.init)

        // Handle patterns like:
        // - `...-5` -> `... 4.5`
        // - `...-20250514` -> `... 4 (20250514)`
        // - `...-5-20250514` -> `... 4.5 (20250514)`
        if baseDisplayName.last?.isNumber == true, !suffixTokens.isEmpty {
            if suffixTokens.count == 1 {
                let token = suffixTokens[0]
                if isShortNumericVersionToken(token) {
                    return "\(baseDisplayName).\(token)"
                }
                if isDateToken(token) {
                    return "\(baseDisplayName) (\(token))"
                }
            } else if suffixTokens.count == 2 {
                let pointToken = suffixTokens[0]
                let dateToken = suffixTokens[1]
                if isShortNumericVersionToken(pointToken), isDateToken(dateToken) {
                    return "\(baseDisplayName).\(pointToken) (\(dateToken))"
                }
            }
        }

        return "\(baseDisplayName) (\(normalizedSuffix))"
    }

    private static func isShortNumericVersionToken(_ token: String) -> Bool {
        guard token.allSatisfy(\.isNumber) else { return false }
        return token.count <= 2
    }

    private static func isDateToken(_ token: String) -> Bool {
        guard token.count == 8, token.allSatisfy(\.isNumber) else { return false }
        return true
    }
    
    private static func mapProviderName(_ provider: String) -> String {
        let mapping: [String: String] = [
            "x-ai": "XAI",
            "xai": "XAI",
            "anthropic": "ANTHROPIC",
            "openai": "OPENAI",
            "chatgpt": "OPENAI",
            "codex": "OPENAI",
            "google": "GOOGLE",
            "gemini": "GOOGLE",
            "meta": "META",
            "meta-llama": "META",
            "mistralai": "MISTRAL",
            "mistral": "MISTRAL",
            "cohere": "COHERE",
            "perplexity": "PERPLEXITY",
            "deepseek": "DEEPSEEK",
            "pollinations": "POLLINATIONS",
            "qwen": "QWEN",
            "nvidia": "NVIDIA",
            "groq": "GROQ",
            "ollama": "OLLAMA",
            "openrouter": "OPENROUTER",
            "lmstudio": "LMSTUDIO",
            "claude": "ANTHROPIC",
        ]
        return mapping[provider.lowercased()] ?? provider.uppercased()
    }
}
