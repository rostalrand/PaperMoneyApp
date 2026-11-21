import Foundation

public enum AlertCondition: String, Codable, CaseIterable {
    case above = "Rises Above"
    case below = "Drops Below"
}

/// Represents a custom target price alert for any stock or ETF
public struct PriceAlert: Identifiable, Codable, Equatable {
    public let id: UUID
    public let symbol: String
    public let targetPrice: Double
    public let condition: AlertCondition
    public var isTriggered: Bool
    public let createdAt: Date
    public var triggeredAt: Date?

    public init(
        id: UUID = UUID(),
        symbol: String,
        targetPrice: Double,
        condition: AlertCondition,
        isTriggered: Bool = false,
        createdAt: Date = Date(),
        triggeredAt: Date? = nil
    ) {
        self.id = id
        self.symbol = symbol
        self.targetPrice = targetPrice
        self.condition = condition
        self.isTriggered = isTriggered
        self.createdAt = createdAt
        self.triggeredAt = triggeredAt
    }
}
