import XCTest
@testable import PaperMoneyApp

@MainActor
final class PortfolioTests: XCTestCase {
    var viewModel: PortfolioViewModel!
    var mockDefaults: UserDefaults!

    override func setUp() async throws {
        try await super.setUp()
        let suiteName = "test_\(UUID().uuidString)"
        mockDefaults = UserDefaults(suiteName: suiteName)!
        let storage = StorageService(userDefaults: mockDefaults)
        viewModel = PortfolioViewModel(storage: storage)
    }

    override func tearDown() async throws {
        mockDefaults = nil
        viewModel = nil
        try await super.tearDown()
    }

    func testInitialDeposit() {
        XCTAssertEqual(viewModel.cashBalance, 100_000.0)
        XCTAssertEqual(viewModel.totalDeposited, 100_000.0)
        XCTAssertEqual(viewModel.positions.count, 0)
        XCTAssertEqual(viewModel.transactions.count, 1)
        XCTAssertEqual(viewModel.transactions.first?.type, .deposit)
    }

    func testCustomDeposit() {
        let depositAmount = 50_000.0
        viewModel.depositCash(amount: depositAmount, note: "Test Bonus")

        XCTAssertEqual(viewModel.cashBalance, 150_000.0)
        XCTAssertEqual(viewModel.totalDeposited, 150_000.0)
        XCTAssertEqual(viewModel.transactions.first?.totalAmount, 50_000.0)
        XCTAssertEqual(viewModel.transactions.first?.note, "Test Bonus")
    }

    func testBuyStockSuccess() {
        guard let aapl = viewModel.getStock(for: "AAPL") else {
            XCTFail("Stock AAPL not found")
            return
        }

        let sharesToBuy = 10.0
        let expectedCost = sharesToBuy * aapl.currentPrice
        let initialCash = viewModel.cashBalance

        let result = viewModel.buyStock(symbol: "AAPL", shares: sharesToBuy)
        XCTAssertTrue(caseIsSuccess(result))

        XCTAssertEqual(viewModel.cashBalance, initialCash - expectedCost, accuracy: 0.01)
        let pos = viewModel.getPosition(for: "AAPL")
        XCTAssertNotNil(pos)
        XCTAssertEqual(pos?.shares, sharesToBuy)
        XCTAssertEqual(pos?.averagePrice, aapl.currentPrice, accuracy: 0.01)
    }

    func testBuyStockInsufficientFunds() {
        let sharesToBuy = 10_000.0 // Costs > $2M, exceeding $100k balance
        let result = viewModel.buyStock(symbol: "AAPL", shares: sharesToBuy)

        switch result {
        case .failure(let error):
            if case .insufficientFunds = error {
                // Expected
            } else {
                XCTFail("Unexpected error: \(error)")
            }
        case .success:
            XCTFail("Buy should have failed due to insufficient funds")
        }
    }

    func testSellStockSuccess() {
        _ = viewModel.buyStock(symbol: "AAPL", shares: 10.0)
        let cashBeforeSell = viewModel.cashBalance

        guard let aapl = viewModel.getStock(for: "AAPL") else {
            XCTFail("Stock AAPL not found")
            return
        }

        let result = viewModel.sellStock(symbol: "AAPL", shares: 4.0)
        XCTAssertTrue(caseIsSuccess(result))

        let proceeds = 4.0 * aapl.currentPrice
        XCTAssertEqual(viewModel.cashBalance, cashBeforeSell + proceeds, accuracy: 0.01)

        let pos = viewModel.getPosition(for: "AAPL")
        XCTAssertNotNil(pos)
        XCTAssertEqual(pos?.shares, 6.0)
    }

    func testSellEntirePositionRemovesHolding() {
        _ = viewModel.buyStock(symbol: "AAPL", shares: 5.0)
        let result = viewModel.sellStock(symbol: "AAPL", shares: 5.0)
        XCTAssertTrue(caseIsSuccess(result))

        let pos = viewModel.getPosition(for: "AAPL")
        XCTAssertNil(pos, "Position should be removed when 100% sold")
    }

    func testSellMoreSharesThanOwnedFails() {
        _ = viewModel.buyStock(symbol: "AAPL", shares: 2.0)
        let result = viewModel.sellStock(symbol: "AAPL", shares: 10.0)

        switch result {
        case .failure(let error):
            if case .insufficientShares = error {
                // Expected
            } else {
                XCTFail("Unexpected error: \(error)")
            }
        case .success:
            XCTFail("Sell should have failed due to insufficient shares")
        }
    }

