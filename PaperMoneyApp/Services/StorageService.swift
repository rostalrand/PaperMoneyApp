import Foundation
import Combine

/// Manages frictionless local persistence with automatic Apple iCloud Key-Value synchronization.
/// No account creation or login required: uses Apple's native iCloud container.
public final class StorageService: ObservableObject {
    public static let shared = StorageService()

    private let userDefaults: UserDefaults
    private let iCloudStore: NSUbiquitousKeyValueStore

    @Published public private(set) var isICloudAvailable: Bool = false
    @Published public private(set) var lastSyncDate: Date? = nil

    public let externalChangePublisher = PassthroughSubject<Void, Never>()

    private enum Keys {
        static let cashBalance = "paper_money_cash_balance"
        static let totalDeposited = "paper_money_total_deposited"
        static let positions = "paper_money_positions"
        static let transactions = "paper_money_transactions"
        static let watchlist = "paper_money_watchlist"
        static let limitOrders = "paper_money_limit_orders"
        static let priceAlerts = "paper_money_price_alerts"
        static let portfolioSnapshots = "paper_money_portfolio_snapshots"
        static let hasInitialized = "paper_money_has_initialized"
        static let lastSync = "paper_money_last_sync_timestamp"
    }

    public init(
        userDefaults: UserDefaults = .standard,
        iCloudStore: NSUbiquitousKeyValueStore = .default
    ) {
        self.userDefaults = userDefaults
        self.iCloudStore = iCloudStore

        checkICloudStatus()
        setupICloudObserver()
    }

    private func checkICloudStatus() {
        // FileManager.default.ubiquityIdentityToken checks if an active iCloud account is logged into iOS
        let token = FileManager.default.ubiquityIdentityToken
        self.isICloudAvailable = (token != nil)
        self.iCloudStore.synchronize()
    }

