import Foundation

public enum ProviderID: String, Codable, CaseIterable, Sendable {
    case chatgpt
    case codex
    case claude
    case gemini
    case groq
    case openrouter
    case mistral
    case xai
    case perplexity
    case deepseek
    case moonshot
    case qwen
    case zhipu
    case siliconflow
    case hunyuan
    case doubao
    case pollinations
    case fireworks
    case ollama
    case lmstudio
}

extension ProviderID {
    public init?(normalizing input: String) {
        let normalized = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalized {
        case "chatgpt", "chat gpt", "openai":
            self = .chatgpt
        case "codex", "codex app server", "codex_app_server":
            self = .codex
        case "claude", "anthropic":
            self = .claude
        case "gemini", "google":
            self = .gemini
        case "groq":
            self = .groq
        case "openrouter", "open router":
            self = .openrouter
        case "mistral":
            self = .mistral
        case "xai":
            self = .xai
        case "perplexity":
            self = .perplexity
        case "deepseek":
            self = .deepseek
        case "moonshot", "kimi", "kimi / moonshot":
            self = .moonshot
        case "qwen", "aliyun", "alibaba", "阿里云百炼":
            self = .qwen
        case "zhipu", "bigmodel", "智谱 bigmodel":
            self = .zhipu
        case "siliconflow", "silicon flow":
            self = .siliconflow
        case "hunyuan", "tencent", "腾讯混元":
            self = .hunyuan
        case "doubao", "volcengine", "ark", "豆包", "火山方舟":
            self = .doubao
        case "pollinations", "pollinations ai":
            self = .pollinations
        case "fireworks", "fireworks ai":
            self = .fireworks
        case "ollama":
            self = .ollama
        case "lmstudio", "lm studio":
            self = .lmstudio
        default:
            return nil
        }
    }
}

public struct ProviderAttachmentCapabilities: Sendable {
    public let providerID: ProviderID
    public let supportsImageInputs: Bool
    public let supportsNativeFileInputs: Bool

    public static func forProvider(_ providerID: ProviderID) -> ProviderAttachmentCapabilities {
        switch providerID {
        case .chatgpt:
            return ProviderAttachmentCapabilities(
                providerID: providerID,
                supportsImageInputs: true,
                supportsNativeFileInputs: true
            )
        case .codex:
            return ProviderAttachmentCapabilities(
                providerID: providerID,
                supportsImageInputs: false,
                supportsNativeFileInputs: false
            )
        case .claude:
            return ProviderAttachmentCapabilities(
                providerID: providerID,
                supportsImageInputs: true,
                supportsNativeFileInputs: true
            )

        case .deepseek, .doubao, .fireworks, .gemini, .hunyuan, .lmstudio, .moonshot, .openrouter, .pollinations, .qwen, .siliconflow, .xai, .zhipu:
            return ProviderAttachmentCapabilities(
                providerID: providerID,
                supportsImageInputs: true,
                supportsNativeFileInputs: false
            )

        case .mistral, .ollama, .perplexity, .groq:
            return ProviderAttachmentCapabilities(
                providerID: providerID,
                supportsImageInputs: false,
                supportsNativeFileInputs: false
            )
        }
    }

    public var composerSummary: String {
        var parts: [String] = []
        parts.reserveCapacity(2)

        if supportsNativeFileInputs {
            parts.append("Files: sent as native attachments when supported")
        } else {
            parts.append("Files: sent as extracted text")
        }

        if supportsImageInputs {
            parts.append("Images: supported")
        } else {
            parts.append("Images: not supported")
        }

        return parts.joined(separator: " • ")
    }
}
