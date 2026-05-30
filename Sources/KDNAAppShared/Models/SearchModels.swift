import Foundation

public struct SearchResult: Codable, Identifiable, Equatable {
    public let id = UUID()
    public let title: String
    public let url: String
    public let snippet: String
    
    enum CodingKeys: String, CodingKey { case title, url, snippet }
}

public struct SearchQuery: Codable {
    public let query: String
    public let engine: String
}
