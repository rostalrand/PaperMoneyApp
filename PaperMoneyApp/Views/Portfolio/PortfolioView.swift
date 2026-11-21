import SwiftUI

public struct PortfolioView: View {
    @ObservedObject var viewModel: PortfolioViewModel
    @Binding var selectedTab: Int
    @State private var showDepositSheet: Bool = false
    @State private var scrubbedPoint: ChartDataPoint? = nil
    @AppStorage("has_dismissed_welcome_guide") private var hasDismissedWelcomeGuide: Bool = false

    public init(viewModel: PortfolioViewModel, selectedTab: Binding<Int> = .constant(0)) {
        self.viewModel = viewModel
        self._selectedTab = selectedTab
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Onboarding Welcome Card (First Launch Only)
                    if !hasDismissedWelcomeGuide {
                        welcomeGuideCard
                    }

                    // Header Portfolio Value Card
                    portfolioHeroCard

                    // Portfolio Performance Curve Chart
                    portfolioPerformanceChart

                    // Quick Actions
                    quickActionButtons

                    // Portfolio Stats Grid
                    portfolioStatsGrid

                    // Asset Allocation Section
                    assetAllocationSection

                    // Active Holdings Section
                    positionsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .refreshable {
                await viewModel.fetchLiveMarketData()
            }
            .navigationTitle("Paper Portfolio")
            .navigationDestination(for: Stock.self) { stock in
                StockDetailView(stock: stock, viewModel: viewModel)
            }
            .sheet(isPresented: $showDepositSheet) {
                DepositSheetView(viewModel: viewModel)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Onboarding Welcome Guide
    private var welcomeGuideCard: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "sparkles")
                .font(.system(size: 22))
                .foregroundColor(.yellow)
                .padding(10)
                .background(Color.yellow.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("Welcome to Paper Money!")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            hasDismissedWelcomeGuide = true
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(4)
                    }
                    .buttonStyle(.plain)
                }

