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
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .monospacedDigit()

                HStack(spacing: 3) {
                    Image(systemName: isGain ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 9, weight: .bold))
                    Text("\(isGain ? "+" : "")$\(formatNumber(abs(pnl))) (\(String(format: "%.2f", returnPercent))%)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(isGain ? AppTheme.Colors.gainBadge : AppTheme.Colors.lossBadge)
                .foregroundColor(isGain ? AppTheme.Colors.gain : AppTheme.Colors.loss)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke((isGain ? AppTheme.Colors.gain : AppTheme.Colors.loss).opacity(0.2), lineWidth: 0.5)
                )
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
