import SwiftUI

public struct StockDetailView: View {
    @Environment(\.dismiss) private var dismiss
    public let stock: Stock
    @ObservedObject var viewModel: PortfolioViewModel

    @State private var selectedTimeframe: ChartTimeframe = .oneDay
    @State private var chartPoints: [ChartDataPoint] = []
    @State private var candles: [CandlestickPoint] = []
    @State private var chartMode: ChartDisplayMode = .line
    @State private var scrubbedPoint: ChartDataPoint? = nil
    @State private var showTradeSheet: Bool = false
    @State private var tradeType: TransactionType = .buy
    @State private var showPriceAlertSheet: Bool = false
    @State private var alertTargetPriceText: String = ""
    @State private var alertCondition: AlertCondition = .above
    @State private var selectedArticle: NewsArticle? = nil

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
        ZStack(alignment: .bottom) {
            AppTheme.Colors.obsidianCanvas
                .ignoresSafeArea()

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
                    Spacer().frame(height: 100)
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
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 14) {
                    Button {
                        alertTargetPriceText = String(format: "%.2f", liveStock.currentPrice)
                        showPriceAlertSheet = true
                    } label: {
                        Image(systemName: "bell.badge")
                            .foregroundColor(AppTheme.Colors.subheadline)
                    }
                    .accessibilityLabel("Set price alert for \(liveStock.symbol)")

                    Button {
                        viewModel.toggleWatchlist(symbol: liveStock.symbol)
                    } label: {
                        Image(systemName: isWatchlisted ? "star.fill" : "star")
                            .foregroundColor(isWatchlisted ? Color(hex: "#FFD700") : AppTheme.Colors.muted)
                    }
                    .accessibilityLabel(isWatchlisted ? "Remove \(liveStock.symbol) from watchlist" : "Add \(liveStock.symbol) to watchlist")
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
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPriceAlertSheet) {
            priceAlertSheetView
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedArticle) { article in
            articleDetailSheet(article)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Article Detail Sheet
    private func articleDetailSheet(_ article: NewsArticle) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(article.publisher)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Text("·")
                            .foregroundColor(.secondary)
                        Text(article.timeAgo)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(article.sentiment.rawValue.uppercased())
                            .font(.system(size: 10, weight: .black))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(sentimentColor(article.sentiment).opacity(0.15))
                            .foregroundColor(sentimentColor(article.sentiment))
                            .cornerRadius(6)
                    }

                    Text(article.title)
                        .font(.system(.title3, design: .rounded, weight: .bold))

                    Divider()

                    Text(article.snippet)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineSpacing(4)

