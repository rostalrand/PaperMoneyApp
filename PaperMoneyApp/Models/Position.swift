import Foundation

/// Represents an active stock holding in the user's paper portfolio
public struct Position: Identifiable, Codable, Equatable {
    public var id: String { symbol }
    public let symbol: String
    public let companyName: String
    public var shares: Double
    public var totalCost: Double

    public var averagePrice: Double {
        guard shares > 0 else { return 0 }
        return totalCost / shares
    }

    public func currentValue(at stockPrice: Double) -> Double {
        return shares * stockPrice
    }

    public func unrealizedPnl(at stockPrice: Double) -> Double {
        return currentValue(at: stockPrice) - totalCost
    }

    public func returnPercent(at stockPrice: Double) -> Double {
        guard totalCost > 0 else { return 0 }
        return (unrealizedPnl(at: stockPrice) / totalCost) * 100
    }

    public init(symbol: String, companyName: String, shares: Double, totalCost: Double) {
        self.symbol = symbol
        self.companyName = companyName
        self.shares = shares
        self.totalCost = totalCost
    }
}
