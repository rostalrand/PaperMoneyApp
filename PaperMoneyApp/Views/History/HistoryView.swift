import SwiftUI

public enum HistoryDomain: String, CaseIterable, Identifiable {
    case activity = "Activity"
    case orders = "Orders"
    case alerts = "Alerts"

    public var id: String { rawValue }
}

public struct HistoryView: View {
    @ObservedObject var viewModel: PortfolioViewModel
    @Binding var selectedTab: Int
    @State private var selectedDomain: HistoryDomain = .activity
    @State private var activityFilter: String = "All"

    private let activityFilterOptions = ["All", "Buys", "Sells", "Deposits"]

    public init(viewModel: PortfolioViewModel, selectedTab: Binding<Int> = .constant(2)) {
        self.viewModel = viewModel
        self._selectedTab = selectedTab
    }

    private var filteredTransactions: [Transaction] {
        switch activityFilter {
        case "Deposits":
            return viewModel.transactions.filter { $0.type == .deposit }
        case "Buys":
            return viewModel.transactions.filter { $0.type == .buy }
        case "Sells":
            return viewModel.transactions.filter { $0.type == .sell }
        default:
            return viewModel.transactions
        }
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tier 1: Primary Domain Segment (Activity, Orders, Alerts)
                Picker("Domain", selection: $selectedDomain) {
                    ForEach(HistoryDomain.allCases) { domain in
                        Text(domain.rawValue).tag(domain)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 6)

                // Trader Performance Card
                analyticsCard

                // Tier 2: Activity Sub-filter Pills (Only shown when domain is Activity)
                if selectedDomain == .activity {
                    activityFilterPills
                }

                if selectedDomain == .orders {
                    if viewModel.pendingOrders.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "clock.badge.checkmark")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                                .padding(.top, 40)
                            Text("No Limit Orders Placed")
                                .font(.headline)
                            Text("Set target buy or sell prices in the Trade sheet to place automated Limit Orders.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)

                            Button {
                                selectedTab = 1
                            } label: {
                                Text("Explore Market & Set Orders")
                                    .font(.footnote)
                                    .fontWeight(.bold)
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
                        List {
                            ForEach(viewModel.pendingOrders) { order in
                                Group {
                                    if let stock = viewModel.getStock(for: order.symbol) {
                                        NavigationLink(value: stock) {
                                            orderRow(order)
                                        }
                                    } else {
                                        orderRow(order)
                                    }
                                }
                                .swipeActions(edge: .trailing) {
                                    if order.status == .pending {
                                        Button(role: .destructive) {
                                            viewModel.cancelLimitOrder(id: order.id)
                                        } label: {
                                            Label("Cancel", systemImage: "xmark.circle")
                                        }
                                    }
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                        .scrollDismissesKeyboard(.interactively)
                    }
                } else if selectedDomain == .alerts {
                    if viewModel.priceAlerts.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "bell.slash")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                                .padding(.top, 40)
                            Text("No Price Alerts Set")
                                .font(.headline)
                            Text("Open any stock detail view and tap the bell icon to set customized target alerts.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)

                            Button {
                                selectedTab = 1
                            } label: {
                                Text("Browse Stocks to Set Alerts")
                                    .font(.footnote)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.blue.opacity(0.15))
                                    .foregroundColor(.blue)
                                    .cornerRadius(10)
                            }
                            .padding(.top, 4)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(viewModel.priceAlerts) { alert in
                                Group {
                                    if let stock = viewModel.getStock(for: alert.symbol) {
                                        NavigationLink(value: stock) {
                                            alertRow(alert)
                                        }
                                    } else {
                                        alertRow(alert)
                                    }
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        viewModel.removePriceAlert(id: alert.id)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                        .scrollDismissesKeyboard(.interactively)
                    }
                } else if filteredTransactions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                            .padding(.top, 40)
                        Text("No transactions recorded")
                            .font(.headline)
                        Text("When you deposit paper money or execute trades, they will appear here.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        Button {
                            selectedTab = 1
                        } label: {
                            Text("Browse Stock Market")
                                .font(.footnote)
                                .fontWeight(.bold)
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
                    List {
                        ForEach(filteredTransactions) { tx in
                            if let symbol = tx.symbol, let stock = viewModel.getStock(for: symbol) {
                                NavigationLink(value: stock) {
                                    transactionRow(tx)
                                }
                            } else {
                                transactionRow(tx)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            .navigationTitle("Activity History")
            .navigationDestination(for: Stock.self) { stock in
                StockDetailView(stock: stock, viewModel: viewModel)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(
                        item: viewModel.exportTransactionsCSV(),
                        subject: Text("PaperMoneyApp Statement"),
                        message: Text("Exported paper trading transactions CSV")
                    ) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 15, weight: .semibold))
                    }
                }
            }
        }
    }

    // MARK: - Activity Filter Pills Bar
    private var activityFilterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(activityFilterOptions, id: \.self) { filter in
                    Button {
                        activityFilter = filter
                    } label: {
                        Text(filter)
                            .font(.system(.footnote, design: .rounded, weight: .semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                activityFilter == filter
                                    ? AppTheme.Colors.gain
                                    : AppTheme.Colors.cardSurface
                            )
                            .foregroundColor(activityFilter == filter ? Color(hex: "#080A0F") : AppTheme.Colors.subheadline)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(activityFilter == filter ? Color.clear : AppTheme.Colors.cardBorder, lineWidth: 1)
                            )
                            .cornerRadius(16)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
    }

    // MARK: - Trader Analytics Card
    private var analyticsCard: some View {
        let stats = viewModel.traderAnalytics
        let isProfit = stats.realizedPnL >= 0

        return HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("REALIZED P&L")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(AppTheme.Colors.muted)
                Text("\(isProfit ? "+" : "")$\(formatCurrency(abs(stats.realizedPnL)))")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundColor(isProfit ? AppTheme.Colors.gain : AppTheme.Colors.loss)
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()
                .frame(height: 28)
                .overlay(AppTheme.Colors.cardBorder)

            VStack(alignment: .center, spacing: 2) {
                Text("WIN RATE")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(AppTheme.Colors.muted)
                Text(stats.closedTradesCount > 0 ? "\(String(format: "%.1f", stats.winRate))%" : "—")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundColor(AppTheme.Colors.headline)
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 28)
                .overlay(AppTheme.Colors.cardBorder)

            VStack(alignment: .trailing, spacing: 2) {
                Text("EXECUTIONS")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(AppTheme.Colors.muted)
                Text("\(stats.totalTradesCount)")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundColor(AppTheme.Colors.headline)
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(AppTheme.Colors.cardSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.Colors.cardBorder, lineWidth: 1)
        )
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    private func alertRow(_ alert: PriceAlert) -> some View {
        HStack(spacing: 12) {
            Image(systemName: alert.isTriggered ? "bell.badge.fill" : "bell.fill")
                .font(.system(size: 18))
                .foregroundColor(alert.isTriggered ? Color(hex: "#FF9F0A") : Color(hex: "#0A84FF"))
                .frame(width: 36, height: 36)
                .background((alert.isTriggered ? Color(hex: "#FF9F0A") : Color(hex: "#0A84FF")).opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(alert.symbol)
                        .font(.system(.headline, design: .rounded, weight: .semibold))

                    Text(alert.isTriggered ? "TRIGGERED" : "ACTIVE")
                        .font(.system(size: 9, weight: .black))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background((alert.isTriggered ? Color(hex: "#FF9F0A").opacity(0.15) : AppTheme.Colors.gainBadge))
                        .foregroundColor(alert.isTriggered ? Color(hex: "#FF9F0A") : AppTheme.Colors.gain)
                        .cornerRadius(6)
                }

                Text("\(alert.condition.rawValue) $\(String(format: "%.2f", alert.targetPrice))")
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.subheadline)
                    .monospacedDigit()

                Text(formatDate(alert.createdAt))
                    .font(.caption2)
                    .foregroundColor(AppTheme.Colors.muted)
            }

            Spacer()

            Button {
                viewModel.removePriceAlert(id: alert.id)
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.loss.opacity(0.7))
                    .padding(8)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    private func transactionRow(_ tx: Transaction) -> some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: tx.type.iconName)
                .font(.system(size: 20))
                .foregroundColor(color(for: tx.type))
                .frame(width: 36, height: 36)
                .background(color(for: tx.type).opacity(0.12))
                .clipShape(Circle())

            // Details
            VStack(alignment: .leading, spacing: 3) {
                if let symbol = tx.symbol {
                    Text("\(tx.type.rawValue) \(symbol)")
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                    if let shares = tx.shares, let price = tx.pricePerShare {
                        Text("\(formatShares(shares)) shares @ $\(String(format: "%.2f", price))")
                            .font(.caption)
                            .foregroundColor(AppTheme.Colors.subheadline)
                            .monospacedDigit()
                    }
                } else {
                    Text(tx.type.rawValue)
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                    if let note = tx.note {
                        Text(note)
                            .font(.caption)
                            .foregroundColor(AppTheme.Colors.subheadline)
                    }
                }

                Text(formatDate(tx.timestamp))
                    .font(.caption2)
                    .foregroundColor(AppTheme.Colors.muted)
            }

            Spacer()

            // Amount
            VStack(alignment: .trailing, spacing: 2) {
                let isCredit = (tx.type == .deposit || tx.type == .sell)
                let prefix = isCredit ? "+" : "-"
                Text("\(prefix)$\(formatCurrency(tx.totalAmount))")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundColor(isCredit ? AppTheme.Colors.gain : AppTheme.Colors.headline)
                    .monospacedDigit()
            }
        }
        .padding(.vertical, 4)
    }

    private func orderRow(_ order: LimitOrder) -> some View {
        HStack(spacing: 12) {
            Image(systemName: orderIcon(for: order))
                .font(.system(size: 20))
                .foregroundColor(kindColor(for: order.kind))
                .frame(width: 36, height: 36)
                .background(kindColor(for: order.kind).opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("\(order.type.rawValue) \(order.symbol)")
                        .font(.system(.headline, design: .rounded, weight: .semibold))

                    Text(order.kind.rawValue.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(kindColor(for: order.kind).opacity(0.15))
                        .foregroundColor(kindColor(for: order.kind))
                        .cornerRadius(6)

                    Text(order.status.rawValue.uppercased())
                        .font(.system(size: 9, weight: .black))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(statusColor(for: order.status).opacity(0.15))
                        .foregroundColor(statusColor(for: order.status))
                        .cornerRadius(6)
                }

                Text("Target $\(String(format: "%.2f", order.targetPrice)) · \(formatShares(order.shares)) shares")
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.subheadline)
                    .monospacedDigit()

                Text(formatDate(order.createdAt))
                    .font(.caption2)
                    .foregroundColor(AppTheme.Colors.muted)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(formatCurrency(order.totalAmount))")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .monospacedDigit()

                if order.status == .pending {
                    Button {
                        viewModel.cancelLimitOrder(id: order.id)
                    } label: {
                        Text("Cancel")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(AppTheme.Colors.lossBadge)
                            .foregroundColor(AppTheme.Colors.loss)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func orderIcon(for order: LimitOrder) -> String {
        switch order.kind {
        case .limit:
            return order.type == .buy ? "arrow.down.forward.circle.fill" : "arrow.up.forward.circle.fill"
        case .stopLoss:
            return "shield.lefthalf.filled"
        case .takeProfit:
            return "target"
        }
    }

    private func kindColor(for kind: OrderKind) -> Color {
        switch kind {
        case .limit: return .blue
        case .stopLoss: return .red
        case .takeProfit: return .green
        }
    }

    private func statusColor(for status: OrderStatus) -> Color {
        switch status {
        case .pending: return .orange
        case .filled: return .green
        case .cancelled: return .gray
        }
    }

    private func color(for type: TransactionType) -> Color {
        switch type {
        case .deposit: return .green
        case .withdraw: return .orange
        case .buy: return .blue
        case .sell: return .purple
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
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