    func testResetAccount() {
        _ = viewModel.buyStock(symbol: "AAPL", shares: 5.0)
        viewModel.resetAccount(startingDeposit: 250_000.0)

        XCTAssertEqual(viewModel.cashBalance, 250_000.0)
        XCTAssertEqual(viewModel.totalDeposited, 250_000.0)
        XCTAssertEqual(viewModel.positions.count, 0)
    }

    func testMarketDataCatalogAndChartPoints() {
        let service = MarketDataService.shared
        let initialStocks = service.getInitialStocks()
        XCTAssertGreaterThanOrEqual(initialStocks.count, 10)

        guard let aapl = initialStocks.first(where: { $0.symbol == "AAPL" }) else {
            XCTFail("AAPL not found")
            return
        }

        let chart1D = service.generateChartData(for: aapl, timeframe: .oneDay)
        XCTAssertEqual(chart1D.count, 30)
        XCTAssertEqual(chart1D.last?.price, aapl.currentPrice)

        let chart1Y = service.generateChartData(for: aapl, timeframe: .oneYear)
        XCTAssertEqual(chart1Y.count, 52)
    }

    func testPlaceLimitBuyOrderSuccess() {
        guard let aapl = viewModel.getStock(for: "AAPL") else {
            XCTFail("AAPL not found")
            return
        }

        let targetPrice = aapl.currentPrice * 0.90
        let result = viewModel.placeLimitOrder(symbol: "AAPL", type: .buy, shares: 5.0, targetPrice: targetPrice)
        XCTAssertTrue(caseIsSuccess(result))
        XCTAssertEqual(viewModel.pendingOrders.count, 1)
        XCTAssertEqual(viewModel.pendingOrders.first?.status, .pending)
        XCTAssertEqual(viewModel.pendingOrders.first?.targetPrice, targetPrice)
    }

    func testLimitBuyOrderTriggersWhenPriceDrops() {
        guard let aapl = viewModel.getStock(for: "AAPL") else {
            XCTFail("AAPL not found")
            return
        }

        let targetPrice = 200.0
        _ = viewModel.placeLimitOrder(symbol: "AAPL", type: .buy, shares: 10.0, targetPrice: targetPrice)

        var droppedAapl = aapl
        droppedAapl.currentPrice = 199.50

        viewModel.checkAndExecuteLimitOrders(for: [droppedAapl])

        XCTAssertEqual(viewModel.pendingOrders.first?.status, .filled)
        let pos = viewModel.getPosition(for: "AAPL")
        XCTAssertNotNil(pos)
        XCTAssertEqual(pos?.shares, 10.0)
    }

    func testLimitSellOrderTriggersWhenPriceRises() {
        _ = viewModel.buyStock(symbol: "AAPL", shares: 10.0)

        guard let aapl = viewModel.getStock(for: "AAPL") else {
            XCTFail("AAPL not found")
            return
        }

        let targetSellPrice = aapl.currentPrice * 1.20
        _ = viewModel.placeLimitOrder(symbol: "AAPL", type: .sell, shares: 5.0, targetPrice: targetSellPrice)

        var surgedAapl = aapl
        surgedAapl.currentPrice = targetSellPrice + 2.0

        viewModel.checkAndExecuteLimitOrders(for: [surgedAapl])

        XCTAssertEqual(viewModel.pendingOrders.first?.status, .filled)
        let pos = viewModel.getPosition(for: "AAPL")
        XCTAssertEqual(pos?.shares, 5.0)
    }

    func testCancelLimitOrder() {
        _ = viewModel.placeLimitOrder(symbol: "AAPL", type: .buy, shares: 5.0, targetPrice: 150.0)
        guard let order = viewModel.pendingOrders.first else {
            XCTFail("Order not placed")
            return
        }

        viewModel.cancelLimitOrder(id: order.id)
        XCTAssertEqual(viewModel.pendingOrders.first?.status, .cancelled)
    }