                    Text("Paper Money Market Intelligence uses simulated and aggregated real-world financial signals to mirror mobile market sentiment.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 10)
                }
                .padding(20)
            }
            .navigationTitle(article.symbol)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        selectedArticle = nil
                    }
                }
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
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .font(.body.weight(.semibold))
                    .foregroundColor(.green)
                }
            }
        }
    }

    // MARK: - Price Header
    private var priceHeaderSection: some View {
        let basePrice = chartPoints.first?.price ?? liveStock.currentPrice
        let displayPrice = scrubbedPoint?.price ?? liveStock.currentPrice
        let diff = displayPrice - (scrubbedPoint != nil ? basePrice : (liveStock.currentPrice - liveStock.change))
        let pct = (displayPrice - diff) > 0 ? (diff / (displayPrice - diff)) * 100 : 0.0
        let isPos = scrubbedPoint != nil ? (diff >= 0) : liveStock.isPositive

        return VStack(alignment: .leading, spacing: 6) {
            Text(liveStock.name)
                .font(.subheadline)
                .foregroundColor(AppTheme.Colors.subheadline)

            Text("$\(String(format: "%.2f", displayPrice))")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.Colors.headline)
                .monospacedDigit()

            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: isPos ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 11, weight: .bold))
                    Text("\(isPos ? "+" : "")$\(String(format: "%.2f", abs(diff)))")
                        .font(.system(.footnote, design: .rounded, weight: .bold))
                        .monospacedDigit()
                    Text("(\(String(format: "%.2f", pct))%)")
                        .font(.system(.footnote, design: .rounded, weight: .medium))
                        .monospacedDigit()
                }
                .foregroundColor(isPos ? AppTheme.Colors.gain : AppTheme.Colors.loss)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background((isPos ? AppTheme.Colors.gainBadge : AppTheme.Colors.lossBadge))
                .cornerRadius(6)

                if let scrub = scrubbedPoint {
                    Text(formatScrubDate(scrub.timestamp))
                        .font(.caption2)
                        .foregroundColor(AppTheme.Colors.muted)
                } else {
                    Text(selectedTimeframe.rawValue)
                        .font(.caption2)
                        .foregroundColor(AppTheme.Colors.muted)
                }
            }
        }
    }

    // MARK: - Chart Section
    private var chartSection: some View {
        VStack(spacing: 14) {
            // Chart Display Mode Toggle (Line vs Candles)
            HStack {
                Spacer()
                HStack(spacing: 4) {
                    ForEach(ChartDisplayMode.allCases) { mode in
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                chartMode = mode
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: mode.iconName)
                                Text(mode.rawValue)
                            }
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(chartMode == mode ? AppTheme.Colors.cardHighlight : Color.clear)
                            .foregroundColor(chartMode == mode ? AppTheme.Colors.headline : AppTheme.Colors.muted)
                            .cornerRadius(6)
                        }
                    }
                }
                .padding(3)
                .background(AppTheme.Colors.cardSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppTheme.Colors.cardBorder, lineWidth: 1)
                )
                .cornerRadius(8)
            }

            InteractiveChartView(
                points: chartPoints,
                candles: candles,
                isPositive: (scrubbedPoint != nil ? ((scrubbedPoint!.price - (chartPoints.first?.price ?? scrubbedPoint!.price)) >= 0) : liveStock.isPositive),
                displayMode: $chartMode,
                externalSelectedPoint: $scrubbedPoint
            )
            .frame(height: 220)

            // Timeframe Segmented Control
            HStack(spacing: 6) {
                ForEach(ChartTimeframe.allCases) { tf in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedTimeframe = tf
                        }
                    } label: {
                        Text(tf.rawValue)
                            .font(.system(size: 12, weight: selectedTimeframe == tf ? .bold : .semibold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(selectedTimeframe == tf ? AppTheme.Colors.cardHighlight : Color.clear)
                            .foregroundColor(selectedTimeframe == tf ? (liveStock.isPositive ? AppTheme.Colors.gain : AppTheme.Colors.loss) : AppTheme.Colors.muted)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(4)
            .background(AppTheme.Colors.cardSurface)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(AppTheme.Colors.cardBorder, lineWidth: 1)
            )
            .cornerRadius(10)
        }
    }

    // MARK: - User Position Card
    private func userPositionCard(_ position: Position) -> some View {
        let currentVal = position.currentValue(at: liveStock.currentPrice)
        let pnl = position.unrealizedPnl(at: liveStock.currentPrice)
        let isGain = pnl >= 0

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Your Position")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundColor(AppTheme.Colors.headline)
                Spacer()
                Text("$\(formatCurrency(currentVal))")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundColor(AppTheme.Colors.headline)
                    .monospacedDigit()
            }

            Divider()
                .overlay(AppTheme.Colors.cardBorder)

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
        .background(AppTheme.Colors.cardSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.Colors.cardBorder, lineWidth: 1)
        )
        .cornerRadius(16)
    }

    // MARK: - Key Statistics
    private var keyStatisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Statistics")
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundColor(AppTheme.Colors.headline)

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
        VStack(alignment: .leading, spacing: 10) {
            Text("About \(liveStock.name)")
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundColor(AppTheme.Colors.headline)
            Text(liveStock.about)
                .font(.footnote)
                .foregroundColor(AppTheme.Colors.subheadline)
                .lineSpacing(4)
        }
        .padding(16)
        .background(AppTheme.Colors.cardSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.Colors.cardBorder, lineWidth: 1)
        )
        .cornerRadius(16)
    }

    // MARK: - News & Market Headlines
    private var newsSection: some View {
        let news = viewModel.getNews(for: liveStock.symbol)

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Market News & Analysis")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundColor(AppTheme.Colors.headline)
                Spacer()
                HStack(spacing: 4) {
                    Circle()
                        .fill(AppTheme.Colors.gain)
                        .frame(width: 6, height: 6)
                    Text("LIVE")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(AppTheme.Colors.gain)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(AppTheme.Colors.gainBadge)
                .cornerRadius(4)
            }

            VStack(spacing: 10) {
                ForEach(news) { item in
                    Button {
                        selectedArticle = item
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Text(item.publisher)
                                    .font(.system(.caption, design: .rounded, weight: .bold))
                                    .foregroundColor(AppTheme.Colors.headline)

                                Text("•")
                                    .font(.caption2)
                                    .foregroundColor(AppTheme.Colors.muted)

                                Text(item.timeAgo)
                                    .font(.caption2)
                                    .foregroundColor(AppTheme.Colors.muted)

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
                                .foregroundColor(AppTheme.Colors.headline)
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)

                            Text(item.snippet)
                                .font(.caption)
                                .foregroundColor(AppTheme.Colors.subheadline)
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                        }
                        .padding(12)
                        .background(AppTheme.Colors.cardHighlight)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppTheme.Colors.cardBorder, lineWidth: 0.8)
                        )
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(AppTheme.Colors.cardSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.Colors.cardBorder, lineWidth: 1)
        )
        .cornerRadius(16)
    }

    private func sentimentColor(_ sentiment: MarketSentiment) -> Color {
        switch sentiment {
        case .bullish: return AppTheme.Colors.gain
        case .neutral: return AppTheme.Colors.muted
        case .bearish: return AppTheme.Colors.loss
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
                        .background(AppTheme.Colors.lossBadge)
                        .foregroundColor(AppTheme.Colors.loss)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(AppTheme.Colors.loss.opacity(0.3), lineWidth: 1)
                        )
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
                    .background(AppTheme.Colors.gain)
                    .foregroundColor(Color(hex: "#080A0F"))
                    .cornerRadius(14)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppTheme.Colors.cardSurface.opacity(0.95))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(AppTheme.Colors.cardBorder),
            alignment: .top
        )
    }

    private func formatScrubDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
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
