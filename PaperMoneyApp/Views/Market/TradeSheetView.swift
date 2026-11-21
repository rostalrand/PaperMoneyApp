import SwiftUI

public enum TradeOrderType: String, CaseIterable, Identifiable {
    case market = "Market"
    case limit = "Limit"
    case stopLoss = "Stop Loss"
    case takeProfit = "Take Profit"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .market: return "bolt.fill"
        case .limit: return "arrow.left.arrow.right"
        case .stopLoss: return "shield.lefthalf.filled"
        case .takeProfit: return "target"
        }
    }
}

public struct TradeSheetView: View {
    @Environment(\.dismiss) private var dismiss
    public let stock: Stock
    @ObservedObject var viewModel: PortfolioViewModel

    @State private var tradeType: TransactionType = .buy
    @State private var selectedOrderType: TradeOrderType = .market
    @State private var targetPriceText: String = ""
    @State private var isDollarMode: Bool = false
    @State private var inputText: String = ""
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert: Bool = false

    public init(stock: Stock, viewModel: PortfolioViewModel, initialTradeType: TransactionType = .buy) {
        self.stock = stock
        self.viewModel = viewModel
        self._tradeType = State(initialValue: initialTradeType)
        self._targetPriceText = State(initialValue: String(format: "%.2f", stock.currentPrice))
    }

    private var effectivePrice: Double {
        if selectedOrderType != .market {
            let cleaned = targetPriceText.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            return Double(cleaned) ?? stock.currentPrice
        }
        return stock.currentPrice
    }

    private var ownedPosition: Position? {
        viewModel.getPosition(for: stock.symbol)
    }

    private var sharesOwned: Double {
        ownedPosition?.shares ?? 0.0
    }

    private var inputNumeric: Double {
        let cleaned = inputText.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(cleaned) ?? 0.0
    }

    private var calculatedShares: Double {
        if isDollarMode {
            guard effectivePrice > 0 else { return 0 }
            return inputNumeric / effectivePrice
        } else {
            return inputNumeric
        }
    }

    private var calculatedTotalCost: Double {
        if isDollarMode {
            return inputNumeric
        } else {
            return inputNumeric * effectivePrice
        }
    }

    private var remainingCash: Double {
        if tradeType == .buy {
            return max(0, viewModel.cashBalance - calculatedTotalCost)
        } else {
            return viewModel.cashBalance + calculatedTotalCost
        }
    }

    private var isValidOrder: Bool {
        guard calculatedShares > 0 && calculatedTotalCost > 0 else { return false }
        if tradeType == .buy {
            return viewModel.cashBalance >= calculatedTotalCost
        } else {
            return sharesOwned >= calculatedShares
        }
    }