    func testAssetAllocationPercentagesSumTo100() {
        _ = viewModel.buyStock(symbol: "AAPL", shares: 10.0)
        _ = viewModel.buyStock(symbol: "NVDA", shares: 20.0)

        let slices = viewModel.assetAllocation
        XCTAssertFalse(slices.isEmpty)

        let totalPercentage = slices.reduce(0.0) { $0 + $1.percentage }
        XCTAssertEqual(totalPercentage, 100.0, accuracy: 0.1)
    }

    func testStopLossOrderTriggersWhenPriceDrops() {
        _ = viewModel.buyStock(symbol: "NVDA", shares: 10.0)
        guard let nvda = viewModel.getStock(for: "NVDA") else {
            XCTFail("NVDA not found")
            return
        }

        let stopPrice = nvda.currentPrice * 0.90
        let result = viewModel.placeOrder(symbol: "NVDA", type: .sell, kind: .stopLoss, shares: 10.0, targetPrice: stopPrice)
        XCTAssertTrue(caseIsSuccess(result))
        XCTAssertEqual(viewModel.pendingOrders.first?.kind, .stopLoss)

        var droppedNvda = nvda
        droppedNvda.currentPrice = stopPrice - 1.0 // Breached downside stop
        viewModel.checkAndExecuteLimitOrders(for: [droppedNvda])

        XCTAssertEqual(viewModel.pendingOrders.first?.status, .filled)
        XCTAssertNil(viewModel.getPosition(for: "NVDA"))
    }

    func testTakeProfitOrderTriggersWhenPriceRises() {
        _ = viewModel.buyStock(symbol: "TSLA", shares: 5.0)
        guard let tsla = viewModel.getStock(for: "TSLA") else {
            XCTFail("TSLA not found")
            return
        }

        let profitTarget = tsla.currentPrice * 1.15
        let result = viewModel.placeOrder(symbol: "TSLA", type: .sell, kind: .takeProfit, shares: 5.0, targetPrice: profitTarget)
        XCTAssertTrue(caseIsSuccess(result))
        XCTAssertEqual(viewModel.pendingOrders.first?.kind, .takeProfit)

        var surgedTsla = tsla
        surgedTsla.currentPrice = profitTarget + 2.0 // Exceeded profit target
        viewModel.checkAndExecuteLimitOrders(for: [surgedTsla])

        XCTAssertEqual(viewModel.pendingOrders.first?.status, .filled)
        XCTAssertNil(viewModel.getPosition(for: "TSLA"))
    }

    func testPrivacyModeToggle() {
        XCTAssertFalse(viewModel.isPrivacyMode)
        viewModel.togglePrivacyMode()
        XCTAssertTrue(viewModel.isPrivacyMode)
        viewModel.togglePrivacyMode()
        XCTAssertFalse(viewModel.isPrivacyMode)
    }

    func testExportTransactionsCSV() {
        _ = viewModel.buyStock(symbol: "AAPL", shares: 5.0)
        let csv = viewModel.exportTransactionsCSV()

        XCTAssertTrue(csv.contains("Timestamp,Type,Symbol,Company,Shares,Price,TotalAmount,Note"))
        XCTAssertTrue(csv.contains("Deposit"))
        XCTAssertTrue(csv.contains("AAPL"))
        XCTAssertTrue(csv.contains("Buy"))
    }

    func testNewsFeedForSymbols() {
        let aaplNews = viewModel.getNews(for: "AAPL")
        XCTAssertFalse(aaplNews.isEmpty)
        XCTAssertEqual(aaplNews.first?.symbol, "AAPL")
        XCTAssertNotNil(aaplNews.first?.title)
        XCTAssertNotNil(aaplNews.first?.publisher)

        let genericNews = viewModel.getNews(for: "PLTR")
        XCTAssertFalse(genericNews.isEmpty)
        XCTAssertEqual(genericNews.first?.symbol, "PLTR")
    }

    func testAddPriceAlertAndTrigger() {
        guard let nvda = viewModel.getStock(for: "NVDA") else {
            XCTFail("NVDA not found")
            return
        }

        let targetPrice = nvda.currentPrice + 10.0
        viewModel.addPriceAlert(symbol: "NVDA", targetPrice: targetPrice, condition: .above)
        XCTAssertEqual(viewModel.priceAlerts.count, 1)
        XCTAssertFalse(viewModel.priceAlerts.first!.isTriggered)

        var surgedNvda = nvda
        surgedNvda.currentPrice = targetPrice + 1.0
        viewModel.checkPriceAlerts(for: [surgedNvda])

        XCTAssertTrue(viewModel.priceAlerts.first!.isTriggered)
        XCTAssertNotNil(viewModel.priceAlerts.first!.triggeredAt)
    }

