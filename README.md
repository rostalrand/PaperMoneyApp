# Paper Money iOS - Stock Trading Simulator App

A modern, native iOS stock market paper trading application built exclusively for iOS with **SwiftUI** and modern iOS design principles. 

Designed for anyone who wants to simulate investing in the stock market with virtual paper money: deposit any custom amount of paper money, explore live stock quotes, screen top gainers/losers, analyze price charts, execute market and advanced orders (Limit, Stop-Loss, Take-Profit), protect downside risk, set target price alerts, track trading performance analytics (Win Rate % and Realized P&L), and export transaction statements in real time.

---

## 📱 Features

- **💵 Dynamic Paper Money Deposit Engine**
  - Deposit **any custom dollar amount** you want (e.g. $250, $5,000, $1,000,000).
  - Quick-deposit preset chips (+$1K, +$5K, +$10K, +$25K, +$50K, +$100K).
  - Add optional deposit notes (e.g., "Monthly Allowance", "Practice Bankroll").
  - Clean "Reset Account" button to start fresh at $100,000 anytime.

- **📈 Real-Time Stock Market Feeds & Universal Ticker Search**
  - **Live Network Market Data**: Built-in async networking in `MarketDataService.swift` connects to real-world live market feeds (Yahoo Finance API) to fetch real live prices, volume, and 52-week highs/lows.
  - **Market Screener**: 1-tap screener pills for **Top Gainers 🟢**, **Top Losers 🔴**, **Most Active**, and **Watchlist ⭐**.
  - **Universal Ticker Search**: Search any US equity or ETF ticker (e.g., PLTR, GME, ARM, RIVN) with automatic autocompletion and live quote fetching.
  - **Live Interactive Historical Charts**: Streams live multi-timeframe candle and line chart points (`1D`, `1W`, `1M`, `1Y`, `ALL`) with real timestamps and closing prices.
  - **Pull-To-Refresh**: Native iOS pull-to-refresh support on both the Portfolio and Market screens.
  - **24/7 Offline & Weekend Fallback**: When the market is closed (evenings, weekends, holidays) or the device is offline, it automatically falls back to continuous micro-tick simulation so users can practice paper trading anytime without interruption.

- **⚡ Advanced Trading & Order Matching Engine**
  - **Market Orders**: Instant simulated paper buys and sells at current live market prices.
  - **Limit Orders**: Automated execution when price hits your target or better (buy on dips, sell on spikes).
  - **Stop-Loss Orders**: Automatic risk management trigger executing a market sell if price drops to or below your stop price, protecting capital against drawdowns.
  - **Take-Profit Orders**: Automatic profit-locking trigger executing a market sell when price surges to your target.
  - **Quick Sizing Chips**: 1-tap allocation chips (`25%`, `50%`, `75%`, `MAX`) for instant capital sizing.
  - **Order Tracking & Cancellation**: Dedicated "Orders" tab in Activity History showing status badges (`Pending`, `Filled`, `Cancelled`) with 1-tap cancellation for active orders.

- **🔔 Custom Price Alerts Engine**
  - Set custom target price alerts for any stock or ETF (`PriceAlert.swift`).
  - Choose condition: **Rises Above 🟢** or **Drops Below 🔴**.
  - Monitored continuously in the live tick evaluation loop. Triggers in-app warning banners and tactile haptic alerts when price breaches the threshold.
  - Dedicated "Alerts" tab in Activity History to view active alerts and manage deletions.

- **🏆 Trader Performance Analytics & Win-Rate Stats**
  - Comprehensive trade performance card in Activity History:
    - **Realized P&L**: Cumulative dollar profit or loss realized across all closed positions.
    - **Win Rate %**: Percentage of profitable closed trades.
    - **Total Executions**: Complete counter of market and limit fills.

- **📰 Financial Market News & Sentiment Feed**
  - Real-time curated news headlines and development briefs in `StockDetailView` (`NewsArticle.swift`).
  - Sentiment tags (`BULLISH`, `NEUTRAL`, `BEARISH`) with publisher attribution and relative timestamps.

- **🕯️ Dual-Mode Charts: Candlestick OHLC & Line Rendering**
  - Instant toggle between smooth gradient line charts and native 60fps Canvas-rendered Candlestick OHLC bars in `InteractiveChartView.swift` and `StockDetailView.swift`.
  - Real-time scrubbable Open, High, Low, Close readouts for multi-timeframe price action analysis.

- **⚙️ App Settings & iCloud Sync Diagnostics**
  - Dedicated `SettingsView.swift` triggered via a top toolbar gear button or the hero iCloud badge.
  - Live container diagnostics (`ubiquity-kvstore-identifier`, sync state, timestamp).
  - 1-tap "Force iCloud Sync" reconciliation button.
  - Quick starting capital reset selector ($10k, $25k, $50k, $100k, $500k, $1M).
  - Preferences for Privacy Mode, Haptic Feedback, and Live Micro-Ticks.

- **👁️ Quick Balance Privacy Mode**
  - Tap the Privacy Eye icon on the portfolio hero card to mask dollar values (`$ ••••••••`) and percentage returns (`+••••%`) when trading in public spaces.

