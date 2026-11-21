import SwiftUI

public struct MainTabView: View {
    @StateObject private var viewModel = PortfolioViewModel()
    @StateObject private var adService = AdService.shared

    public init() {}

    public var body: some View {
        ZStack(alignment: .top) {
            TabView {
                PortfolioView(viewModel: viewModel)
                    .tabItem {
                        Label("Portfolio", systemImage: "chart.pie.fill")
                    }

                MarketView(viewModel: viewModel)
                    .tabItem {
                        Label("Market", systemImage: "chart.line.uptrend.xyaxis")
                    }

                HistoryView(viewModel: viewModel)
                    .tabItem {
                        Label("Activity", systemImage: "clock.arrow.circlepath")
                    }

                SettingsView(viewModel: viewModel)
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
            }
            .tint(.green)

            // Dynamic floating toast notification
            ToastBanner(message: viewModel.bannerMessage ?? "", isVisible: viewModel.showBanner)

            // Google AdMob App Open Overlay - appears ONCE on app launch
            if adService.isShowingLaunchAd {
                AppOpenAdOverlayView(adService: adService)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    .zIndex(100)
            }
        }
        .onAppear {
            adService.triggerLaunchAdIfNeeded()
        }
    }
}