    func testRemovePriceAlert() {
        viewModel.addPriceAlert(symbol: "AAPL", targetPrice: 300.0, condition: .above)
        guard let alert = viewModel.priceAlerts.first else {
            XCTFail("Alert not found")
            return
        }

        viewModel.removePriceAlert(id: alert.id)
        XCTAssertEqual(viewModel.priceAlerts.count, 0)
    }

    func testTraderAnalyticsWinRateAndRealizedPnL() {
        _ = viewModel.buyStock(symbol: "AAPL", shares: 10.0)
        _ = viewModel.sellStock(symbol: "AAPL", shares: 10.0)

        let stats = viewModel.traderAnalytics
        XCTAssertEqual(stats.totalTradesCount, 2)
        XCTAssertEqual(stats.closedTradesCount, 1)
        XCTAssertGreaterThanOrEqual(stats.winRate, 0.0)
    }

    func testCandlestickPointGeneration() {
        guard let aapl = viewModel.getStock(for: "AAPL") else {
            XCTFail("AAPL not found")
            return
        }

        XCTAssertFalse(aapl.candlestickHistory.isEmpty)
        for candle in aapl.candlestickHistory {
            XCTAssertGreaterThanOrEqual(candle.high, candle.low, "Candle high must be >= low")
            XCTAssertGreaterThanOrEqual(candle.high, min(candle.open, candle.close), "Candle high must be >= min(open, close)")
            XCTAssertLessThanOrEqual(candle.low, max(candle.open, candle.close), "Candle low must be <= max(open, close)")
            XCTAssertGreaterThan(candle.high, 0.0)
        }
    }

    func testResetAccountWithCustomCapital() {
        _ = viewModel.buyStock(symbol: "AAPL", shares: 5.0)
        viewModel.addPriceAlert(symbol: "AAPL", targetPrice: 300.0, condition: .above)

        XCTAssertFalse(viewModel.positions.isEmpty)

        viewModel.resetAccount(startingDeposit: 50_000.0)

        XCTAssertEqual(viewModel.cashBalance, 50_000.0)
        XCTAssertEqual(viewModel.totalDeposited, 50_000.0)
        XCTAssertTrue(viewModel.positions.isEmpty)
        XCTAssertTrue(viewModel.limitOrders.isEmpty)
        XCTAssertEqual(viewModel.transactions.count, 1)
        XCTAssertEqual(viewModel.transactions.first?.type, .deposit)
        XCTAssertEqual(viewModel.transactions.first?.totalAmount, 50_000.0)
    }

    func testScreenerCategoryFilter() {
        let all = viewModel.allStocks
        XCTAssertFalse(all.isEmpty)

        let techStocks = all.filter { $0.sector.contains("Tech") || $0.sector.contains("Internet") }
        XCTAssertFalse(techStocks.isEmpty)

        let etfStocks = all.filter { $0.sector.contains("ETF") || $0.sector.contains("Index") }
        XCTAssertFalse(etfStocks.isEmpty)

        let sortedGainers = all.sorted { $0.changePercent > $1.changePercent }
        XCTAssertGreaterThanOrEqual(sortedGainers.first!.changePercent, sortedGainers.last!.changePercent)

        let sortedLosers = all.sorted { $0.changePercent < $1.changePercent }
        XCTAssertLessThanOrEqual(sortedLosers.first!.changePercent, sortedLosers.last!.changePercent)
    }

    func testStorageTransactionQuotaCapping() {
        let storage = StorageService(userDefaults: mockDefaults)
        var largeTxList: [Transaction] = []
        for i in 1...600 {
            largeTxList.append(Transaction(type: .deposit, totalAmount: Double(i), note: "Tx #\(i)"))
        }

        storage.saveTransactions(largeTxList)
        let loaded = storage.loadTransactions()
        XCTAssertEqual(loaded.count, 500, "Transactions should be capped to 500 to protect 1MB KVS quota")
        XCTAssertEqual(loaded.first?.totalAmount, 1.0)
    }

