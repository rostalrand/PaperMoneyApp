import SwiftUI

public struct ToastBanner: View {
    public let message: String
    public let isVisible: Bool

    public init(message: String, isVisible: Bool) {
        self.message = message
        self.isVisible = isVisible
    }

    public var body: some View {
        if isVisible {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppTheme.Colors.gain)
                    .font(.subheadline)
                Text(message)
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.Colors.headline)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(AppTheme.Colors.cardSurface)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(AppTheme.Colors.cardBorder, lineWidth: 1)
            )
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.4), radius: 10, x: 0, y: 5)
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isVisible)
            .padding(.top, 8)
        }
    }
}
