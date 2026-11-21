import SwiftUI

public struct StockRowView: View {
    public let stock: Stock
    @AppStorage("stock_row_metric_mode") private var metricMode: Int = 0

    public init(stock: Stock) {
        self.stock = stock
    }

    public var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(stock.symbol)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                Text(stock.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(width: 110, alignment: .leading)

            // Sparkline Graph
            SparklineView(data: stock.sparkline, isPositive: stock.isPositive)
                .frame(height: 32)
                .padding(.horizontal, 4)

            Spacer()

            // Price & Change
            VStack(alignment: .trailing, spacing: 3) {
                Text("$\(String(format: "%.2f", stock.currentPrice))")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))

                Button {
                    metricMode = (metricMode + 1) % 3
                    HapticsService.shared.selection()
                } label: {
                    HStack(spacing: 3) {
                        if metricMode != 2 {
                            Image(systemName: stock.isPositive ? "arrow.up.right" : "arrow.down.right")
                                .font(.caption2)
                        }
                        Text(metricLabel)
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background((stock.isPositive ? Color.green : Color.red).opacity(0.15))
                    .foregroundColor(stock.isPositive ? .green : .red)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
    }

    private var metricLabel: String {
        switch metricMode {
        case 1:
            let prefix = stock.isPositive ? "+" : ""
            return "\(prefix)$\(String(format: "%.2f", stock.change))"
        case 2:
            return stock.marketCap
        default:
            let prefix = stock.isPositive ? "+" : ""
            return "\(prefix)\(String(format: "%.2f", stock.changePercent))%"
        }
    }
}
