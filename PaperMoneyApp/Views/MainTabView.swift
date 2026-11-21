import SwiftUI

public struct MainTabView: View {
    @StateObject private var viewModel = PortfolioViewModel()
    @StateObject private var adService = AdService.shared
    @State private var selectedTab: Int = 0

    public init() {}

    public var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $selectedTab) {
                PortfolioView(viewModel: viewModel, selectedTab: $selectedTab)
                    .tabItem {
                        Label("Portfolio", systemImage: "chart.pie.fill")
                    }
                    .tag(0)

                MarketView(viewModel: viewModel, selectedTab: $selectedTab)
                    .tabItem {
                        Label("Market", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    .tag(1)

                HistoryView(viewModel: viewModel, selectedTab: $selectedTab)
                    .tabItem {
                        Label("Activity", systemImage: "clock.arrow.circlepath")
                    }
                    .tag(2)

                SettingsView(viewModel: viewModel, selectedTab: $selectedTab)
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .tag(3)
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