- **📊 Portfolio Curve & Asset Allocation Breakdown**
  - **Portfolio Performance Curve**: Interactive chart tracking total paper equity over time with multi-timeframe controls.
  - **Asset Allocation Bar**: Visual proportional breakdown of Cash vs. Stock holdings with individual weight percentages and dynamic colors.

- **📑 Activity History & CSV Statement Export**
  - Comprehensive audit log of all deposits, buys, sells, limit orders, and alerts.
  - **CSV Export**: 1-tap export via native iOS `ShareLink` conforming to RFC-4180 for spreadsheet analysis in Excel, Apple Numbers, or Google Sheets.

- **☁️ Zero-Login Frictionless Apple iCloud Sync**
  - **No login, registration, email, or password required** — users jump straight into trading.
  - Automatically syncs cash balance, positions, transactions, limit orders, price alerts, and watchlists to the user's Apple iCloud via `NSUbiquitousKeyValueStore` when enabled.
  - Offline fallback to local `UserDefaults` persistence.

- **💰 Super Clean Google AdMob App Open Overlay**
  - Displays **one single Google AdMob App Open ad overlay** when the user launches the app.
  - **Zero banners, zero sticky ads, and zero interstitial popups** during trading — delivering an ultra-clean, pristine financial dashboard experience.
  - Configured with official Google AdMob test IDs (`ca-app-pub-3940256099942544/5575463023`) and SKAdNetwork items in `Info.plist`.

- **📳 Native iOS Haptic Feedback**
  - Tactile physical response on deposits, order executions, cancellations, alerts, and privacy mode toggles via `HapticsService.swift`.

---

## 🏗️ Project Architecture

```
PaperMoneyApp/
├── PaperMoneyApp.xcodeproj/            # Xcode project bundle
├── PaperMoneyApp/
│   ├── App/
│   │   ├── PaperMoneyApp.swift         # App entry point & dark theme setup
│   │   └── MainTabView.swift           # Root 3-tab navigation & toast banner
│   ├── Models/
│   │   ├── Stock.swift                 # Stock entity, sparkline & chart data
│   │   ├── Position.swift              # Portfolio holding & cost basis logic
│   │   ├── Transaction.swift           # Deposit, buy, and sell activity logs
│   │   ├── PortfolioSummary.swift      # Dynamic equity and return calculations
│   │   ├── LimitOrder.swift            # Limit, Stop-Loss & Take-Profit orders
│   │   ├── NewsArticle.swift           # Financial news headlines & sentiment
│   │   └── PriceAlert.swift            # Custom target price alerts model
│   ├── ViewModels/
│   │   └── PortfolioViewModel.swift    # Core reactive state machine (MVVM)
│   ├── Services/
│   │   ├── StorageService.swift        # Dual iCloud (NSUbiquitousKVS) + UserDefaults
│   │   ├── MarketDataService.swift     # Live Yahoo Finance feed, universal search, 24/7 ticks
│   │   ├── AdService.swift             # Single-launch AdMob App Open manager
│   │   └── HapticsService.swift        # Native iOS UIImpact/UINotification haptics
│   ├── Views/
│   │   ├── Portfolio/
│   │   │   ├── PortfolioView.swift     # Balance, equity chart, allocation bar & holdings
│   │   │   ├── DepositSheetView.swift  # Custom deposit & preset chips
│   │   │   └── PositionRowView.swift   # Holding item row with P&L
│   │   ├── Market/
│   │   │   ├── MarketView.swift        # Universal search & Top Gainers/Losers screener
│   │   │   ├── StockRowView.swift      # Quote row with live sparklines
│   │   │   ├── StockDetailView.swift   # Scrubbable chart, statistics, news & alert sheet
│   │   │   └── TradeSheetView.swift    # Market / Limit / Stop-Loss / Take-Profit order sheet
│   │   ├── History/
│   │   │   └── HistoryView.swift       # Filterable audit ledger, trader analytics & CSV ShareLink
│   │   ├── Settings/
│   │   │   ├── SettingsView.swift      # iCloud diagnostics, force sync & capital reset
│   │   │   └── LegalSheetView.swift    # App Store compliance disclaimers, privacy policy & terms
│   │   └── Components/
│   │       ├── InteractiveChartView.swift # Scrubbable Line & Candlestick chart component
│   │       ├── SparklineView.swift     # Inline mini sparkline
│   │       ├── StatBoxView.swift       # 2-column key metric stat box
│   │       ├── ToastBanner.swift       # Top floating execution notification
│   │       └── AppOpenAdOverlayView.swift # 1-time AdMob launch overlay
│   ├── Resources/
│   │   ├── Info.plist                  # AdMob App ID, ATT privacy & SKAdNetwork identifiers
│   │   ├── PaperMoneyApp.entitlements  # iCloud Ubiquitous Key-Value store entitlement
│   │   └── Assets.xcassets             # 1024x1024 AppIcon & AccentColor catalog
│   └── Tests/
│       └── PortfolioTests.swift        # 29 automated unit test cases
├── simulator.html                      # Standalone interactive iPhone 16 mockup
├── APP_STORE_RELEASE_GUIDE.md          # Complete App Store submission & archive guide
└── README.md                           # Documentation
```

