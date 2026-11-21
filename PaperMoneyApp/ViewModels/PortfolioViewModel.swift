import Foundation
import Combine
import SwiftUI

public enum TradeError: LocalizedError {
    case insufficientFunds(required: Double, available: Double)
    case insufficientShares(owned: Double, requested: Double)
    case invalidAmount

    public var errorDescription: String? {
        switch self {
        case .insufficientFunds(let required, let available):
            return "Insufficient paper funds. Required: $\(String(format: "%.2f", required)), Available: $\(String(format: "%.2f", available))"
        case .insufficientShares(let owned, let requested):
            return "Cannot sell \(String(format: "%.2f", requested)) shares. You only own \(String(format: "%.2f", owned)) shares."
        case .invalidAmount:
            return "Please enter a valid amount greater than zero."
        }
    }
}

@MainActor
public final class PortfolioViewModel: ObservableObject {
    @Published public var cashBalance: Double = 100_000.0
    @Published public var totalDeposited: Double = 100_000.0
    @Published public var positions: [Position] = []
    @Published public var transactions: [Transaction] = []
    @Published public var stocks: [Stock] = []
    @Published public var watchlistSymbols: Set<String> = []
    @Published public var pendingOrders: [LimitOrder] = []
    @Published public var portfolioSnapshots: [ChartDataPoint] = []
    @Published public var priceAlerts: [PriceAlert] = []
    @Published public var isPrivacyMode: Bool = false

    @Published public var bannerMessage: String? = nil
    @Published public var showBanner: Bool = false

    private let storage: StorageService
    private let marketService: MarketDataService
    private var timerCancellable: AnyCancellable?

    public init(
        storage: StorageService = .shared,
        marketService: MarketDataService = .shared
    ) {
        self.storage = storage
        self.marketService = marketService

        loadPersistedData()
        startLiveMarketSimulation()

        // Fetch real-time live quotes on launch
        Task {
            await self.fetchLiveMarketData()
        }
    }

    // MARK: - Live Network Refresh
    public func fetchLiveMarketData() async {
        for (index, stock) in stocks.enumerated() {
            if let live = await marketService.fetchLiveStockQuote(for: stock.symbol) {
                var updated = stock
                updated.currentPrice = live.price
                if !updated.sparkline.isEmpty {
                    updated.sparkline[updated.sparkline.count - 1] = live.price
                }
                self.stocks[index] = updated
            }
        }
        self.checkAndExecuteLimitOrders(for: self.stocks)
    }

    private func loadPersistedData() {
        if !storage.hasInitialized {
            // First run: Seed initial welcome paper deposit of $100,000
            self.cashBalance = 100_000.0
            self.totalDeposited = 100_000.0
            self.positions = []
            self.transactions = [
                Transaction(
                    type: .deposit,
                    totalAmount: 100_000.0,
                    note: "Initial Paper Money Welcome Grant"
                )
            ]
            self.watchlistSymbols = ["AAPL", "NVDA", "TSLA", "SPY"]
            self.pendingOrders = []
            self.priceAlerts = []
            self.portfolioSnapshots = [
                ChartDataPoint(timestamp: Date().addingTimeInterval(-86400 * 7), price: 100_000.0),
                ChartDataPoint(timestamp: Date(), price: 100_000.0)
            ]
            self.stocks = marketService.getInitialStocks()

            saveAll()
            storage.markInitialized()
        } else {
            self.cashBalance = storage.loadCashBalance()
            self.totalDeposited = storage.loadTotalDeposited()
            self.positions = storage.loadPositions()
            self.transactions = storage.loadTransactions()
            self.watchlistSymbols = storage.loadWatchlist()
            self.pendingOrders = storage.loadLimitOrders()
            self.priceAlerts = storage.loadPriceAlerts()
            let savedSnapshots = storage.loadPortfolioSnapshots()
            self.portfolioSnapshots = savedSnapshots.isEmpty ? [
                ChartDataPoint(timestamp: Date().addingTimeInterval(-86400), price: self.cashBalance),
                ChartDataPoint(timestamp: Date(), price: self.cashBalance)
            ] : savedSnapshots
            self.stocks = marketService.getInitialStocks()
        }
    }

