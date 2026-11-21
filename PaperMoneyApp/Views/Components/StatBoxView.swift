import SwiftUI

public struct StatBoxView: View {
    public let title: String
    public let value: String
    public var subtitle: String? = nil
    public var isPositive: Bool? = nil

    public init(title: String, value: String, subtitle: String? = nil, isPositive: Bool? = nil) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.isPositive = isPositive
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(AppTheme.Colors.secondaryText)
                .textCase(.uppercase)
                .tracking(0.5)

            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundColor(.primary)
                .monospacedDigit()

            if let sub = subtitle {
                Text(sub)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(
                        isPositive == nil ? AppTheme.Colors.secondaryText : (isPositive! ? AppTheme.Colors.gain : AppTheme.Colors.loss)
                    )
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AppTheme.Colors.cardSurface)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppTheme.Colors.cardBorder, lineWidth: 1)
        )
    }
}
