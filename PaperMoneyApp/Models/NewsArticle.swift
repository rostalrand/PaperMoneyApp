import Foundation

public enum MarketSentiment: String, Codable, CaseIterable {
    case bullish = "Bullish"
    case neutral = "Neutral"
    case bearish = "Bearish"

    public var badgeColorHex: String {
        switch self {
        case .bullish: return "#34C759"
        case .neutral: return "#8E8E93"
        case .bearish: return "#FF3B30"
        }
    }
}

/// Represents a financial news headline related to a stock or the broader market
public struct NewsArticle: Identifiable, Codable, Equatable {
    public let id: UUID
    public let symbol: String
    public let title: String
    public let publisher: String
    public let timeAgo: String
    public let snippet: String
    public let sentiment: MarketSentiment

    public init(
        id: UUID = UUID(),
        symbol: String,
        title: String,
        publisher: String,
        timeAgo: String,
        snippet: String,
        sentiment: MarketSentiment = .bullish
    ) {
        self.id = id
        self.symbol = symbol
        self.title = title
        self.publisher = publisher
        self.timeAgo = timeAgo
        self.snippet = snippet
        self.sentiment = sentiment
    }
}