    private func saveAll() {
        storage.saveCashBalance(cashBalance)
        storage.saveTotalDeposited(totalDeposited)
        storage.savePositions(positions)
        storage.saveTransactions(transactions)
        storage.saveWatchlist(watchlistSymbols)
        storage.saveLimitOrders(pendingOrders)
        storage.savePriceAlerts(priceAlerts)
        storage.savePortfolioSnapshots(portfolioSnapshots)
    }

    // MARK: - Computed Portfolio Metrics
    public var summary: PortfolioSummary {
        let investedEquity = positions.reduce(0.0) { sum, pos in
            let stockPrice = getStock(for: pos.symbol)?.currentPrice ?? pos.averagePrice
            return sum + pos.currentValue(at: stockPrice)
        }

        let totalCostBasis = positions.reduce(0.0) { sum, pos in
            sum + pos.totalCost
        }

        return PortfolioSummary(
            cashBalance: cashBalance,
            investedEquity: investedEquity,
            totalCostBasis: totalCostBasis,
            totalDeposited: totalDeposited
        )
    }

    public func getStock(for symbol: String) -> Stock? {
        stocks.first { $0.symbol == symbol }
    }

    public func getPosition(for symbol: String) -> Position? {
        positions.first { $0.symbol == symbol }
    }

    public var watchlistStocks: [Stock] {
        stocks.filter { watchlistSymbols.contains($0.symbol) }
    }

    // MARK: - Cash Management (Deposit / Withdraw)
    public func depositCash(amount: Double, note: String = "Manual Paper Deposit") {
        guard amount > 0 else { return }

        cashBalance += amount
        totalDeposited += amount

        let tx = Transaction(
            type: .deposit,
            totalAmount: amount,
            note: note
        )
        transactions.insert(tx, at: 0)

        saveAll()
        showNotification(message: "Deposited +$\(formatCurrency(amount)) paper cash!")
        recordSnapshot()
        HapticsService.shared.notification(type: .success)
    }

    // MARK: - Trading Operations
    public func buyStock(symbol: String, shares: Double) -> Result<Void, TradeError> {
        guard shares > 0 else { return .failure(.invalidAmount) }
        guard let stock = getStock(for: symbol) else { return .failure(.invalidAmount) }

        let totalCost = shares * stock.currentPrice
        guard cashBalance >= totalCost else {
            return .failure(.insufficientFunds(required: totalCost, available: cashBalance))
        }

        // Deduct cash
        cashBalance -= totalCost

        // Update or add position
        if let index = positions.firstIndex(where: { $0.symbol == symbol }) {
            var existing = positions[index]
            let updatedShares = existing.shares + shares
            let updatedCost = existing.totalCost + totalCost
            existing.shares = updatedShares
            existing.totalCost = updatedCost
            positions[index] = existing
        } else {
            let newPosition = Position(
                symbol: symbol,
                companyName: stock.name,
                shares: shares,
                totalCost: totalCost
            )
            positions.append(newPosition)
        }

        // Record transaction
        let tx = Transaction(
            type: .buy,
            symbol: symbol,
            companyName: stock.name,
            shares: shares,
            pricePerShare: stock.currentPrice,
            totalAmount: totalCost,
            note: "Market Buy Execution"
        )
        transactions.insert(tx, at: 0)

        saveAll()
        showNotification(message: "Bought \(String(format: "%.2f", shares)) \(symbol) for $\(formatCurrency(totalCost))")
        recordSnapshot()
        HapticsService.shared.notification(type: .success)
        return .success(())
    }

