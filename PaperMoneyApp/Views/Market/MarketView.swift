import SwiftUI

public struct MarketView: View {
    @ObservedObject var viewModel: PortfolioViewModel
    @State private var searchText: String = ""
    @State private var selectedFilter: String = "All"
    @State private var selectedStock: Stock? = nil

    private let filterOptions = ["All", "Watchlist ⭐", "Gainers 🟢", "Losers 🔴", "Tech", "ETFs"]

    public init(viewModel: PortfolioViewModel) {
        self.viewModel = viewModel
    }

    private var filteredStocks: [Stock] {
        var list = viewModel.stocks

        // Category & Screener filters
        if selectedFilter == "Watchlist ⭐" {
            list = viewModel.watchlistStocks
        } else if selectedFilter == "Gainers 🟢" {
            list = list.sorted { $0.changePercent > $1.changePercent }
        } else if selectedFilter == "Losers 🔴" {
            list = list.sorted { $0.changePercent < $1.changePercent }
        } else if selectedFilter == "Tech" {
            list = list.filter { $0.sector.contains("Tech") || $0.sector.contains("Internet") }
        } else if selectedFilter == "ETFs" {
            list = list.filter { $0.sector.contains("ETF") }
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
                // Category Filter Pills
                filterPillsBar

                // Stocks List
                if filteredStocks.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                            .padding(.top, 40)
                        Text("No matching stocks")
                            .font(.headline)
                        Text("Try searching for symbols like AAPL, NVDA, TSLA, SPY")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredStocks) { stock in
                            Button {
                                selectedStock = stock
                            } label: {
                                StockRowView(stock: stock)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Stock Market")
            .searchable(text: $searchText, prompt: "Search any ticker or ETF (e.g. PLTR, GME)")
            .onSubmit(of: .search) {
                Task {
                    _ = await viewModel.searchUniversalStocks(query: searchText)
                }
            }
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
            .sheet(item: $selectedStock) { stock in
                StockDetailView(stock: stock, viewModel: viewModel)
            }
        }
    }

    private var filterPillsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filterOptions, id: \.self) { filter in
                    Button {
                        selectedFilter = filter
                    } label: {
                        Text(filter)
                            .font(.system(.footnote, design: .rounded, weight: .semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                selectedFilter == filter
                                    ? Color.green
                                    : Color(UIColor.secondarySystemGroupedBackground)
                            )
                            .foregroundColor(selectedFilter == filter ? .white : .primary)
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
}
