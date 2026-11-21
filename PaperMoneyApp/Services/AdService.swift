import Foundation
import SwiftUI
import Combine

/// Manages the single Google AdMob App Open Ad overlay presented on app launch.
/// In accordance with user requirements:
/// - Appears ONCE when the app is launched.
/// - NO banners, NO sticky bottom ads, and NO interstitial interruptions during trading.
/// - Completely clean trading interface once dismissed.
public final class AdService: ObservableObject {
    public static let shared = AdService()

    /// Toggle to switch between Google AdMob Test Ad Unit and your Live Production Ad Unit
    public var isProductionMode: Bool = true

    /// Google AdMob App Open Test Ad Unit ID for iOS
    public let testAppOpenAdUnitID = "ca-app-pub-3940256099942544/5575463023"

    /// Live production AdMob App Open Ad Unit ID configured for App Store release
    public var productionAppOpenAdUnitID: String = "ca-app-pub-3083596925398734/9038523742"

    /// The active Ad Unit ID based on environment configuration
    public var appOpenAdUnitID: String {
        isProductionMode ? productionAppOpenAdUnitID : testAppOpenAdUnitID
    }

    @Published public var isShowingLaunchAd: Bool = false
    @Published public private(set) var hasShownLaunchAdThisSession: Bool = false

    private init() {}

    /// Triggered on initial app launch. Presents the single Google App Open ad overlay once.
    /// Incorporates a 6-second network failsafe timeout to guarantee users are never blocked offline.
    public func triggerLaunchAdIfNeeded() {
        guard !hasShownLaunchAdThisSession else { return }

        // First-launch grace period: allow the user to view their welcome grant first
        guard StorageService.shared.hasInitialized else {
            hasShownLaunchAdThisSession = true
            return
        }

        // Slight micro delay for smooth initial frame presentation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            guard let self = self, !self.hasShownLaunchAdThisSession else { return }
            self.isShowingLaunchAd = true
            self.hasShownLaunchAdThisSession = true

            // Automatic failsafe: Auto-dismiss if ad loading or dismiss hangs
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) { [weak self] in
                guard let self = self, self.isShowingLaunchAd else { return }
                self.dismissLaunchAd()
            }
        }
    }

    /// Dismisses the ad overlay and returns immediately to the trading interface
    public func dismissLaunchAd() {
        withAnimation(.easeInOut(duration: 0.25)) {
            self.isShowingLaunchAd = false
        }
    }
}
