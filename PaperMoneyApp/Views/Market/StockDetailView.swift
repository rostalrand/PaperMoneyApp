import SwiftUI

public struct StockDetailView: View {
    @Environment(\.dismiss) private var dismiss
    public let stock: Stock
    @ObservedObject var viewModel: PortfolioViewModel

    @State private var selectedTimeframe: ChartTimeframe = .oneDay
    @State private var chartPoints: [ChartDataPoint] = []
    @State private var candles: [CandlestickPoint] = []
    @State private var chartMode: ChartDisplayMode = .line
    @State private var showTradeSheet: Bool = false
    @State private var tradeType: TransactionType = .buy
    @State private var showPriceAlertSheet: Bool = false
    @State private var alertTargetPriceText: String = ""
    @State private var alertCondition: AlertCondition = .above

    public init(stock: Stock, viewModel: PortfolioViewModel) {
        self.stock = stock
        self.viewModel = viewModel
    }

    private var liveStock: Stock {
        viewModel.getStock(for: stock.symbol) ?? stock
    }

    private var ownedPosition: Position? {
        viewModel.getPosition(for: stock.symbol)
    }

    private var isWatchlisted: Bool {
        viewModel.isWatchlisted(symbol: stock.symbol)
    }

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header Price and Change
                        priceHeaderSection

                        // Interactive Chart
                        chartSection

                        // User's Position if held
                        if let pos = ownedPosition {
                            userPositionCard(pos)
                        }

                        // Key Statistics Grid
                        keyStatisticsSection

                        // Company About
                        aboutSection

                        // Market News & Sentiment Section
                        newsSection

