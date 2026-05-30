import Foundation

// MARK: - Tavily Search Request

public struct TavilySearchRequest: Codable {
    public init(apiKey: String, query: String, searchDepth: String = "basic", includeImages: Bool = false, includeAnswer: Bool = false, includeRawContent: Bool = false, maxResults: Int = 5) {
        self.apiKey = apiKey; self.query = query; self.searchDepth = searchDepth; self.includeImages = includeImages; self.includeAnswer = includeAnswer; self.includeRawContent = includeRawContent; self.maxResults = maxResults
    }

    public let apiKey: String
    public let query: String
    public let searchDepth: String
    public let includeImages: Bool
    public let includeAnswer: Bool
    public let includeRawContent: Bool
    public let maxResults: Int
    
    public enum CodingKeys: String, CodingKey {
        case apiKey = "api_key"
        case query
        case searchDepth = "search_depth"
        case includeImages = "include_images"
        case includeAnswer = "include_answer"
        case includeRawContent = "include_raw_content"
        case maxResults = "max_results"
    }
}

// MARK: - Tavily Search Response

public struct TavilySearchResponse: Codable {
    public let answer: String?
    public let query: String
    public let responseTime: Double
    public let images: [String]
    public let results: [TavilySearchResult]
    
    public enum CodingKeys: String, CodingKey {
        case answer
        case query
        case responseTime = "response_time"
        case images
        case results
    }
}

// MARK: - Tavily Search Result

public struct TavilySearchResult: Codable, Identifiable {
    public let title: String
    public let url: String
    public let content: String
    public let score: Double
    public let publishedDate: String?

    public var id: String { url }
    
    public enum CodingKeys: String, CodingKey {
        case title
        case url
        case content
        case score
        case publishedDate = "published_date"
    }
}