    public func sellStock(symbol: String, shares: Double) -> Result<Void, TradeError> {
        guard shares > 0 else { return .failure(.invalidAmount) }
        guard let stock = getStock(for: symbol) else { return .failure(.invalidAmount) }
        guard let index = positions.firstIndex(where: { $0.symbol == symbol }) else {
            return .failure(.insufficientShares(owned: 0, requested: shares))
        }

        var existing = positions[index]
        guard existing.shares >= shares else {
            return .failure(.insufficientShares(owned: existing.shares, requested: shares))
        }

        let proceeds = shares * stock.currentPrice
        cashBalance += proceeds

        let costPerShare = existing.averagePrice
        let costSold = shares * costPerShare

        if abs(existing.shares - shares) < 0.0001 {
            // Sold entire holding
            positions.remove(at: index)
        } else {
            existing.shares -= shares
            existing.totalCost -= costSold
            positions[index] = existing
        }

        // Record transaction
        let tx = Transaction(
            type: .sell,
            symbol: symbol,
            companyName: stock.name,
            shares: shares,
            pricePerShare: stock.currentPrice,
            totalAmount: proceeds,
            note: "Market Sell Execution"
        )
        transactions.insert(tx, at: 0)

        saveAll()
        showNotification(message: "Sold \(String(format: "%.2f", shares)) \(symbol) for +$\(formatCurrency(proceeds))")
        recordSnapshot()
        HapticsService.shared.notification(type: .success)
        return .success(())
    }

    // MARK: - Watchlist Management
    public func toggleWatchlist(symbol: String) {
        if watchlistSymbols.contains(symbol) {
            watchlistSymbols.remove(symbol)
        } else {
            watchlistSymbols.insert(symbol)
        }
        storage.saveWatchlist(watchlistSymbols)
    }

    public func isWatchlisted(symbol: String) -> Bool {
        watchlistSymbols.contains(symbol)
    }

    // MARK: - Account Reset
    public func resetAccount(startingDeposit: Double = 100_000.0) {
        storage.clearAll()
        cashBalance = startingDeposit
        totalDeposited = startingDeposit
        positions = []
        transactions = [
            Transaction(
                type: .deposit,
                totalAmount: startingDeposit,
                note: "Fresh Paper Trading Account Reset"
            )
        ]
        watchlistSymbols = ["AAPL", "NVDA", "TSLA", "SPY"]
        pendingOrders = []
        priceAlerts = []
        saveAll()
        storage.markInitialized()
        showNotification(message: "Account reset to $\(formatCurrency(startingDeposit))")
    }

    // MARK: - Live Market Simulation
    private func startLiveMarketSimulation() {
        // Ticks every 4 seconds to simulate active trading
        timerCancellable = Timer.publish(every: 4.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.stocks = self.marketService.simulatePriceTicks(for: self.stocks)
                self.checkAndExecuteLimitOrders(for: self.stocks)
                self.checkPriceAlerts(for: self.stocks)
            }
    }

    // MARK: - Asset Allocation
    public struct AssetSlice: Identifiable, Equatable {
        public var id: String { symbol }
        public let symbol: String
        public let name: String
        public let value: Double
        public let percentage: Double
        public let colorHex: String

        public init(symbol: String, name: String, value: Double, percentage: Double, colorHex: String) {
            self.symbol = symbol
            self.name = name
            self.value = value
            self.percentage = percentage
            self.colorHex = colorHex
        }
    }

