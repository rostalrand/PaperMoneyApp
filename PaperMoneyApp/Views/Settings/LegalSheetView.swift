import SwiftUI

public enum LegalSheetType: String, Identifiable {
    case disclaimer = "Regulatory Disclaimer"
    case privacyPolicy = "Privacy Policy"
    case termsOfService = "Terms of Service"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .disclaimer:
            return "Educational Simulator Disclaimer"
        case .privacyPolicy:
            return "App Privacy Policy"
        case .termsOfService:
            return "Terms of Service"
        }
    }

    public var icon: String {
        switch self {
        case .disclaimer:
            return "exclamationmark.shield.fill"
        case .privacyPolicy:
            return "hand.raised.fill"
        case .termsOfService:
            return "doc.text.fill"
        }
    }
}

public struct LegalSheetView: View {
    @Environment(\.dismiss) private var dismiss
    public let type: LegalSheetType

    public init(type: LegalSheetType) {
        self.type = type
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Header Banner
                    HStack(spacing: 12) {
                        Image(systemName: type.icon)
                            .font(.system(size: 28))
                            .foregroundColor(.green)
                            .frame(width: 48, height: 48)
                            .background(Color.green.opacity(0.12))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(type.title)
                                .font(.system(.title3, design: .rounded, weight: .bold))
                            Text("Effective: November 2026 · Version 1.0.0")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.bottom, 6)

                    Divider()

                    // Document Body
                    contentBody
                        .font(.subheadline)
                        .lineSpacing(4)
                        .foregroundColor(.primary.opacity(0.9))
                }
                .padding(20)
            }
            .navigationTitle(type.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }

    @ViewBuilder
    private var contentBody: some View {
        switch type {
        case .disclaimer:
            VStack(alignment: .leading, spacing: 14) {
                Text("1. Virtual Currency & Paper Trading Only")
                    .font(.headline)
                Text("Paper Money is strictly an educational stock market simulation application. All cash balances, portfolio equity values, deposits, buys, sells, limit orders, and performance analytics are 100% simulated paper money with zero monetary value.")

                Text("2. Not a Brokerage or Investment Advisor")
                    .font(.headline)
                Text("Paper Money is NOT a registered broker-dealer, investment adviser, or member of FINRA or SIPC. The application does NOT execute real securities transactions, route orders to financial exchanges, or hold customer funds.")

                Text("3. Market Data & Pricing")
                    .font(.headline)
                Text("Market quotes, charts, and financial indicators provided within the application are sourced for educational and illustrative purposes. Past performance in this simulator does not guarantee or predict future real-world trading results.")

                Text("4. Educational Purpose")
                    .font(.headline)
                Text("This app is engineered to help traders, students, and investors practice market mechanics, test order types (Market, Limit, Stop-Loss, Take-Profit), and analyze risk management without risking real capital.")
            }

        case .privacyPolicy:
            VStack(alignment: .leading, spacing: 14) {
                Text("1. Zero Personal Data Collection")
                    .font(.headline)
                Text("Paper Money is built upon strict zero-friction, privacy-first principles. We do NOT require you to create an account, register with an email address, or provide any personal identification.")

                Text("2. Apple iCloud Private Persistence")
                    .font(.headline)
                Text("Your paper trading positions, cash balances, transaction logs, and price alerts are saved exclusively on your local device and synchronized through your personal Apple iCloud account via Apple's native NSUbiquitousKeyValueStore. We operate no external databases and have no access to your portfolio data.")

                Text("3. Single Launch AdMob Sponsorship")
                    .font(.headline)
                Text("To support development, Paper Money displays a single Google AdMob App Open sponsorship overlay when the app is launched. Once dismissed, zero banner ads, sticky ads, or trading interruptions occur. AdMob may utilize standard privacy-compliant identifiers in adherence with Apple's App Tracking Transparency guidelines.")

                Text("4. Data Deletion & Account Reset")
                    .font(.headline)
                Text("You maintain complete control over your data. You can wipe all positions, active orders, and historical transactions at any time using the 'Reset Account' feature in Settings.")
            }

        case .termsOfService:
            VStack(alignment: .leading, spacing: 14) {
                Text("1. Acceptance of Terms")
                    .font(.headline)
                Text("By downloading or using Paper Money, you agree to these Terms of Service. If you do not agree, do not use the application.")

                Text("2. Permitted Use")
                    .font(.headline)
                Text("You are granted a limited, revocable, non-exclusive license to use Paper Money for personal, non-commercial educational paper trading simulation purposes on iOS-compatible devices.")

                Text("3. Disclaimer of Warranties")
                    .font(.headline)
                Text("The software is provided 'AS IS' without warranty of any kind, express or implied. The developers shall not be liable for any claims, damages, or financial losses arising from investment decisions made in real-world trading markets.")

                Text("4. Modifications")
                    .font(.headline)
                Text("We reserve the right to modify or update features, simulation algorithms, and these terms at any time.")
            }
        }
    }
}
