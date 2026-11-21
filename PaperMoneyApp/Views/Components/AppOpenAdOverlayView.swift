import SwiftUI

/// Full-screen Google AdMob App Open Ad overlay.
/// Presented exactly ONCE when the app opens to monetize cleanly without intrusive banners.
public struct AppOpenAdOverlayView: View {
    @ObservedObject var adService: AdService
    @State private var timeRemaining: Int = 3
    @State private var canSkip: Bool = false
    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    public init(adService: AdService = .shared) {
        self.adService = adService
    }

    public var body: some View {
        ZStack {
            // Dark Backdrop
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Top Header: Ad Badge & Skip Button
                HStack {
                    HStack(spacing: 6) {
                        Text("Ad")
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.yellow.opacity(0.9))
                            .foregroundColor(.black)
                            .cornerRadius(4)

                        Text("Google AdMob · App Open")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button {
                        adService.dismissLaunchAd()
                    } label: {
                        HStack(spacing: 4) {
                            Text(canSkip ? "Skip Ad" : "Skip in \(timeRemaining)s")
                                .font(.system(.caption, design: .rounded, weight: .bold))
                            Image(systemName: "xmark")
                                .font(.caption2)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.15))
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()

                // Sponsored Creative Card
                VStack(spacing: 16) {
                    // Sponsor Logo / Icon
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [Color.blue, Color.cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 76, height: 76)
                        Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                    .shadow(color: Color.blue.opacity(0.4), radius: 12, x: 0, y: 6)

                    VStack(spacing: 6) {
                        Text("Apex Market Intelligence")
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .foregroundColor(.white)

                        Text("Real-time algorithmic analytics & market signals for mobile traders.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    // Sponsored Rating Strip
                    HStack(spacing: 12) {
                        HStack(spacing: 3) {
                            ForEach(0..<5) { _ in
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                    .foregroundColor(.yellow)
                            }
                        }
                        Text("4.9 ★ (120K Reviews)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    // Install / Visit CTA
                    Button {
                        // Open sponsor link
                        adService.dismissLaunchAd()
                    } label: {
                        Text("Install Free")
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }
                .padding(24)
                .background(Color(UIColor.secondarySystemBackground).opacity(0.5))
                .cornerRadius(24)
                .padding(.horizontal, 20)

                Spacer()

                // Bottom Dismiss Action
                Button {
                    adService.dismissLaunchAd()
                } label: {
                    Text("Continue to Paper Money App")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 24)
            }
        }
        .onReceive(timer) { _ in
            if timeRemaining > 1 {
                timeRemaining -= 1
            } else {
                canSkip = true
            }
        }
    }
}