    public var assetAllocation: [AssetSlice] {
        let total = summary.totalValue
        guard total > 0 else { return [] }

        var slices: [AssetSlice] = []
        // Cash slice
        slices.append(AssetSlice(symbol: "CASH", name: "Paper Cash", value: cashBalance, percentage: (cashBalance / total) * 100, colorHex: "#34C759"))

        let colors = ["#007AFF", "#AF52DE", "#FF9500", "#5856D6", "#FF2D55", "#5AC8FA", "#FFCC00"]
        for (idx, pos) in positions.enumerated() where pos.shares > 0 {
            let price = getStock(for: pos.symbol)?.currentPrice ?? pos.averagePrice
            let val = pos.currentValue(at: price)
            let color = colors[idx % colors.count]
            slices.append(AssetSlice(symbol: pos.symbol, name: pos.companyName, value: val, percentage: (val / total) * 100, colorHex: color))
        }
        return slices.sorted { $0.value > $1.value }
    }

    // MARK: - Performance Snapshot Recording
    public func recordSnapshot() {
        let newPoint = ChartDataPoint(timestamp: Date(), price: summary.totalValue)
        portfolioSnapshots.append(newPoint)
        if portfolioSnapshots.count > 60 {
            portfolioSnapshots.removeFirst()
        }
        storage.savePortfolioSnapshots(portfolioSnapshots)
    }

    // MARK: - Advanced Order Engine (Limit, Stop Loss, Take Profit)
    public func placeOrder(
        symbol: String,
        type: TransactionType,
        kind: OrderKind,
        shares: Double,
        targetPrice: Double
    ) -> Result<Void, TradeError> {
        guard shares > 0, targetPrice > 0 else { return .failure(.invalidAmount) }
        guard let stock = getStock(for: symbol) else { return .failure(.invalidAmount) }

        if type == .buy {
            let estCost = shares * targetPrice
            guard cashBalance >= estCost else {
                return .failure(.insufficientFunds(required: estCost, available: cashBalance))
            }
        } else {
            let owned = getPosition(for: symbol)?.shares ?? 0
            let pendingSellShares = pendingOrders.filter { $0.symbol == symbol && $0.type == .sell && $0.status == .pending }.reduce(0.0) { $0 + $1.shares }
            guard (owned - pendingSellShares) >= shares else {
                return .failure(.insufficientShares(owned: owned - pendingSellShares, requested: shares))
            }
        }

        let order = LimitOrder(
            symbol: symbol,
            companyName: stock.name,
            type: type,
            kind: kind,
            shares: shares,
            targetPrice: targetPrice,
            status: .pending
        )
        pendingOrders.insert(order, at: 0)
        saveAll()
        HapticsService.shared.notification(type: .success)
        showNotification(message: "\(kind.rawValue) \(type.rawValue) placed for \(String(format: "%.2f", shares)) \(symbol) @ $\(String(format: "%.2f", targetPrice))")
        return .success(())
    }

    public func placeLimitOrder(symbol: String, type: TransactionType, shares: Double, targetPrice: Double) -> Result<Void, TradeError> {
        placeOrder(symbol: symbol, type: type, kind: .limit, shares: shares, targetPrice: targetPrice)
    }

    public func cancelLimitOrder(id: UUID) {
        if let idx = pendingOrders.firstIndex(where: { $0.id == id }) {
            var order = pendingOrders[idx]
            order.status = .cancelled
            pendingOrders[idx] = order
            saveAll()
            HapticsService.shared.impact(style: .medium)
            showNotification(message: "\(order.kind.rawValue) order for \(order.symbol) cancelled.")
        }
    }

