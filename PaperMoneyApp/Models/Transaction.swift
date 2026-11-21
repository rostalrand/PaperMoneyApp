import Foundation

public enum TransactionType: String, Codable, CaseIterable {
    case deposit = "Deposit"
    case withdraw = "Withdraw"
    case buy = "Buy"
    case sell = "Sell"

    public var iconName: String {
        switch self {
        case .deposit: return "arrow.down.left.circle.fill"
        case .withdraw: return "arrow.up.right.circle.fill"
        case .buy: return "cart.fill.badge.plus"
        case .sell: return "dollarsign.arrow.circlepath"
        }
    }
}

/// Represents a single paper trading activity or cash transfer
public struct Transaction: Identifiable, Codable, Equatable {
    public let id: UUID
    public let timestamp: Date
    public let type: TransactionType
    public let symbol: String?
    public let companyName: String?
    public let shares: Double?
    public let pricePerShare: Double?
    public let totalAmount: Double
    public let note: String?

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        type: TransactionType,
        symbol: String? = nil,
        companyName: String? = nil,
        shares: Double? = nil,
        pricePerShare: Double? = nil,
        totalAmount: Double,
        note: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.symbol = symbol
        self.companyName = companyName
        self.shares = shares
        self.pricePerShare = pricePerShare
        self.totalAmount = totalAmount
        self.note = note
    }
}
