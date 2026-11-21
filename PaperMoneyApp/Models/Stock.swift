import Foundation

/// Represents a financial stock security in the paper market
public struct Stock: Identifiable, Codable, Equatable, Hashable {
    public var id: String { symbol }
    public let symbol: String
    public let name: String
    public var currentPrice: Double
    public let previousClose: Double
    public var sparkline: [Double]
    public let marketCap: String
    public let peRatio: Double?
    public let high52: Double
    public let low52: Double
    public let volume: String
    public let sector: String
    public let about: String

    public var change: Double {
        currentPrice - previousClose
    }

    public var changePercent: Double {
        guard previousClose > 0 else { return 0 }
        return (change / previousClose) * 100
    }

    public var isPositive: Bool {
        change >= 0
    }

    public init(
        symbol: String,
        name: String,
        currentPrice: Double,
        previousClose: Double,
        sparkline: [Double],
        marketCap: String,
        peRatio: Double? = nil,
        high52: Double,
        low52: Double,
        volume: String,
        sector: String,
        about: String
    ) {
        self.symbol = symbol
        self.name = name
        self.currentPrice = currentPrice
        self.previousClose = previousClose
        self.sparkline = sparkline
        self.marketCap = marketCap
        self.peRatio = peRatio
        self.high52 = high52
        self.low52 = low52
        self.volume = volume
        self.sector = sector
        self.about = about
    }
}

public struct ChartDataPoint: Identifiable, Codable, Equatable, Hashable {
    public let id: UUID
    public let timestamp: Date
    public let price: Double

    public init(id: UUID = UUID(), timestamp: Date, price: Double) {
        self.id = id
        self.timestamp = timestamp
        self.price = price
    }
}

public struct CandlestickPoint: Identifiable, Codable, Equatable, Hashable {
    public let id: UUID
    public let timestamp: Date
    public let open: Double
    public let high: Double
    public let low: Double
    public let close: Double

    public var isBullish: Bool {
        close >= open
    }

    public init(
        id: UUID = UUID(),
        timestamp: Date,
        open: Double,
        high: Double,
        low: Double,
        close: Double
    ) {
        self.id = id
        self.timestamp = timestamp
        self.open = open
        self.high = high
        self.low = low
        self.close = close
    }
}

public enum ChartTimeframe: String, CaseIterable, Identifiable {
    case oneDay = "1D"
    case oneWeek = "1W"
    case oneMonth = "1M"
    case oneYear = "1Y"
    case all = "ALL"

    public var id: String { rawValue }
}