    public func checkAndExecuteLimitOrders(for currentStocks: [Stock]) {
        for (index, order) in pendingOrders.enumerated() where order.status == .pending {
            guard let stock = currentStocks.first(where: { $0.symbol == order.symbol }) else { continue }

            var shouldExecute = false
            switch order.kind {
            case .limit:
                if order.type == .buy && stock.currentPrice <= order.targetPrice {
                    shouldExecute = true
                } else if order.type == .sell && stock.currentPrice >= order.targetPrice {
                    shouldExecute = true
                }
            case .stopLoss:
                if stock.currentPrice <= order.targetPrice {
                    shouldExecute = true
                }
            case .takeProfit:
                if stock.currentPrice >= order.targetPrice {
                    shouldExecute = true
                }
            }

            if shouldExecute {
                var updatedOrder = order
                updatedOrder.status = .filled
                updatedOrder.filledAt = Date()
                updatedOrder.executionPrice = stock.currentPrice
                pendingOrders[index] = updatedOrder

                if order.type == .buy {
                    _ = buyStock(symbol: order.symbol, shares: order.shares)
                } else {
                    _ = sellStock(symbol: order.symbol, shares: order.shares)
                }

                let bannerText: String
                switch order.kind {
                case .stopLoss:
                    bannerText = "🚨 Stop Loss Triggered: Sold \(String(format: "%.2f", order.shares)) \(order.symbol) @ $\(String(format: "%.2f", stock.currentPrice))"
                case .takeProfit:
                    bannerText = "🎉 Take Profit Triggered: Sold \(String(format: "%.2f", order.shares)) \(order.symbol) @ $\(String(format: "%.2f", stock.currentPrice))"
                case .limit:
                    bannerText = "⚡ Limit Order FILLED: \(order.type.rawValue) \(String(format: "%.2f", order.shares)) \(order.symbol) @ $\(String(format: "%.2f", stock.currentPrice))"
                }

                showNotification(message: bannerText)
                HapticsService.shared.notification(type: .success)
            }
        }
    }

    // MARK: - Privacy Mode Toggle
    public func togglePrivacyMode() {
        isPrivacyMode.toggle()
        HapticsService.shared.impact(style: .light)
    }

    // MARK: - Market News & Sentiment Feed
    public func getNews(for symbol: String) -> [NewsArticle] {
        marketService.fetchNews(for: symbol)
    }

    // MARK: - Trade Statement CSV Export
    public func exportTransactionsCSV() -> String {
        var csv = "Timestamp,Type,Symbol,Company,Shares,Price,TotalAmount,Note\n"
        let formatter = ISO8601DateFormatter()
        for tx in transactions {
            let dateStr = formatter.string(from: tx.timestamp)
            let sym = tx.symbol ?? ""
            let comp = (tx.companyName ?? "").replacingOccurrences(of: ",", with: " ")
            let shares = tx.shares != nil ? String(format: "%.4f", tx.shares!) : ""
            let price = tx.pricePerShare != nil ? String(format: "%.2f", tx.pricePerShare!) : ""
            let amt = String(format: "%.2f", tx.totalAmount)
            let note = (tx.note ?? "").replacingOccurrences(of: ",", with: " ")
            csv += "\(dateStr),\(tx.type.rawValue),\(sym),\(comp),\(shares),\(price),\(amt),\(note)\n"
        }
        return csv
    }

    // MARK: - Universal Real-Time Ticker Search
    public func searchUniversalStocks(query: String) async -> [Stock] {
        let results = await marketService.searchUniversalTickers(query: query)
        for res in results {
            if !stocks.contains(where: { $0.symbol == res.symbol }) {
                stocks.append(res)
            }
        }
        return results
    }

    // MARK: - Price Alerts Engine
    public func addPriceAlert(symbol: String, targetPrice: Double, condition: AlertCondition) {
        let alert = PriceAlert(
            symbol: symbol,
            targetPrice: targetPrice,
            condition: condition
        )
        priceAlerts.insert(alert, at: 0)
        storage.savePriceAlerts(priceAlerts)
        HapticsService.shared.notification(type: .success)
        showNotification(message: "🔔 Alert set: \(symbol) \(condition.rawValue) $\(String(format: "%.2f", targetPrice))")
    }

    public func removePriceAlert(id: UUID) {
        if let idx = priceAlerts.firstIndex(where: { $0.id == id }) {
            let removed = priceAlerts.remove(at: idx)
            storage.savePriceAlerts(priceAlerts)
            HapticsService.shared.impact(style: .medium)
            showNotification(message: "Alert for \(removed.symbol) removed.")
        }
    }

