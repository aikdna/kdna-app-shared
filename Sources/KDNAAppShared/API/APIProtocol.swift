import Foundation
import KDNACore

public enum APIError: Error {
    case requestFailed(Error)
    case invalidResponse
    case decodingFailed(String)
    case unauthorized
    case rateLimited
    case serverError(String)
    case unknown(String)
    case noApiService(String)
}

public struct ToolCall: Codable {
    public let id: String
    public let type: String
    public let function: FunctionCall

    public struct FunctionCall: Codable {
        public let name: String
        public let arguments: String
    }

    public init(id: String, type: String, function: FunctionCall) {
        self.id = id
        self.type = type
        self.function = function
    }
}

/// Controls whether a handler should attempt provider-native file/document attachments,
/// or force all non-image attachments to be inlined as extracted text.
public enum AttachmentPolicy: String, Sendable {
    case preferProviderAttachments
    case inlineTextOnly
}

public protocol APIService {
    var name: String { get }
    var baseURL: URL { get }
    var session: URLSession { get }
    var model: String { get }
    var logger: KDNALogger { get }

    func sendMessage(
        _ requestMessages: [[String: String]],
        tools: [[String: Any]]?,
        settings: GenerationSettings,
        completion: @escaping (Result<(String?, [ToolCall]?), APIError>) -> Void
    )

    func sendMessageStream(
        _ requestMessages: [[String: String]],
        tools: [[String: Any]]?,
        settings: GenerationSettings
    ) async throws -> AsyncThrowingStream<(String?, [ToolCall]?), Error>

    func fetchModels() async throws -> [AIModel]

    func prepareRequest(
        requestMessages: [[String: String]],
        tools: [[String: Any]]?,
        model: String,
        settings: GenerationSettings,
        attachmentPolicy: AttachmentPolicy,
        stream: Bool
    ) async throws -> URLRequest

    func parseJSONResponse(data: Data) -> (String?, String?, [ToolCall]?)?

    func parseDeltaJSONResponse(data: Data?) -> (Bool, Error?, String?, String?, [ToolCall]?)
}

public protocol APIServiceConfiguration {
    var name: String { get set }
    var apiUrl: URL { get set }
    var apiKey: String { get set }
    var model: String { get set }
}

public struct AIModel: Codable, Identifiable {
    public let id: String

    public init(id: String) {
        self.id = id
    }
}

// MARK: - Default Implementations

extension APIService {
    public func fetchModels() async throws -> [AIModel] {
        return []
    }

    public func handleAPIResponse(_ response: URLResponse?, data: Data?, error: Error?) -> Result<Data?, APIError> {
        if let error = error {
            return .failure(.requestFailed(error))
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            return .failure(.invalidResponse)
        }

        if !(200...299).contains(httpResponse.statusCode) {
            if let data = data, let errorResponse = String(data: data, encoding: .utf8) {
                switch httpResponse.statusCode {
                case 401:
                    return .failure(.unauthorized)
                case 429:
                    return .failure(.rateLimited)
                case 400...499:
                    return .failure(.serverError("Client Error: \(errorResponse)"))
                case 500...599:
                    return .failure(.serverError("Server Error: \(errorResponse)"))
                default:
                    return .failure(.unknown("Unknown error: \(errorResponse)"))
                }
            } else {
                return .failure(.serverError("HTTP \(httpResponse.statusCode)"))
            }
        }

        return .success(data)
    }

    public func isNotSSEComment(_ string: String) -> Bool {
        return !string.starts(with: ":")
    }

