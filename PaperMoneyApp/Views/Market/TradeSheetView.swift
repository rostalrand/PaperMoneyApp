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
    @State private var isDollarMode: Bool = true
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
            let rawShares = inputNumeric / effectivePrice
            return (rawShares * 10000).rounded() / 10000
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
            return viewModel.cashBalance >= (calculatedTotalCost - 0.009)
        } else {
            return sharesOwned >= (calculatedShares - 0.0005)
        }
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Top Header: Navigation & Purchasing Power
                topNavigationBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Order Type Selector
                        orderTypePillSelector

                        // Target Price Field if Limit / Stop / Take Profit
                        if selectedOrderType != .market {
                            targetPriceAdjuster
                        }

                        // Prominent Amount Input Display
                        amountInputHeroDisplay

                        // Quick Position Sizing Chips
                        quickSizingChipsRow

                        // Order Preview Context Card
                        orderPreviewContextCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 16)
                }

                // Custom Financial Numeric Keypad (Robinhood Style)
                financialKeypad

                // Bottom Full-Width Action Button
                bottomExecutionButton
            }
            .background(AppTheme.Colors.canvas.ignoresSafeArea())
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .alert("Order Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Unable to execute trade.")
            }
        }
    }

    // MARK: - Top Navigation Bar
    private var topNavigationBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(AppTheme.Colors.elevatedSurface)
                    .clipShape(Circle())
            }

            Spacer()

            // Buy / Sell Mode Toggle
            HStack(spacing: 4) {
                Button {
                    tradeType = .buy
                    HapticsService.shared.selection()
                } label: {
                    Text("Buy")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(tradeType == .buy ? AppTheme.Colors.gain : Color.clear)
                        .foregroundColor(tradeType == .buy ? .black : .white)
                        .cornerRadius(20)
                }
                .disabled(selectedOrderType == .stopLoss || selectedOrderType == .takeProfit)

                Button {
                    tradeType = .sell
                    HapticsService.shared.selection()
                } label: {
                    Text("Sell")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(tradeType == .sell ? AppTheme.Colors.loss : Color.clear)
                        .foregroundColor(tradeType == .sell ? .white : .white)
                        .cornerRadius(20)
                }
            }
            .padding(3)
            .background(AppTheme.Colors.elevatedSurface)
            .cornerRadius(24)

            Spacer()

            // Dollar vs Shares Toggle
            Button {
                isDollarMode.toggle()
                inputText = ""
                HapticsService.shared.selection()
            } label: {
                Text(isDollarMode ? "in Dollars" : "in Shares")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.Colors.gain)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.Colors.gainBadge)
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Order Type Pill Selector
    private var orderTypePillSelector: some View {
        HStack(spacing: 6) {
            ForEach(TradeOrderType.allCases) { type in
                Button {
                    selectedOrderType = type
                    if type == .stopLoss || type == .takeProfit {
                        tradeType = .sell
                        if type == .stopLoss {
                            targetPriceText = String(format: "%.2f", stock.currentPrice * 0.95)
                        } else {
                            targetPriceText = String(format: "%.2f", stock.currentPrice * 1.10)
                        }
                    } else {
                        targetPriceText = String(format: "%.2f", stock.currentPrice)
                    }
                    HapticsService.shared.selection()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: type.iconName)
                            .font(.system(size: 10, weight: .bold))
                        Text(type.rawValue)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(selectedOrderType == type ? AppTheme.Colors.elevatedSurface : Color.clear)
                    .foregroundColor(selectedOrderType == type ? .white : AppTheme.Colors.secondaryText)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(selectedOrderType == type ? AppTheme.Colors.cardBorder : Color.clear, lineWidth: 1)
                    )
                }
            }
        }
    }

    // MARK: - Target Price Adjuster
    private var targetPriceAdjuster: some View {
        HStack {
            Text(targetPriceLabel)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(AppTheme.Colors.secondaryText)
            Spacer()
            Text("$")
                .foregroundColor(AppTheme.Colors.secondaryText)
            TextField("0.00", text: $targetPriceText)
                .keyboardType(.decimalPad)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(AppTheme.Colors.elevatedSurface)
        .cornerRadius(12)
    }

    // MARK: - Amount Input Hero Display
    private var amountInputHeroDisplay: some View {
        VStack(spacing: 6) {
            // Purchasing power pill
            HStack(spacing: 4) {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 10))
                if tradeType == .buy {
                    Text("$\(formatCurrency(viewModel.cashBalance)) Buying Power")
                } else {
                    Text("\(formatShares(sharesOwned)) Shares Available")
                }
            }
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundColor(AppTheme.Colors.secondaryText)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(AppTheme.Colors.elevatedSurface)
            .cornerRadius(14)

            // Massive Numeric Display
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                if isDollarMode {
                    Text("$")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(inputText.isEmpty ? AppTheme.Colors.tertiaryText : .white)
                }
                Text(inputText.isEmpty ? "0" : inputText)
                    .font(.system(size: 46, weight: .heavy, design: .rounded))
                    .foregroundColor(inputText.isEmpty ? AppTheme.Colors.tertiaryText : .white)
                    .monospacedDigit()
                if !isDollarMode {
                    Text("Shares")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(inputText.isEmpty ? AppTheme.Colors.tertiaryText : .white)
                        .padding(.leading, 4)
                }
            }
            .padding(.vertical, 8)

            // Approximation Sub-label
            if isDollarMode {
                Text("≈ \(formatShares(calculatedShares)) \(stock.symbol) Shares @ $\(String(format: "%.2f", effectivePrice))")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.Colors.secondaryText)
                    .monospacedDigit()
            } else {
                Text("≈ $\(formatCurrency(calculatedTotalCost)) Total Value @ $\(String(format: "%.2f", effectivePrice))")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.Colors.secondaryText)
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    // MARK: - Position Sizing Chips
    private var quickSizingChipsRow: some View {
        HStack(spacing: 8) {
            ForEach([0.25, 0.50, 0.75, 1.0], id: \.self) { pct in
                Button {
                    if pct == 1.0 {
                        setMaxAmount()
                    } else {
                        setPercentageAmount(pct)
                    }
                } label: {
                    Text(pct == 1.0 ? "MAX" : "\(Int(pct * 100))%")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(AppTheme.Colors.elevatedSurface)
                        .foregroundColor(pct == 1.0 ? AppTheme.Colors.gain : .white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(pct == 1.0 ? AppTheme.Colors.gain.opacity(0.3) : AppTheme.Colors.cardBorder, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Order Preview Card
    private var orderPreviewContextCard: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Execution Price")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.Colors.secondaryText)
                Spacer()
                Text("$\(String(format: "%.2f", effectivePrice))")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .monospacedDigit()
            }

            HStack {
                Text("Estimated Total")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.Colors.secondaryText)
                Spacer()
                Text("$\(formatCurrency(calculatedTotalCost))")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(tradeType == .buy ? .white : AppTheme.Colors.gain)
                    .monospacedDigit()
            }

            HStack {
                Text("Trading Commission")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.Colors.secondaryText)
                Spacer()
                Text("$0.00 Free")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.Colors.gain)
            }
        }
        .padding(14)
        .background(AppTheme.Colors.cardSurface)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppTheme.Colors.cardBorder, lineWidth: 1)
        )
    }

    // MARK: - Custom Financial Keypad
    private var financialKeypad: some View {
        let keys = [
            ["1", "2", "3"],
            ["4", "5", "6"],
            ["7", "8", "9"],
            [".", "0", "⌫"]
        ]

        return VStack(spacing: 8) {
            ForEach(keys, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { key in
                        Button {
                            handleKeypadPress(key)
                        } label: {
                            Text(key)
                                .font(AppTheme.Fonts.keypadNumber)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(AppTheme.Colors.elevatedSurface.opacity(0.8))
                                .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(key == "⌫" ? "Backspace" : (key == "." ? "Decimal point" : "Digit \(key)"))
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    // MARK: - Bottom Execution Button
    private var bottomExecutionButton: some View {
        VStack(spacing: 6) {
            Button {
                executeTrade()
            } label: {
                HStack(spacing: 8) {
                    Text(actionButtonTitle)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(tradeType == .buy ? .black : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(isValidOrder ? (tradeType == .buy ? AppTheme.Colors.gain : AppTheme.Colors.loss) : AppTheme.Colors.elevatedSurface)
                .cornerRadius(26)
            }
            .disabled(!isValidOrder)

            Text("Simulated Paper Order · Zero Risk")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(AppTheme.Colors.tertiaryText)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .padding(.top, 6)
    }

    private var targetPriceLabel: String {
        switch selectedOrderType {
        case .market: return ""
        case .limit: return "Target Limit Price"
        case .stopLoss: return "Stop Trigger Price"
        case .takeProfit: return "Profit Target Price"
        }
    }

    private var actionButtonTitle: String {
        guard isValidOrder else { return "Enter Amount" }
        switch selectedOrderType {
        case .market:
            return tradeType == .buy ? "Submit Buy Order" : "Submit Sell Order"
        case .limit:
            return "Place Limit \(tradeType.rawValue)"
        case .stopLoss:
            return "Set Stop-Loss @ $\(String(format: "%.2f", effectivePrice))"
        case .takeProfit:
            return "Set Take-Profit @ $\(String(format: "%.2f", effectivePrice))"
        }
    }

    private func handleKeypadPress(_ key: String) {
        HapticsService.shared.impact(style: .light)
        if key == "⌫" {
            if !inputText.isEmpty {
                inputText.removeLast()
            }
        } else if key == "." {
            if !inputText.contains(".") {
                inputText += (inputText.isEmpty ? "0." : ".")
            }
        } else {
            if inputText == "0" {
                inputText = key
            } else {
                if inputText.contains(".") {
                    let parts = inputText.split(separator: ".")
                    if parts.count > 1 && parts[1].count >= 4 {
                        return
                    }
                } else if inputText.count >= 8 {
                    return
                }
                inputText += key
            }
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
                inputText = formatShares(shares)
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
                inputText = formatShares(maxShares)
            }
        } else {
            if isDollarMode {
                let totalValue = sharesOwned * effectivePrice
                inputText = String(format: "%.2f", totalValue)
            } else {
                inputText = formatShares(sharesOwned)
            }
        }
        HapticsService.shared.impact(style: .light)
    }

    private func executeTrade() {
        var shares = calculatedShares
        guard shares > 0 else { return }

        if tradeType == .sell && abs(sharesOwned - shares) < 0.0005 {
            shares = sharesOwned
        }

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