    public var body: some View {
        NavigationStack {
            Form {
                // Buy / Sell Selector (Locked to Sell for Stop-Loss & Take-Profit)
                Section {
                    Picker("Trade Type", selection: $tradeType) {
                        Text("Buy \(stock.symbol)").tag(TransactionType.buy)
                        Text("Sell \(stock.symbol)").tag(TransactionType.sell)
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .disabled(selectedOrderType == .stopLoss || selectedOrderType == .takeProfit)
                }

                // Balance Context
                Section {
                    HStack {
                        Text(tradeType == .buy ? "Available Paper Cash" : "Shares Currently Owned")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        if tradeType == .buy {
                            Text("$\(formatCurrency(viewModel.cashBalance))")
                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                                .foregroundColor(.green)
                        } else {
                            Text("\(formatShares(sharesOwned)) shares")
                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                        }
                    }
                }

                // Order Type Selector
                Section("Order Type") {
                    Picker("Execution Style", selection: $selectedOrderType) {
                        ForEach(TradeOrderType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedOrderType) { newType in
                        if newType == .stopLoss || newType == .takeProfit {
                            tradeType = .sell
                            if newType == .stopLoss {
                                targetPriceText = String(format: "%.2f", stock.currentPrice * 0.95)
                            } else {
                                targetPriceText = String(format: "%.2f", stock.currentPrice * 1.10)
                            }
                        } else {
                            targetPriceText = String(format: "%.2f", stock.currentPrice)
                        }
                    }

                    // Price Target field for Limit, Stop Loss, or Take Profit
                    if selectedOrderType != .market {
                        HStack {
                            Text(targetPriceLabel)
                                .font(.subheadline)
                            Spacer()
                            Text("$")
                                .foregroundColor(.secondary)
                            TextField("0.00", text: $targetPriceText)
                                .keyboardType(.decimalPad)
                                .font(.system(.body, design: .rounded, weight: .bold))
                                .multilineTextAlignment(.trailing)
                                .frame(width: 90)
                        }

                        Text(orderGuidanceText)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                // Quantity / Amount Section
                Section("Quantity") {
                    Picker("Order By", selection: $isDollarMode) {
                        Text("Number of Shares").tag(false)
                        Text("Dollar Amount ($)").tag(true)
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Text(isDollarMode ? "$" : "Qty")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        TextField(isDollarMode ? "0.00" : "0", text: $inputText)
                            .keyboardType(.decimalPad)
                            .font(.system(.title2, design: .rounded, weight: .bold))

                        Button {
                            setMaxAmount()
                        } label: {
                            Text("MAX")
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.green.opacity(0.15))
                                .foregroundColor(.green)
                                .cornerRadius(8)
                        }
                    }

                    // Quick Percentage Position Sizing Chips (25%, 50%, 75%, MAX)
                    HStack(spacing: 8) {
                        ForEach([0.25, 0.50, 0.75, 1.0], id: \.self) { pct in
                            Button {
                                setPercentageAmount(pct)
                            } label: {
                                Text(pct == 1.0 ? "MAX" : "\(Int(pct * 100))%")
                                    .font(.system(.caption, design: .rounded, weight: .bold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(Color(UIColor.tertiarySystemGroupedBackground))
                                    .foregroundColor(.primary)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    HStack {
                        Text("Current Market Price")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("$\(String(format: "%.2f", stock.currentPrice))")
                            .font(.system(.footnote, design: .rounded, weight: .semibold))
                    }
                }

                // Execution Summary
                Section("Execution Preview") {
                    HStack {
                        Text("Estimated Shares")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatShares(calculatedShares))
                            .fontWeight(.medium)
                    }

                    HStack {
                        Text(tradeType == .buy ? "Estimated Cost" : "Estimated Proceeds")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("$\(formatCurrency(calculatedTotalCost))")
                            .fontWeight(.bold)
                            .foregroundColor(tradeType == .buy ? .primary : .green)
                    }

                    HStack {
                        Text("Cash After Trade")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("$\(formatCurrency(remainingCash))")
                            .foregroundColor(.secondary)
                    }
                }

                // Execute Button
                Section {
                    Button {
                        executeTrade()
                    } label: {
                        HStack {
                            Spacer()
                            Text(actionButtonTitle)
                                .font(.headline)
                                .fontWeight(.bold)
                            Spacer()
                        }
                        .padding(.vertical, 6)
                    }
                    .disabled(!isValidOrder)
                    .tint(buttonTintColor)
                } footer: {
                    Text(orderFooterText)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("\(selectedOrderType.rawValue) \(stock.symbol)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Order Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Unable to execute trade.")
            }
        }
    }

    private var targetPriceLabel: String {
        switch selectedOrderType {
        case .market: return ""
        case .limit: return "Target Limit Price"
        case .stopLoss: return "Stop Trigger Price"
        case .takeProfit: return "Profit Target Price"
        }
    }

    private var orderGuidanceText: String {
        switch selectedOrderType {
        case .market:
            return ""
        case .limit:
            if tradeType == .buy {
                return "Order will fill only when the price drops to or below $\(String(format: "%.2f", effectivePrice))."
            } else {
                return "Order will fill only when the price rises to or above $\(String(format: "%.2f", effectivePrice))."
            }
        case .stopLoss:
            return "Automatically sells your shares if market price drops to or below $\(String(format: "%.2f", effectivePrice)) to prevent severe drawdown."
        case .takeProfit:
            return "Automatically sells your shares when price surges to or above $\(String(format: "%.2f", effectivePrice)) to lock in profit."
        }
    }

    private var actionButtonTitle: String {
        switch selectedOrderType {
        case .market:
            return tradeType == .buy ? "Execute Paper Buy" : "Execute Paper Sell"
        case .limit:
            return "Place Limit \(tradeType.rawValue)"
        case .stopLoss:
            return "Set Stop-Loss @ $\(String(format: "%.2f", effectivePrice))"
        case .takeProfit:
            return "Set Take-Profit @ $\(String(format: "%.2f", effectivePrice))"
        }
    }

    private var buttonTintColor: Color {
        switch selectedOrderType {
        case .market, .limit:
            return tradeType == .buy ? Color.green : Color.red
        case .stopLoss:
            return Color.red
        case .takeProfit:
            return Color.green
        }
    }

    private var orderFooterText: String {
        switch selectedOrderType {
        case .market:
            return "This is an instant simulated paper trade with zero commission fees."
        case .limit:
            return "Order will monitor live price ticks and execute automatically when your target price is reached."
        case .stopLoss:
            return "Monitors live price ticks and automatically executes a market sell on any downside breach."
        case .takeProfit:
            return "Monitors live price ticks and automatically locks in gains when your upside target is reached."
        }
    }

    private func setPercentageAmount(_ fraction: Double) {
        if tradeType == .buy {
            let totalAvailable = viewModel.cashBalance * fraction
            if isDollarMode {
                inputText = String(format: "%.2f", totalAvailable)
            } else {
                guard effectivePrice > 0 else { return }
                let shares = floor((totalAvailable / effectivePrice) * 1000) / 1000
                inputText = String(format: "%.3f", shares)
            }
        } else {
            let sharesTarget = sharesOwned * fraction
            if isDollarMode {
                inputText = String(format: "%.2f", sharesTarget * effectivePrice)
            } else {
                inputText = formatShares(sharesTarget)
            }
        }
        HapticsService.shared.impact(style: .light)
    }

    private func setMaxAmount() {
        if tradeType == .buy {
            if isDollarMode {
                inputText = String(format: "%.2f", viewModel.cashBalance)
            } else {
                guard effectivePrice > 0 else { return }
                let maxShares = floor((viewModel.cashBalance / effectivePrice) * 1000) / 1000
                inputText = String(format: "%.3f", maxShares)
            }
        } else {
            if isDollarMode {
                let totalValue = sharesOwned * effectivePrice
                inputText = String(format: "%.2f", totalValue)
            } else {
                inputText = formatShares(sharesOwned)
            }
        }
    }

    private func executeTrade() {
        let shares = calculatedShares
        guard shares > 0 else { return }

        switch selectedOrderType {
        case .market:
            if tradeType == .buy {
                let result = viewModel.buyStock(symbol: stock.symbol, shares: shares)
                handleResult(result)
            } else {
                let result = viewModel.sellStock(symbol: stock.symbol, shares: shares)
                handleResult(result)
            }
        case .limit:
            let result = viewModel.placeOrder(
                symbol: stock.symbol,
                type: tradeType,
                kind: .limit,
                shares: shares,
                targetPrice: effectivePrice
            )
            handleResult(result)
        case .stopLoss:
            let result = viewModel.placeOrder(
                symbol: stock.symbol,
                type: .sell,
                kind: .stopLoss,
                shares: shares,
                targetPrice: effectivePrice
            )
            handleResult(result)
        case .takeProfit:
            let result = viewModel.placeOrder(
                symbol: stock.symbol,
                type: .sell,
                kind: .takeProfit,
                shares: shares,
                targetPrice: effectivePrice
            )
            handleResult(result)
        }
    }

    private func handleResult(_ result: Result<Void, TradeError>) {
        switch result {
        case .success:
            dismiss()
        case .failure(let error):
            errorMessage = error.localizedDescription
            showErrorAlert = true
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
