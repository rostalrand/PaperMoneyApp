import SwiftUI

public enum MarketCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case watchlist = "Watchlist"
    case gainers = "Gainers"
    case losers = "Losers"
    case tech = "Tech"
    case etfs = "ETFs"
    case crypto = "Crypto"

    public var id: String { rawValue }

    public var iconName: String? {
        switch self {
        case .all: return nil
        case .watchlist: return "star.fill"
        case .gainers: return "arrow.up.right"
        case .losers: return "arrow.down.right"
        case .tech: return "desktopcomputer"
        case .etfs: return "chart.pie.fill"
        case .crypto: return "bitcoinsign.circle.fill"
        }
    }
}

public struct MarketView: View {
    @ObservedObject var viewModel: PortfolioViewModel
    @Binding var selectedTab: Int
    @State private var searchText: String = ""
    @State private var selectedCategory: MarketCategory = .all
    @State private var quickTradeStock: Stock? = nil

    public init(viewModel: PortfolioViewModel, selectedTab: Binding<Int> = .constant(1)) {
        self.viewModel = viewModel
        self._selectedTab = selectedTab
    }

    private var filteredStocks: [Stock] {
        var list = viewModel.stocks

        // Category & Screener filters
        switch selectedCategory {
        case .all:
            break
        case .watchlist:
            list = viewModel.watchlistStocks
        case .gainers:
            list = list.sorted { $0.changePercent > $1.changePercent }
        case .losers:
            list = list.sorted { $0.changePercent < $1.changePercent }
        case .tech:
            list = list.filter { $0.sector.contains("Tech") || $0.sector.contains("Internet") || $0.sector.contains("Semiconductors") }
        case .etfs:
            list = list.filter { $0.sector.contains("ETF") }
        case .crypto:
            list = list.filter { $0.sector.contains("Crypto") || $0.symbol == "COIN" }
        }

        // Search text query
        if !searchText.isEmpty {
            let query = searchText.lowercased().trimmingCharacters(in: .whitespaces)
            list = list.filter {
                $0.symbol.lowercased().contains(query) ||
                $0.name.lowercased().contains(query)
            }
        }

        return list
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Top Search Bar (Always visible immediately at the top - no hidden navigation drawers)
                searchBarSection

                // Category Screener Pills (Always directly underneath the search bar)
                filterPillsBar

                // Stocks List
                if filteredStocks.isEmpty {
                    if selectedCategory == .watchlist {
                        VStack(spacing: 12) {
                            Image(systemName: "star.slash")
                                .font(.system(size: 40))
                                .foregroundColor(AppTheme.Colors.secondaryText)
                                .padding(.top, 40)
                            Text("Your Watchlist is Empty")
                                .font(.system(.headline, design: .rounded, weight: .bold))
                            Text("Star stocks in the market list or on stock detail pages to monitor your favorite tickers here.")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(AppTheme.Colors.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                            Button {
                                selectedCategory = .all
                            } label: {
                                Text("View All Stocks")
                                    .font(.system(.footnote, design: .rounded, weight: .bold))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(AppTheme.Colors.gainBadge)
                                    .foregroundColor(AppTheme.Colors.gain)
                                    .cornerRadius(10)
                            }
                            .padding(.top, 4)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundColor(AppTheme.Colors.secondaryText)
                                .padding(.top, 40)
                            Text("No matching stocks")
                                .font(.system(.headline, design: .rounded, weight: .bold))
                            Text("Try searching for symbols like AAPL, NVDA, TSLA, SPY")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(AppTheme.Colors.secondaryText)
                            if !searchText.isEmpty {
                                Button {
                                    searchText = ""
                                } label: {
                                    Text("Clear Search")
                                        .font(.system(.footnote, design: .rounded, weight: .bold))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(AppTheme.Colors.gainBadge)
                                        .foregroundColor(AppTheme.Colors.gain)
                                        .cornerRadius(10)
                                }
                                .padding(.top, 4)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else {
                    List {
                        ForEach(filteredStocks) { stock in
                            NavigationLink(value: stock) {
                                StockRowView(stock: stock)
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    viewModel.toggleWatchlist(symbol: stock.symbol)
                                    HapticsService.shared.impact(style: .light)
                                } label: {
                                    Label(
                                        viewModel.isWatchlisted(symbol: stock.symbol) ? "Unstar" : "Watch",
                                        systemImage: viewModel.isWatchlisted(symbol: stock.symbol) ? "star.slash.fill" : "star.fill"
                                    )
                                }
                                .tint(.yellow)
                            }
                            .swipeActions(edge: .trailing) {
                                Button {
                                    quickTradeStock = stock
                                } label: {
                                    Label("Trade", systemImage: "arrow.left.arrow.right")
                                }
                                .tint(AppTheme.Colors.gain)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            .background(AppTheme.Colors.obsidianCanvas.ignoresSafeArea())
            .navigationTitle("Stock Market")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: searchText) { newValue in
                if newValue.count >= 2 {
                    Task {
                        _ = await viewModel.searchUniversalStocks(query: newValue)
                    }
                }
            }
            .refreshable {
                await viewModel.fetchLiveMarketData()
            }
            .navigationDestination(for: Stock.self) { stock in
                StockDetailView(stock: stock, viewModel: viewModel)
            }
            .sheet(item: $quickTradeStock) { stock in
                TradeSheetView(stock: stock, viewModel: viewModel, initialTradeType: .buy)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Search Bar Section (Always visible immediately)
    private var searchBarSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppTheme.Colors.secondaryText)
                .font(.system(size: 14, weight: .semibold))

            TextField("Search symbol or company (e.g. AAPL, PLTR)...", text: $searchText)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.characters)
                .onSubmit {
                    Task {
                        _ = await viewModel.searchUniversalStocks(query: searchText)
                    }
                }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppTheme.Colors.secondaryText)
                        .font(.system(size: 14))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(AppTheme.Colors.cardSurface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.Colors.cardBorder, lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: - Screener Filter Bar (Positioned directly underneath the search bar)
    private var filterPillsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MarketCategory.allCases) { category in
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                            selectedCategory = category
                        }
                        HapticsService.shared.selection()
                    } label: {
                        HStack(spacing: 5) {
                            if let icon = category.iconName {
                                Image(systemName: icon)
                                    .font(.system(size: 11, weight: .bold))
                            }
                            Text(category.rawValue)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            selectedCategory == category
                                ? AppTheme.Colors.gain
                                : AppTheme.Colors.cardSurface
                        )
                        .foregroundColor(selectedCategory == category ? .black : .white)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(selectedCategory == category ? Color.clear : AppTheme.Colors.cardBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}
