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
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundColor(.primary)
            if let sub = subtitle {
                Text(sub)
                    .font(.caption2)
                    .foregroundColor(
                        isPositive == nil ? .secondary : (isPositive! ? .green : .red)
                    )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}
