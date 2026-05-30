import Foundation

// MARK: - Exa Search Request

public struct ExaSearchRequest: Encodable {
    public let query: String
    public let type: String
    public let numResults: Int
    public let contents: ExaSearchContents
}

public struct ExaSearchContents: Encodable {
    public let highlights: Bool
    public let text: Bool
}

// MARK: - Exa Search Response

public struct ExaSearchResponse: Decodable {
    public let requestId: String?
    public let searchType: String?
    public let results: [ExaSearchResult]
}

// MARK: - Exa Search Result

public struct ExaSearchResult: Decodable, Identifiable {
    public let title: String
    public let url: String
    public let publishedDate: String?
    public let author: String?
    public let highlights: [String]?
    public let summary: String?
    public let text: String?

    public var id: String { url }

    public var content: String {
        if let highlights, !highlights.isEmpty {
            return highlights.joined(separator: "\n")
        }

        if let summary, !summary.isEmpty {
            return summary
        }

        return text ?? ""
    }
}
