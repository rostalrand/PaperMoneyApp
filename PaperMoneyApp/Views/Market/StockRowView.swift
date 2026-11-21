import SwiftUI

public struct StockRowView: View {
    public let stock: Stock

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

                HStack(spacing: 3) {
                    Image(systemName: stock.isPositive ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption2)
                    Text("\(stock.isPositive ? "+" : "")\(String(format: "%.2f", stock.changePercent))%")
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background((stock.isPositive ? Color.green : Color.red).opacity(0.15))
                .foregroundColor(stock.isPositive ? .green : .red)
                .cornerRadius(6)
            }
        }
        .padding(.vertical, 8)
    }
}