    private func setupICloudObserver() {
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: iCloudStore,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            self.lastSyncDate = Date()
            self.externalChangePublisher.send(())
        }
    }

    public var hasInitialized: Bool {
        if iCloudStore.bool(forKey: Keys.hasInitialized) {
            return true
        }
        return userDefaults.bool(forKey: Keys.hasInitialized)
    }

    public func markInitialized() {
        userDefaults.set(true, forKey: Keys.hasInitialized)
        iCloudStore.set(true, forKey: Keys.hasInitialized)
        iCloudStore.synchronize()
    }

    // MARK: - Cash Balance
    public func saveCashBalance(_ balance: Double) {
        userDefaults.set(balance, forKey: Keys.cashBalance)
        iCloudStore.set(balance, forKey: Keys.cashBalance)
        iCloudStore.synchronize()
    }

    public func loadCashBalance(defaultVal: Double = 100_000.0) -> Double {
        if iCloudStore.object(forKey: Keys.cashBalance) != nil {
            return iCloudStore.double(forKey: Keys.cashBalance)
        }
        if userDefaults.object(forKey: Keys.cashBalance) != nil {
            return userDefaults.double(forKey: Keys.cashBalance)
        }
        return defaultVal
    }

    // MARK: - Total Deposited
    public func saveTotalDeposited(_ amount: Double) {
        userDefaults.set(amount, forKey: Keys.totalDeposited)
        iCloudStore.set(amount, forKey: Keys.totalDeposited)
        iCloudStore.synchronize()
    }

    public func loadTotalDeposited(defaultVal: Double = 100_000.0) -> Double {
        if iCloudStore.object(forKey: Keys.totalDeposited) != nil {
            return iCloudStore.double(forKey: Keys.totalDeposited)
        }
        if userDefaults.object(forKey: Keys.totalDeposited) != nil {
            return userDefaults.double(forKey: Keys.totalDeposited)
        }
        return defaultVal
    }

    // MARK: - Positions
    public func savePositions(_ positions: [Position]) {
        if let encoded = try? JSONEncoder().encode(positions) {
            userDefaults.set(encoded, forKey: Keys.positions)
            iCloudStore.set(encoded, forKey: Keys.positions)
            iCloudStore.synchronize()
        }
    }

    public func loadPositions() -> [Position] {
        let rawData = iCloudStore.data(forKey: Keys.positions) ?? userDefaults.data(forKey: Keys.positions)
        guard let data = rawData,
              let decoded = try? JSONDecoder().decode([Position].self, from: data) else {
            return []
        }
        return decoded
    }

    // MARK: - Transactions
    /// Saves transactions with quota protection for Apple NSUbiquitousKeyValueStore (1MB cap)
    public func saveTransactions(_ transactions: [Transaction]) {
        // Retain the most recent 500 transactions to prevent iCloud KVS quota overflow
        let cappedTransactions = Array(transactions.prefix(500))
        if let encoded = try? JSONEncoder().encode(cappedTransactions) {
            userDefaults.set(encoded, forKey: Keys.transactions)
            iCloudStore.set(encoded, forKey: Keys.transactions)
            iCloudStore.synchronize()
        }
    }

    public func loadTransactions() -> [Transaction] {
        let rawData = iCloudStore.data(forKey: Keys.transactions) ?? userDefaults.data(forKey: Keys.transactions)
        guard let data = rawData,
              let decoded = try? JSONDecoder().decode([Transaction].self, from: data) else {
            return []
        }
        return decoded
    }

    // MARK: - Watchlist
    public func saveWatchlist(_ symbols: Set<String>) {
        let array = Array(symbols)
        userDefaults.set(array, forKey: Keys.watchlist)
        iCloudStore.set(array, forKey: Keys.watchlist)
        iCloudStore.synchronize()
    }

    public func loadWatchlist(defaultSymbols: Set<String> = ["AAPL", "NVDA", "TSLA"]) -> Set<String> {
        if let array = iCloudStore.array(forKey: Keys.watchlist) as? [String] {
            return Set(array)
        }
        if let array = userDefaults.stringArray(forKey: Keys.watchlist) {
            return Set(array)
        }
        return defaultSymbols
    }

    // MARK: - Limit Orders
    public func saveLimitOrders(_ orders: [LimitOrder]) {
        if let encoded = try? JSONEncoder().encode(orders) {
            userDefaults.set(encoded, forKey: Keys.limitOrders)
            iCloudStore.set(encoded, forKey: Keys.limitOrders)
            iCloudStore.synchronize()
        }
    }

    public func loadLimitOrders() -> [LimitOrder] {
        let rawData = iCloudStore.data(forKey: Keys.limitOrders) ?? userDefaults.data(forKey: Keys.limitOrders)
        guard let data = rawData,
              let decoded = try? JSONDecoder().decode([LimitOrder].self, from: data) else {
            return []
        }
        return decoded
    }

    // MARK: - Portfolio Snapshots (Performance Curve)
    /// Saves performance curve points capped at 200 recent snapshots to safeguard iCloud quota
    public func savePortfolioSnapshots(_ points: [ChartDataPoint]) {
        // Retain the most recent 200 snapshots
        let cappedPoints = Array(points.suffix(200))
        if let encoded = try? JSONEncoder().encode(cappedPoints) {
            userDefaults.set(encoded, forKey: Keys.portfolioSnapshots)
            iCloudStore.set(encoded, forKey: Keys.portfolioSnapshots)
            iCloudStore.synchronize()
        }
    }

    public func loadPortfolioSnapshots() -> [ChartDataPoint] {
        let rawData = iCloudStore.data(forKey: Keys.portfolioSnapshots) ?? userDefaults.data(forKey: Keys.portfolioSnapshots)
        guard let data = rawData,
              let decoded = try? JSONDecoder().decode([ChartDataPoint].self, from: data) else {
            return []
        }
        return decoded
    }

    // MARK: - Price Alerts
    public func savePriceAlerts(_ alerts: [PriceAlert]) {
        if let encoded = try? JSONEncoder().encode(alerts) {
            userDefaults.set(encoded, forKey: Keys.priceAlerts)
            iCloudStore.set(encoded, forKey: Keys.priceAlerts)
            iCloudStore.synchronize()
        }
    }

    public func loadPriceAlerts() -> [PriceAlert] {
        let rawData = iCloudStore.data(forKey: Keys.priceAlerts) ?? userDefaults.data(forKey: Keys.priceAlerts)
        guard let data = rawData,
              let decoded = try? JSONDecoder().decode([PriceAlert].self, from: data) else {
            return []
        }
        return decoded
    }

    // MARK: - Reset All
    public func clearAll() {
        userDefaults.removeObject(forKey: Keys.cashBalance)
        userDefaults.removeObject(forKey: Keys.totalDeposited)
        userDefaults.removeObject(forKey: Keys.positions)
        userDefaults.removeObject(forKey: Keys.transactions)
        userDefaults.removeObject(forKey: Keys.watchlist)
        userDefaults.removeObject(forKey: Keys.limitOrders)
        userDefaults.removeObject(forKey: Keys.priceAlerts)
        userDefaults.removeObject(forKey: Keys.portfolioSnapshots)
        userDefaults.removeObject(forKey: Keys.hasInitialized)

        iCloudStore.removeObject(forKey: Keys.cashBalance)
        iCloudStore.removeObject(forKey: Keys.totalDeposited)
        iCloudStore.removeObject(forKey: Keys.positions)
        iCloudStore.removeObject(forKey: Keys.transactions)
        iCloudStore.removeObject(forKey: Keys.watchlist)
        iCloudStore.removeObject(forKey: Keys.limitOrders)
        iCloudStore.removeObject(forKey: Keys.priceAlerts)
        iCloudStore.removeObject(forKey: Keys.portfolioSnapshots)
        iCloudStore.removeObject(forKey: Keys.hasInitialized)
        iCloudStore.synchronize()
    }
}
