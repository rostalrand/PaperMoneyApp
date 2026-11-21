import SwiftUI

public struct PositionRowView: View {
    public let position: Position
    public let stock: Stock?

    public init(position: Position, stock: Stock?) {
        self.position = position
        self.stock = stock
    }

    private var currentPrice: Double {
        stock?.currentPrice ?? position.averagePrice
    }

    private var currentValue: Double {
        position.currentValue(at: currentPrice)
    }

    private var pnl: Double {
        position.unrealizedPnl(at: currentPrice)
    }

    private var returnPercent: Double {
        position.returnPercent(at: currentPrice)
    }

    private var isGain: Bool {
        pnl >= 0
    }

    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(position.symbol)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                Text("\(formatShares(position.shares)) shares · Avg $\(formatNumber(position.averagePrice))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("$\(formatNumber(currentValue))")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))

                HStack(spacing: 4) {
                    Image(systemName: isGain ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption2)
                    Text("\(isGain ? "+" : "")$\(formatNumber(abs(pnl))) (\(String(format: "%.2f", returnPercent))%)")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background((isGain ? Color.green : Color.red).opacity(0.15))
                .foregroundColor(isGain ? .green : .red)
                .cornerRadius(6)
            }
        }
        .padding(.vertical, 6)
    }

    private func formatNumber(_ val: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: val)) ?? String(format: "%.2f", val)
    }

    private func formatShares(_ shares: Double) -> String {
        if shares.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", shares)
        } else {
            return String(format: "%.3f", shares)
        }
    }
}
