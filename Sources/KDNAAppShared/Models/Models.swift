import Foundation

public enum MessageRole: String, Codable, CaseIterable {
    case system, user, assistant
}

public struct APIServiceConfig: Codable, Identifiable {
    public let id: String
    public let name: String
    public let provider: String
    public let model: String
    public let baseURL: String
    public var apiKey: String?
    public let contextSize: Int
    public let temperature: Double
}