    public func sendMessage(
        _ requestMessages: [[String: String]],
        tools: [[String: Any]]? = nil,
        settings: GenerationSettings
    ) async throws -> (String?, [ToolCall]?) {
        func execute(settings: GenerationSettings, attachmentPolicy: AttachmentPolicy) async throws -> (String?, [ToolCall]?) {
            let request = try await prepareRequest(
                requestMessages: requestMessages,
                tools: tools,
                model: model,
                settings: settings,
                attachmentPolicy: attachmentPolicy,
                stream: false
            )

            let (data, response) = try await session.data(for: request)
            let result = self.handleAPIResponse(response, data: data, error: nil)

            switch result {
            case .success(let responseData):
                if let responseData = responseData {
                    guard let (messageContent, _, toolCalls) = self.parseJSONResponse(data: responseData) else {
                        #if DEBUG
                        logger.debug("Default parsing failed. Handler: \(self.name). Response bytes: \(responseData.count)")
                        #endif
                        throw APIError.decodingFailed("Failed to parse response")
                    }
                    return (messageContent, toolCalls)
                } else {
                    throw APIError.invalidResponse
                }

            case .failure(let error):
                throw error
            }
        }

        var attemptSettings = settings
        var didRetryWithoutReasoning = false
        var attachmentPolicy: AttachmentPolicy = .preferProviderAttachments
        var didRetryWithoutAttachments = false

        while true {
            do {
                return try await execute(settings: attemptSettings, attachmentPolicy: attachmentPolicy)
            } catch let error as APIError {
                if !didRetryWithoutAttachments,
                   AttachmentCompatibility.shouldRetryWithoutFileAttachments(attachmentPolicy: attachmentPolicy, error: error) {
                    didRetryWithoutAttachments = true
                    attachmentPolicy = .inlineTextOnly
                    logger.notice("Retrying request without file attachments due to unsupported parameter (provider: \(self.name))")
                    continue
                }

                if !didRetryWithoutReasoning,
                   ReasoningCompatibility.shouldRetryWithoutReasoning(settings: attemptSettings, error: error) {
                    didRetryWithoutReasoning = true
                    attemptSettings = GenerationSettings(temperature: attemptSettings.temperature, reasoningEffort: .off)
                    logger.notice("Retrying request without reasoning fields due to unsupported parameter (provider: \(self.name))")
                    continue
                }

                throw error
            }
        }
    }
}

public enum ReasoningCompatibility {
    public static func shouldRetryWithoutReasoning(settings: GenerationSettings, error: APIError) -> Bool {
        guard settings.reasoningEffort != .off else { return false }

        let errorText: String
        switch error {
        case .serverError(let message):
            errorText = message
        case .unknown(let message):
            errorText = message
        default:
            return false
        }

        let lower = errorText.lowercased()
        let hasReasoningParam = lower.contains("reasoning_effort")
            || lower.contains("include_reasoning")
            || lower.contains("\"reasoning\"")
            || lower.contains("thinking")

        guard hasReasoningParam else { return false }

        return lower.contains("unknown")
            || lower.contains("unrecognized")
            || lower.contains("unsupported")
            || lower.contains("invalid")
            || lower.contains("not allowed")
            || lower.contains("additional properties")
            || lower.contains("not supported")
    }
}

public enum AttachmentCompatibility {
    public static func shouldRetryWithoutFileAttachments(attachmentPolicy: AttachmentPolicy, error: APIError) -> Bool {
        guard attachmentPolicy != .inlineTextOnly else { return false }

        let errorText: String
        switch error {
        case .serverError(let message):
            errorText = message
        case .unknown(let message):
            errorText = message
        default:
            return false
        }

        let lower = errorText.lowercased()
        let mentionsAttachmentFields = lower.contains("document")
            || lower.contains("file")
            || lower.contains("attachment")
            || lower.contains("media_type")
            || lower.contains("input_file")
            || lower.contains("file_data")
            || lower.contains("filename")

        guard mentionsAttachmentFields else { return false }

        return lower.contains("unknown")
            || lower.contains("unrecognized")
            || lower.contains("unsupported")
            || lower.contains("invalid")
            || lower.contains("not allowed")
            || lower.contains("additional properties")
            || lower.contains("not supported")
    }
}