    public func checkPriceAlerts(for currentStocks: [Stock]) {
        for (index, alert) in priceAlerts.enumerated() where !alert.isTriggered {
            guard let stock = currentStocks.first(where: { $0.symbol == alert.symbol }) else { continue }

            var isTriggered = false
            if alert.condition == .above && stock.currentPrice >= alert.targetPrice {
                isTriggered = true
            } else if alert.condition == .below && stock.currentPrice <= alert.targetPrice {
                isTriggered = true
            }

            if isTriggered {
                var updated = alert
                updated.isTriggered = true
                updated.triggeredAt = Date()
                priceAlerts[index] = updated
                storage.savePriceAlerts(priceAlerts)

                HapticsService.shared.notification(type: .warning)
                showNotification(message: "🚨 Price Alert: \(alert.symbol) reached $\(String(format: "%.2f", stock.currentPrice)) (Target: $\(String(format: "%.2f", alert.targetPrice)))")
            }
        }
    }

    // MARK: - Trader Performance Analytics
    public struct TraderAnalytics: Equatable {
        public let realizedPnL: Double
        public let totalTradesCount: Int
        public let closedTradesCount: Int
        public let winningTradesCount: Int
        public let losingTradesCount: Int
        public let winRate: Double
        public let bestTrade: Double
        public let worstTrade: Double

        public init(
            realizedPnL: Double,
            totalTradesCount: Int,
            closedTradesCount: Int,
            winningTradesCount: Int,
            losingTradesCount: Int,
            winRate: Double,
            bestTrade: Double,
            worstTrade: Double
        ) {
            self.realizedPnL = realizedPnL
            self.totalTradesCount = totalTradesCount
            self.closedTradesCount = closedTradesCount
            self.winningTradesCount = winningTradesCount
            self.losingTradesCount = losingTradesCount
            self.winRate = winRate
            self.bestTrade = bestTrade
            self.worstTrade = worstTrade
        }
    }

    public var traderAnalytics: TraderAnalytics {
        let buys = transactions.filter { $0.type == .buy }
        let sells = transactions.filter { $0.type == .sell }

        var realizedTotal = 0.0
        var winCount = 0
        var lossCount = 0
        var best = 0.0
        var worst = 0.0

        for sell in sells {
            guard let sym = sell.symbol, let sellShares = sell.shares, let sellPrice = sell.pricePerShare else { continue }
            let priorBuys = buys.filter { $0.symbol == sym && $0.timestamp <= sell.timestamp }
            let totalBuyShares = priorBuys.compactMap { $0.shares }.reduce(0.0, +)
            let totalBuyCost = priorBuys.map { $0.totalAmount }.reduce(0.0, +)
            let avgCost = totalBuyShares > 0 ? (totalBuyCost / totalBuyShares) : sellPrice

            let tradePnL = (sellPrice - avgCost) * sellShares
            realizedTotal += tradePnL

            if tradePnL > 0.001 {
                winCount += 1
                if tradePnL > best { best = tradePnL }
            } else if tradePnL < -0.001 {
                lossCount += 1
                if tradePnL < worst { worst = tradePnL }
            }
        }

        let totalClosed = winCount + lossCount
        let winRate = totalClosed > 0 ? (Double(winCount) / Double(totalClosed)) * 100.0 : 0.0

        return TraderAnalytics(
            realizedPnL: realizedTotal,
            totalTradesCount: buys.count + sells.count,
            closedTradesCount: totalClosed,
            winningTradesCount: winCount,
            losingTradesCount: lossCount,
            winRate: winRate,
            bestTrade: best,
            worstTrade: worst
        )
    }

    // MARK: - Toast / Notification Banner
    public func showNotification(message: String) {
        self.bannerMessage = message
        self.showBanner = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if self.bannerMessage == message {
                self.showBanner = false
            }
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }
}
