import Foundation

public enum OrderStatus: String, Codable, CaseIterable {
    case pending = "Pending"
    case filled = "Filled"
    case cancelled = "Cancelled"
}

public enum OrderKind: String, Codable, CaseIterable {
    case limit = "Limit"
    case stopLoss = "Stop Loss"
    case takeProfit = "Take Profit"

    public var badgeColorHex: String {
        switch self {
        case .limit: return "#007AFF"
        case .stopLoss: return "#FF3B30"
        case .takeProfit: return "#34C759"
        }
    }
}

/// Represents a pending or historical limit, stop-loss, or take-profit order
public struct LimitOrder: Identifiable, Codable, Equatable {
    public let id: UUID
    public let symbol: String
    public let companyName: String
    public let type: TransactionType // .buy or .sell
    public let kind: OrderKind
    public let shares: Double
    public let targetPrice: Double
    public var status: OrderStatus
    public let createdAt: Date
    public var filledAt: Date?
    public var executionPrice: Double?

    public var totalAmount: Double {
        shares * targetPrice
    }

    public init(
        id: UUID = UUID(),
        symbol: String,
        companyName: String,
        type: TransactionType,
        kind: OrderKind = .limit,
        shares: Double,
        targetPrice: Double,
        status: OrderStatus = .pending,
        createdAt: Date = Date(),
        filledAt: Date? = nil,
        executionPrice: Double? = nil
    ) {
        self.id = id
        self.symbol = symbol
        self.companyName = companyName
        self.type = type
        self.kind = kind
        self.shares = shares
        self.targetPrice = targetPrice
        self.status = status
        self.createdAt = createdAt
        self.filledAt = filledAt
        self.executionPrice = executionPrice
    }

    // Custom Decodable for 100% backward compatibility if kind was omitted in older saved JSON
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.symbol = try container.decode(String.self, forKey: .symbol)
        self.companyName = try container.decode(String.self, forKey: .companyName)
        self.type = try container.decode(TransactionType.self, forKey: .type)
        self.kind = try container.decodeIfPresent(OrderKind.self, forKey: .kind) ?? .limit
        self.shares = try container.decode(Double.self, forKey: .shares)
        self.targetPrice = try container.decode(Double.self, forKey: .targetPrice)
        self.status = try container.decode(OrderStatus.self, forKey: .status)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.filledAt = try container.decodeIfPresent(Date.self, forKey: .filledAt)
        self.executionPrice = try container.decodeIfPresent(Double.self, forKey: .executionPrice)
    }
}
