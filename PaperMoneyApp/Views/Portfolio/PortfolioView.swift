import SwiftUI

public struct PortfolioView: View {
    @ObservedObject var viewModel: PortfolioViewModel
    @Binding var selectedTab: Int
    @State private var showDepositSheet: Bool = false
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
                            .foregroundColor(.green)
                    }

                    Text("·")
                        .foregroundColor(.secondary)

                    Button {
                        selectedTab = 1
                    } label: {
                        Text("Start Trading")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.yellow.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Hero Card
    private var portfolioHeroCard: some View {
        let summary = viewModel.summary
        let isGain = summary.unrealizedReturn >= 0

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("TOTAL PORTFOLIO VALUE")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundColor(.secondary)
                    .tracking(1.0)
                Spacer()
                Button {
                    viewModel.togglePrivacyMode()
                } label: {
                    Image(systemName: viewModel.isPrivacyMode ? "eye.slash.fill" : "eye.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(5)
                        .background(Color(UIColor.tertiarySystemGroupedBackground))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                HStack(spacing: 4) {
                    Image(systemName: "icloud.fill")
                        .font(.caption2)
                    Text(StorageService.shared.isICloudAvailable ? "iCloud" : "Local")
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.blue.opacity(0.85))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.12))
                .cornerRadius(6)
            }

            Text(viewModel.isPrivacyMode ? "$ ••••••••" : "$\(formatCurrency(summary.totalValue))")
                .font(.system(size: 38, weight: .heavy, design: .rounded))
                .foregroundColor(.primary)

            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: isGain ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption)
                    Text(viewModel.isPrivacyMode ? "$ ••••" : "\(isGain ? "+" : "")$\(formatCurrency(abs(summary.unrealizedReturn)))")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    Text(viewModel.isPrivacyMode ? "(••••%)" : "(\(String(format: "%.2f", summary.unrealizedReturnPercent))%)")
                        .font(.caption)
                }
                .foregroundColor(isGain ? .green : .red)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background((isGain ? Color.green : Color.red).opacity(0.15))
                .cornerRadius(8)

                Text("unrealized return")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
    }

    // MARK: - Action Buttons
    private var quickActionButtons: some View {
        let topMover = viewModel.stocks.max(by: { $0.changePercent < $1.changePercent }) ?? viewModel.stocks.first

        return HStack(spacing: 12) {
            Button {
                showDepositSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Deposit Money")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(14)
            }

            if let mover = topMover {
                NavigationLink(value: mover) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                        Text("Top Mover")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(UIColor.tertiarySystemGroupedBackground))
                    .foregroundColor(.primary)
                    .cornerRadius(14)
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
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                Spacer()
                Text("\(viewModel.portfolioSnapshots.count) snapshots")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            InteractiveChartView(
                points: viewModel.portfolioSnapshots,
                isPositive: viewModel.summary.unrealizedReturn >= 0
            )
            .frame(height: 120)
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
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
                    .foregroundColor(.secondary)
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
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
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
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(16)
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
                                    .padding(.leading, 8)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(16)
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

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