---

## 🧪 Automated Unit Test Suite (`PortfolioTests.swift`)

The project includes 29 automated unit test cases:
1. `testInitialDeposit`: Verifies welcome grant and initial cash equity.
2. `testCustomDeposit`: Verifies custom paper money deposits and ledger records.
3. `testBuyStockSuccess`: Verifies position creation and cash deduction.
4. `testBuyStockInsufficientFunds`: Verifies rejection when cost exceeds cash balance.
5. `testSellStockSuccess`: Verifies share deduction and cash receipt.
6. `testSellEntirePositionRemovesHolding`: Verifies complete holding liquidation.
7. `testSellMoreSharesThanOwnedFails`: Verifies share ownership validation.
8. `testResetAccount`: Verifies account wipe and clean restart.
9. `testMarketDataCatalogAndChartPoints`: Verifies chart point generator accuracy.
10. `testPlaceLimitBuyOrderSuccess`: Verifies pending limit buy order creation.
11. `testLimitBuyOrderTriggersWhenPriceDrops`: Verifies automated fill on price dip.
12. `testLimitSellOrderTriggersWhenPriceRises`: Verifies automated fill on price rise.
13. `testCancelLimitOrder`: Verifies manual limit order cancellation.
14. `testAssetAllocationPercentagesSumTo100`: Verifies portfolio slice weights sum to 100%.
15. `testStopLossOrderTriggersWhenPriceDrops`: Verifies stop-loss downside risk liquidation.
16. `testTakeProfitOrderTriggersWhenPriceRises`: Verifies take-profit upside gain locking.
17. `testPrivacyModeToggle`: Verifies balance hiding mode toggle.
18. `testExportTransactionsCSV`: Verifies RFC-4180 CSV header and record generation.
19. `testNewsFeedForSymbols`: Verifies headline retrieval and sentiment structure.
20. `testAddPriceAlertAndTrigger`: Verifies custom price alert creation and breach triggering.
21. `testRemovePriceAlert`: Verifies price alert removal.
22. `testTraderAnalyticsWinRateAndRealizedPnL`: Verifies Win Rate % and Realized P&L calculations.
23. `testCandlestickPointGeneration`: Verifies OHLC point integrity (high >= low, body ranges).
24. `testResetAccountWithCustomCapital`: Verifies clearing positions and resetting cash to any custom capital tier.
25. `testScreenerCategoryFilter`: Verifies stock screener filtering across sectors, ETFs, and gainers/losers.
26. `testStorageTransactionQuotaCapping`: Verifies automatic 500-record capping for 1MB iCloud KVS quota.
27. `testStorageSnapshotQuotaCapping`: Verifies automatic 200-point performance curve snapshot capping.
28. `testAdServiceProductionSwitchAndActiveAdUnitID`: Verifies production vs. test Ad Unit ID switching.
29. `testLegalSheetTypes`: Verifies compliance document metadata and iconography.

---

## 🚀 How to Run & Verify

### 1. Web Simulator (Any browser on Windows/Mac)
Open [simulator.html](file:///C:/Users/User/.gemini/antigravity/scratch/PaperMoneyApp/simulator.html) in your browser:
- Experience the 1-time AdMob App Open launch ad.
- Check the **Welcome Guide** card on the Portfolio tab.
- Toggle between **Line** and **Candles 🕯️** charts with live OHLC readouts.
- Tap `⚙️` Gear or **iCloud Synced** badge to view container diagnostics, trigger force sync, or open **Regulatory Disclaimer**, **Privacy Policy**, and **Terms of Service**.
- Deposit custom paper money or reset starting capital to any tier ($10k to $1M).
- Toggle the Privacy Eye icon to mask account balances.
- Screen stocks with **Gainers 🟢**, **Losers 🔴**, **Watchlist ⭐**, and **ETFs** pills.
- Open AAPL, tap `🔔` to set a Price Alert.
- Size orders with `25%`, `50%`, `75%`, `MAX` chips.
- Check the **Trader Analytics** card in the Activity History tab.
- Export transaction statements to RFC-4180 CSV.

### 2. Native iOS Build in Xcode (macOS)
1. Open [PaperMoneyApp.xcodeproj](file:///C:/Users/User/.gemini/antigravity/scratch/PaperMoneyApp/PaperMoneyApp.xcodeproj/project.pbxproj) in Xcode.
2. Select your Apple Developer Team in **Signing & Capabilities**.
3. Press `Cmd + U` to run all 29 unit tests.
4. Press `Cmd + R` to run in the iOS Simulator or physical iPhone.
5. Refer to [APP_STORE_RELEASE_GUIDE.md](file:///C:/Users/User/.gemini/antigravity/scratch/PaperMoneyApp/APP_STORE_RELEASE_GUIDE.md) for full archiving and TestFlight distribution steps.
