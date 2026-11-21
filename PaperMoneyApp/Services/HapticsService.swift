import UIKit

/// Centralized iOS haptic feedback provider for trading and deposit tactile responses
public final class HapticsService {
    public static let shared = HapticsService()

    private init() {}

    private var isEnabled: Bool {
        if let val = UserDefaults.standard.object(forKey: "haptics_enabled") as? Bool {
            return val
        }
        return true
    }

    public func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    public func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    public func selection() {
        guard isEnabled else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}