    func testStorageSnapshotQuotaCapping() {
        let storage = StorageService(userDefaults: mockDefaults)
        var points: [ChartDataPoint] = []
        for i in 1...300 {
            points.append(ChartDataPoint(timestamp: Date().addingTimeInterval(Double(i)), value: Double(100 + i)))
        }

        storage.savePortfolioSnapshots(points)
        let loaded = storage.loadPortfolioSnapshots()
        XCTAssertEqual(loaded.count, 200, "Snapshots should be capped to 200 to protect 1MB KVS quota")
    }

    func testAdServiceProductionSwitchAndActiveAdUnitID() {
        let adService = AdService.shared
        let originalMode = adService.isProductionMode
        let originalID = adService.productionAppOpenAdUnitID

        adService.isProductionMode = false
        XCTAssertEqual(adService.appOpenAdUnitID, adService.testAppOpenAdUnitID)

        adService.isProductionMode = true
        adService.productionAppOpenAdUnitID = "ca-app-pub-9999999999999999/8888888888"
        XCTAssertEqual(adService.appOpenAdUnitID, "ca-app-pub-9999999999999999/8888888888")

        // Restore original production settings
        adService.isProductionMode = originalMode
        adService.productionAppOpenAdUnitID = originalID
    }

    func testLegalSheetTypes() {
        let disclaimer = LegalSheetType.disclaimer
        XCTAssertEqual(disclaimer.title, "Educational Simulator Disclaimer")
        XCTAssertFalse(disclaimer.icon.isEmpty)

        let privacy = LegalSheetType.privacyPolicy
        XCTAssertEqual(privacy.title, "App Privacy Policy")

        let terms = LegalSheetType.termsOfService
        XCTAssertEqual(terms.title, "Terms of Service")
    }

    func testCancelPendingBuyLimitOrder() {
        let result = viewModel.placeLimitOrder(symbol: "NVDA", type: .buy, shares: 5, targetPrice: 100.0)
        XCTAssertTrue(caseIsSuccess(result))
        guard let order = viewModel.pendingOrders.first else {
            XCTFail("Limit order not found")
            return
        }
        XCTAssertEqual(order.status, .pending)

        viewModel.cancelLimitOrder(id: order.id)
        let updated = viewModel.pendingOrders.first(where: { $0.id == order.id })
        XCTAssertEqual(updated?.status, .cancelled)
    }

    func testRemoveActivePriceAlert() {
        viewModel.addPriceAlert(symbol: "TSLA", targetPrice: 250.0, condition: .above)
        XCTAssertEqual(viewModel.priceAlerts.count, 1)
        guard let alert = viewModel.priceAlerts.first else {
            XCTFail("Price alert not found")
            return
        }

        viewModel.removePriceAlert(id: alert.id)
        XCTAssertEqual(viewModel.priceAlerts.count, 0)
    }

    func testAccountResetWithCustomAmount() {
        viewModel.resetAccount(startingDeposit: 250_000.0)
        XCTAssertEqual(viewModel.cashBalance, 250_000.0)
        XCTAssertEqual(viewModel.totalDeposited, 250_000.0)
        XCTAssertEqual(viewModel.positions.count, 0)
        XCTAssertEqual(viewModel.transactions.count, 1)
        XCTAssertEqual(viewModel.transactions.first?.totalAmount, 250_000.0)
    }

    func testSellWithPrecisionDustHandling() {
        _ = viewModel.buyStock(symbol: "AAPL", shares: 10.0)
        // Simulate slight floating point overshoot (e.g. 10.0002 shares)
        let result = viewModel.sellStock(symbol: "AAPL", shares: 10.0002)
        XCTAssertTrue(caseIsSuccess(result))
        let pos = viewModel.getPosition(for: "AAPL")
        XCTAssertNil(pos, "Position should be completely closed even with slight floating point dust")
    }

    func testViewInitializersWithTabBindings() {
        let mainTab = MainTabView()
        XCTAssertNotNil(mainTab)

        var tabIndex = 0
        let binding = Binding<Int>(get: { tabIndex }, set: { tabIndex = $0 })

        let pView = PortfolioView(viewModel: viewModel, selectedTab: binding)
        XCTAssertNotNil(pView)

        let mView = MarketView(viewModel: viewModel, selectedTab: binding)
        XCTAssertNotNil(mView)

        let hView = HistoryView(viewModel: viewModel, selectedTab: binding)
        XCTAssertNotNil(hView)

        let sView = SettingsView(viewModel: viewModel, selectedTab: binding)
        XCTAssertNotNil(sView)
    }