                        // Bottom padding for sticky button
                        Spacer().frame(height: 80)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }

                // Sticky Bottom Trade Bar
                bottomTradeBar
            }
            .navigationTitle(liveStock.symbol)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 14) {
                        Button {
                            alertTargetPriceText = String(format: "%.2f", liveStock.currentPrice)
                            showPriceAlertSheet = true
                        } label: {
                            Image(systemName: "bell.badge")
                                .foregroundColor(.primary)
                        }

                        Button {
                            viewModel.toggleWatchlist(symbol: liveStock.symbol)
                        } label: {
                            Image(systemName: isWatchlisted ? "star.fill" : "star")
                                .foregroundColor(isWatchlisted ? .yellow : .secondary)
                        }
                    }
                }
            }
            .onAppear {
                loadChart()
            }
            .onChange(of: selectedTimeframe) { _ in
                loadChart()
            }
            .sheet(isPresented: $showTradeSheet) {
                TradeSheetView(stock: liveStock, viewModel: viewModel, initialTradeType: tradeType)
            }
            .sheet(isPresented: $showPriceAlertSheet) {
                priceAlertSheetView
            }
        }
    }

    // MARK: - Price Alert Sheet
    private var priceAlertSheetView: some View {
        NavigationStack {
            Form {
                Section("Alert Condition") {
                    Picker("Condition", selection: $alertCondition) {
                        ForEach(AlertCondition.allCases, id: \.self) { cond in
                            Text(cond.rawValue).tag(cond)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Text("Target Price")
                            .font(.subheadline)
                        Spacer()
                        Text("$")
                            .foregroundColor(.secondary)
                        TextField("0.00", text: $alertTargetPriceText)
                            .keyboardType(.decimalPad)
                            .font(.system(.body, design: .rounded, weight: .bold))
                            .multilineTextAlignment(.trailing)
                            .frame(width: 90)
                    }

                    HStack {
                        Text("Current Market Price")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                        Spacer()
                        Text("$\(String(format: "%.2f", liveStock.currentPrice))")
                            .font(.system(.footnote, design: .rounded, weight: .semibold))
                    }
                }

                Section {
                    Button {
                        if let target = Double(alertTargetPriceText.replacingOccurrences(of: ",", with: "")) {
                            viewModel.addPriceAlert(symbol: liveStock.symbol, targetPrice: target, condition: alertCondition)
                            showPriceAlertSheet = false
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text("Set Price Alert")
                                .font(.headline)
                                .fontWeight(.bold)
                            Spacer()
                        }
                    }
                    .tint(.green)
                } footer: {
                    Text("You will receive an in-app banner and tactile alert when live ticks cross your target price.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Alert for \(liveStock.symbol)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showPriceAlertSheet = false
                    }
                }
            }
        }
    }

    // MARK: - Price Header
    private var priceHeaderSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(liveStock.name)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("$\(String(format: "%.2f", liveStock.currentPrice))")
                .font(.system(size: 36, weight: .heavy, design: .rounded))

            HStack(spacing: 6) {
                Image(systemName: liveStock.isPositive ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption)
                Text("\(liveStock.isPositive ? "+" : "")$\(String(format: "%.2f", abs(liveStock.change)))")
                    .fontWeight(.semibold)
                Text("(\(String(format: "%.2f", liveStock.changePercent))%) Today")
            }
            .font(.footnote)
            .foregroundColor(liveStock.isPositive ? .green : .red)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background((liveStock.isPositive ? Color.green : Color.red).opacity(0.12))
            .cornerRadius(8)
        }
    }

    // MARK: - Chart Section
    private var chartSection: some View {
        VStack(spacing: 12) {
            // Chart Display Mode Toggle (Line vs Candles)
            HStack {
                Spacer()
                HStack(spacing: 2) {
                    ForEach(ChartDisplayMode.allCases) { mode in
                        Button {
                            chartMode = mode
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: mode.iconName)
                                Text(mode.rawValue)
                            }
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(chartMode == mode ? Color.green.opacity(0.2) : Color.clear)
                            .foregroundColor(chartMode == mode ? .green : .secondary)
                            .cornerRadius(6)
                        }
                    }
                }
                .padding(3)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(8)
            }

            InteractiveChartView(
                points: chartPoints,
                candles: candles,
                isPositive: liveStock.isPositive,
                displayMode: $chartMode
            )
            .frame(height: 200)

            // Timeframe Segmented Control
            HStack(spacing: 4) {
                ForEach(ChartTimeframe.allCases) { tf in
                    Button {
                        selectedTimeframe = tf
                    } label: {
                        Text(tf.rawValue)
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(selectedTimeframe == tf ? Color.green.opacity(0.2) : Color.clear)
                            .foregroundColor(selectedTimeframe == tf ? .green : .secondary)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(4)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(10)
        }
    }

    // MARK: - User Position Card
    private func userPositionCard(_ position: Position) -> some View {
        let currentVal = position.currentValue(at: liveStock.currentPrice)
        let pnl = position.unrealizedPnl(at: liveStock.currentPrice)
        let isGain = pnl >= 0

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Holding")
                    .font(.headline)
                Spacer()
                Text("Market Value: $\(formatCurrency(currentVal))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            Divider()

            HStack(spacing: 12) {
                StatBoxView(title: "Shares Owned", value: formatShares(position.shares))
                StatBoxView(title: "Average Cost", value: "$\(String(format: "%.2f", position.averagePrice))")
                StatBoxView(
                    title: "Total Return",
                    value: "\(isGain ? "+" : "")$\(formatCurrency(abs(pnl)))",
                    subtitle: "\(String(format: "%.2f", position.returnPercent(at: liveStock.currentPrice)))%",
                    isPositive: isGain
                )
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    // MARK: - Key Statistics
    private var keyStatisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Statistics")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                StatBoxView(title: "Market Cap", value: liveStock.marketCap)
                StatBoxView(title: "P/E Ratio", value: liveStock.peRatio != nil ? String(format: "%.1f", liveStock.peRatio!) : "—")
                StatBoxView(title: "52-Week High", value: "$\(String(format: "%.2f", liveStock.high52))")
                StatBoxView(title: "52-Week Low", value: "$\(String(format: "%.2f", liveStock.low52))")
                StatBoxView(title: "Volume", value: liveStock.volume)
                StatBoxView(title: "Sector", value: liveStock.sector)
            }
        }
    }

    // MARK: - About Company
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About \(liveStock.name)")
                .font(.headline)
            Text(liveStock.about)
                .font(.footnote)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    // MARK: - News & Market Headlines
    private var newsSection: some View {
        let news = viewModel.getNews(for: liveStock.symbol)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Market News & Analysis")
                    .font(.headline)
                Spacer()
                Text("Live Feed")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.12))
                    .foregroundColor(.green)
                    .cornerRadius(4)
            }

            VStack(spacing: 10) {
                ForEach(news) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Text(item.publisher)
                                .font(.system(.caption, design: .rounded, weight: .bold))
                                .foregroundColor(.primary)

                            Text("•")
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            Text(item.timeAgo)
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            Spacer()

                            Text(item.sentiment.rawValue.uppercased())
                                .font(.system(size: 9, weight: .black))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(sentimentColor(item.sentiment).opacity(0.15))
                                .foregroundColor(sentimentColor(item.sentiment))
                                .cornerRadius(6)
                        }

                        Text(item.title)
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(2)

                        Text(item.snippet)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    .padding(12)
                    .background(Color(UIColor.tertiarySystemGroupedBackground))
                    .cornerRadius(12)
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    private func sentimentColor(_ sentiment: MarketSentiment) -> Color {
        switch sentiment {
        case .bullish: return .green
        case .neutral: return .secondary
        case .bearish: return .red
        }
    }

    // MARK: - Sticky Bottom Trade Bar
    private var bottomTradeBar: some View {
        HStack(spacing: 12) {
            if let pos = ownedPosition, pos.shares > 0 {
                Button {
                    tradeType = .sell
                    showTradeSheet = true
                } label: {
                    Text("Sell")
                        .font(.headline)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red.opacity(0.15))
                        .foregroundColor(.red)
                        .cornerRadius(14)
                }
            }

            Button {
                tradeType = .buy
                showTradeSheet = true
            } label: {
                Text("Buy \(liveStock.symbol)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    private func loadChart() {
        // Instant visual render from local store
        chartPoints = MarketDataService.shared.generateChartData(for: liveStock, timeframe: selectedTimeframe)
        candles = MarketDataService.shared.generateCandlestickData(for: liveStock, timeframe: selectedTimeframe)

        // Asynchronously fetch live real-world chart points from market feed
        Task {
            let livePoints = await MarketDataService.shared.fetchLiveChartData(for: liveStock, timeframe: selectedTimeframe)
            await MainActor.run {
                if !livePoints.isEmpty {
                    self.chartPoints = livePoints
                }
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

    private func formatShares(_ shares: Double) -> String {
        if shares.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", shares)
        } else {
            return String(format: "%.3f", shares)
        }
    }
}
