import Foundation

public struct PortfolioSummary: Equatable {
    public let cashBalance: Double
    public let investedEquity: Double
    public let totalCostBasis: Double
    public let totalDeposited: Double

    public var totalValue: Double {
        cashBalance + investedEquity
    }

    public var unrealizedReturn: Double {
        investedEquity - totalCostBasis
    }

    public var unrealizedReturnPercent: Double {
        guard totalCostBasis > 0 else { return 0 }
        return (unrealizedReturn / totalCostBasis) * 100
    }

    public var totalAllTimeReturn: Double {
        guard totalDeposited > 0 else { return 0 }
        return totalValue - totalDeposited
    }

    public var totalAllTimeReturnPercent: Double {
        guard totalDeposited > 0 else { return 0 }
        return (totalAllTimeReturn / totalDeposited) * 100
    }

    public init(
        cashBalance: Double,
        investedEquity: Double,
        totalCostBasis: Double,
        totalDeposited: Double
    ) {
        self.cashBalance = cashBalance
        self.investedEquity = investedEquity
        self.totalCostBasis = totalCostBasis
        self.totalDeposited = totalDeposited
    }
}