                Text("You have $100,000 in virtual paper capital to practice trading US equities without risk. Your balances automatically sync to your personal Apple iCloud.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineSpacing(2)

                HStack(spacing: 8) {
                    Button {
                        showDepositSheet = true
                    } label: {
                        Text("Add Custom Funds")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.Colors.gain)
                    }

                    Text("·")
                        .foregroundColor(AppTheme.Colors.secondaryText)

                    Button {
                        selectedTab = 1
                    } label: {
                        Text("Start Trading")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.blue)
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(16)
        .background(AppTheme.Colors.cardSurface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.Colors.cardBorder, lineWidth: 1)
        )
    }

    // MARK: - Hero Card
    private var portfolioHeroCard: some View {
        let summary = viewModel.summary

        // If user is scrubbing the chart, dynamically display scrubbed balance and delta
        let displayValue: Double = scrubbedPoint?.price ?? summary.totalValue
        let baseValue = viewModel.portfolioSnapshots.first?.price ?? summary.totalDeposited
        let deltaFromStart: Double = scrubbedPoint != nil ? (displayValue - baseValue) : summary.unrealizedReturn
        let deltaPercent: Double = scrubbedPoint != nil ? ((deltaFromStart / max(1.0, baseValue)) * 100) : summary.unrealizedReturnPercent
        let isScrubGain = deltaFromStart >= 0

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("INVESTING")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.Colors.secondaryText)
                    .tracking(1.2)

                Spacer()

                Button {
                    viewModel.togglePrivacyMode()
                } label: {
                    Image(systemName: viewModel.isPrivacyMode ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.secondaryText)
                        .padding(6)
                        .background(AppTheme.Colors.elevatedSurface)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(viewModel.isPrivacyMode ? "Show portfolio balance" : "Hide portfolio balance")

                HStack(spacing: 4) {
                    Image(systemName: "icloud.fill")
                        .font(.system(size: 10, weight: .semibold))
                    Text(StorageService.shared.isICloudAvailable ? "iCloud" : "Local")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
                .foregroundColor(Color.blue.opacity(0.9))
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color.blue.opacity(0.12))
                .cornerRadius(6)
            }

            Text(viewModel.isPrivacyMode ? "$ ••••••••" : "$\(formatCurrency(displayValue))")
                .font(AppTheme.Fonts.heroBalance)
                .foregroundColor(.primary)
                .monospacedDigit()

            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: isScrubGain ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 10, weight: .bold))
                    Text(viewModel.isPrivacyMode ? "$ ••••" : "\(isScrubGain ? "+" : "")$\(formatCurrency(abs(deltaFromStart)))")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .monospacedDigit()
                    Text(viewModel.isPrivacyMode ? "(••••%)" : "(\(String(format: "%.2f", deltaPercent))%)")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .monospacedDigit()
                }
                .foregroundColor(isScrubGain ? AppTheme.Colors.gain : AppTheme.Colors.loss)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isScrubGain ? AppTheme.Colors.gainBadge : AppTheme.Colors.lossBadge)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke((isScrubGain ? AppTheme.Colors.gain : AppTheme.Colors.loss).opacity(0.2), lineWidth: 0.5)
                )

                if let scrub = scrubbedPoint {
                    Text(formatDate(scrub.timestamp))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.Colors.secondaryText)
                } else {
                    Text("Total Return")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.Colors.secondaryText)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(AppTheme.Colors.cardSurface)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppTheme.Colors.cardBorder, lineWidth: 1)
        )
    }

    // MARK: - Action Buttons
    private var quickActionButtons: some View {
        let topMover = viewModel.stocks.max(by: { $0.changePercent < $1.changePercent }) ?? viewModel.stocks.first

        return HStack(spacing: 12) {
            Button {
                showDepositSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 15, weight: .bold))
                    Text("Deposit Money")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppTheme.Colors.gain)
                .foregroundColor(.black)
                .cornerRadius(14)
            }

            if let mover = topMover {
                NavigationLink(value: mover) {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 15, weight: .bold))
                        Text("Top Mover")
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.Colors.elevatedSurface)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(AppTheme.Colors.cardBorder, lineWidth: 1)
                    )
                }
            }
        }
    }

    // MARK: - Stats Grid
    private var portfolioStatsGrid: some View {
        let summary = viewModel.summary

        return HStack(spacing: 10) {
            StatBoxView(
                title: "Cash Available",
                value: viewModel.isPrivacyMode ? "$ ••••••" : "$\(formatCurrency(summary.cashBalance))",
                subtitle: "Ready to trade"
            )

            StatBoxView(
                title: "Stock Equity",
                value: viewModel.isPrivacyMode ? "$ ••••••" : "$\(formatCurrency(summary.investedEquity))",
                subtitle: "\(viewModel.positions.count) holdings"
            )

            StatBoxView(
                title: "Total Deposited",
                value: viewModel.isPrivacyMode ? "$ ••••••" : "$\(formatCurrency(summary.totalDeposited))",
                subtitle: "Paper base"
            )
        }
    }

    // MARK: - Performance Chart
    private var portfolioPerformanceChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Portfolio Performance")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.Colors.secondaryText)
                    .textCase(.uppercase)
                    .tracking(0.8)
                Spacer()
                Text("\(viewModel.portfolioSnapshots.count) snapshots")
                    .font(.caption2)
                    .foregroundColor(AppTheme.Colors.secondaryText)
            }

            InteractiveChartView(
                points: viewModel.portfolioSnapshots,
                isPositive: viewModel.summary.unrealizedReturn >= 0,
                externalSelectedPoint: $scrubbedPoint
            )
            .frame(height: 130)
        }
        .padding(16)
        .background(AppTheme.Colors.cardSurface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.Colors.cardBorder, lineWidth: 1)
        )
    }

    // MARK: - Asset Allocation Section
    private var assetAllocationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Asset Allocation")
                    .font(.headline)
                Spacer()
                Text("100% Capital")
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.secondaryText)
            }

            // Segmented Progress Bar
            GeometryReader { geometry in
                HStack(spacing: 2) {
                    ForEach(viewModel.assetAllocation) { slice in
                        let sliceWidth = max(2, (CGFloat(slice.percentage) / 100.0) * geometry.size.width)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(hex: slice.colorHex))
                            .frame(width: sliceWidth, height: 10)
                    }
                }
            }
            .frame(height: 10)

            // Allocation Legend (Interactive)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(viewModel.assetAllocation) { slice in
                    if slice.symbol == "CASH" {
                        Button {
                            showDepositSheet = true
                        } label: {
                            allocationLegendItem(slice: slice)
                        }
                        .buttonStyle(.plain)
                    } else if let stock = viewModel.getStock(for: slice.symbol) {
                        NavigationLink(value: stock) {
                            allocationLegendItem(slice: slice)
                        }
                        .buttonStyle(.plain)
                    } else {
                        allocationLegendItem(slice: slice)
                    }
                }
            }
        }
        .padding(16)
        .background(AppTheme.Colors.cardSurface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.Colors.cardBorder, lineWidth: 1)
        )
    }

    private func allocationLegendItem(slice: PortfolioViewModel.AssetSlice) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color(hex: slice.colorHex))
                .frame(width: 8, height: 8)
            Text(slice.symbol)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Spacer()
            Text("\(String(format: "%.1f", slice.percentage))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color(UIColor.tertiarySystemGroupedBackground))
        .cornerRadius(8)
    }

    // MARK: - Positions / Holdings
    private var positionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Holdings")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                Spacer()
                Text("\(viewModel.positions.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(UIColor.tertiarySystemGroupedBackground))
                    .cornerRadius(10)
            }

            if viewModel.positions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.pie")
                        .font(.system(size: 44))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No stock holdings yet")
                        .font(.headline)
                    Text("Use your paper money to buy shares of Apple, Tesla, Nvidia and more!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    HStack(spacing: 12) {
                        Button {
                            selectedTab = 1
                        } label: {
                            Text("Browse Stock Market")
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.green.opacity(0.15))
                                .foregroundColor(.green)
                                .cornerRadius(10)
                        }

                        Button {
                            showDepositSheet = true
                        } label: {
                            Text("Deposit Cash")
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color(UIColor.tertiarySystemGroupedBackground))
                                .foregroundColor(.primary)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 36)
                .background(AppTheme.Colors.cardSurface)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.Colors.cardBorder, lineWidth: 1)
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.positions) { position in
                        if let stock = viewModel.getStock(for: position.symbol) {
                            NavigationLink(value: stock) {
                                PositionRowView(position: position, stock: stock)
                            }
                            .buttonStyle(.plain)

                            if position.id != viewModel.positions.last?.id {
                                Divider()
                                    .background(AppTheme.Colors.cardBorder)
                                    .padding(.leading, 8)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(AppTheme.Colors.cardSurface)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.Colors.cardBorder, lineWidth: 1)
                )
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }
}