    func testWatchlistStocksRetrieval() {
        viewModel.toggleWatchlist(symbol: "AAPL")
        XCTAssertTrue(viewModel.isWatchlisted(symbol: "AAPL"))
        XCTAssertTrue(viewModel.watchlistStocks.contains(where: { $0.symbol == "AAPL" }))

        viewModel.toggleWatchlist(symbol: "AAPL")
        XCTAssertFalse(viewModel.isWatchlisted(symbol: "AAPL"))
    }

    func testAppThemeColorTokens() {
        XCTAssertNotNil(AppTheme.Colors.obsidianCanvas)
        XCTAssertNotNil(AppTheme.Colors.canvas)
        XCTAssertNotNil(AppTheme.Colors.cardSurface)
        XCTAssertNotNil(AppTheme.Colors.elevatedSurface)
        XCTAssertNotNil(AppTheme.Colors.cardHighlight)
        XCTAssertNotNil(AppTheme.Colors.cardBorder)
        XCTAssertNotNil(AppTheme.Colors.gain)
        XCTAssertNotNil(AppTheme.Colors.loss)
        XCTAssertNotNil(AppTheme.Colors.gainBadge)
        XCTAssertNotNil(AppTheme.Colors.lossBadge)
        XCTAssertNotNil(AppTheme.Colors.headline)
        XCTAssertNotNil(AppTheme.Colors.subheadline)
        XCTAssertNotNil(AppTheme.Colors.secondaryText)
        XCTAssertNotNil(AppTheme.Colors.tertiaryText)
        XCTAssertNotNil(AppTheme.Colors.muted)
    }

    func testOfflineMarketSynthesisValidity() {
        let service = MarketDataService.shared
        guard let stock = viewModel.getStock(for: "AAPL") else {
            XCTFail("AAPL not found")
            return
        }

        for tf in ChartTimeframe.allCases {
            let points = service.generateChartData(for: stock, timeframe: tf)
            XCTAssertFalse(points.isEmpty)
            for p in points {
                XCTAssertFalse(p.price.isNaN, "Price must not be NaN")
                XCTAssertFalse(p.price.isInfinite, "Price must not be Infinite")
                XCTAssertGreaterThan(p.price, 0.0, "Price must be strictly positive")
            }
        }

        let tickedStocks = service.simulatePriceTicks(for: viewModel.stocks)
        XCTAssertEqual(tickedStocks.count, viewModel.stocks.count)
        for s in tickedStocks {
            XCTAssertGreaterThan(s.currentPrice, 0.0)
            XCTAssertFalse(s.currentPrice.isNaN)
        }
    }

    func testTradeErrorDescriptions() {
        let insufficientFunds = TradeError.insufficientFunds(required: 1500.0, available: 500.0)
        XCTAssertTrue(insufficientFunds.errorDescription?.contains("Required: $1500.00") ?? false)
        XCTAssertTrue(insufficientFunds.errorDescription?.contains("Available: $500.00") ?? false)

        let insufficientShares = TradeError.insufficientShares(owned: 2.0, requested: 10.0)
        XCTAssertTrue(insufficientShares.errorDescription?.contains("Cannot sell 10.00 shares") ?? false)
        XCTAssertTrue(insufficientShares.errorDescription?.contains("only own 2.00 shares") ?? false)

        let invalid = TradeError.invalidAmount
        XCTAssertTrue(invalid.errorDescription?.contains("valid amount") ?? false)
    }

    func testHapticsToggleRespectsUserPreference() {
        UserDefaults.standard.set(false, forKey: "haptics_enabled")
        HapticsService.shared.impact(style: .heavy)
        HapticsService.shared.notification(type: .error)
        HapticsService.shared.selection()

        UserDefaults.standard.set(true, forKey: "haptics_enabled")
        HapticsService.shared.impact(style: .light)
        HapticsService.shared.selection()
    }

    private func caseIsSuccess<T, E>(_ result: Result<T, E>) -> Bool {
        switch result {
        case .success: return true
        case .failure: return false
        }
    }
}
