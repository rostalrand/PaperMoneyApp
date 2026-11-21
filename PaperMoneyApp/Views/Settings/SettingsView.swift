import SwiftUI

public struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: PortfolioViewModel
    @ObservedObject var storageService: StorageService = .shared

    @State private var selectedResetAmount: Double = 100_000.0
    @State private var showResetConfirmAlert: Bool = false
    @State private var isSyncing: Bool = false
    @State private var selectedLegalSheet: LegalSheetType? = nil
    @AppStorage("haptics_enabled") private var hapticsEnabled: Bool = true

    private let presetResetAmounts: [Double] = [10_000, 25_000, 50_000, 100_000, 500_000, 1_000_000]

    public init(viewModel: PortfolioViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            Form {
                // iCloud Synchronization Status
                Section("Apple iCloud Persistence") {
                    HStack {
                        Label("Storage Engine", systemImage: "icloud.fill")
                            .foregroundColor(.blue)
                        Spacer()
                        Text(storageService.isICloudAvailable ? "iCloud Synced" : "Local Fallback")
                            .font(.system(.footnote, design: .rounded, weight: .bold))
                            .foregroundColor(storageService.isICloudAvailable ? .green : .secondary)
                    }

                    HStack {
                        Text("Architecture")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Zero-Login Ubiquitous KVS")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }

                    Button {
                        forceSync()
                    } label: {
                        HStack {
                            Text("Force Sync to iCloud")
                                .fontWeight(.semibold)
                            Spacer()
                            if isSyncing {
                                ProgressView()
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                            }
                        }
                    }
                } footer: {
                    Text("Your paper balance, positions, transactions, limit orders, and alerts automatically sync across all your Apple devices signed into iCloud.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                // Account Reset with Starting Capital Presets
                Section("Account Balance & Reset") {
                    HStack {
                        Text("Current Cash Balance")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("$\(formatCurrency(viewModel.cashBalance))")
                            .font(.system(.body, design: .rounded, weight: .bold))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Starting Capital for Fresh Reset:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(presetResetAmounts, id: \.self) { amount in
                                    Button {
                                        selectedResetAmount = amount
                                        HapticsService.shared.impact(style: .light)
                                    } label: {
                                        Text("$\(formatCompact(amount))")
                                            .font(.system(.footnote, design: .rounded, weight: .bold))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(selectedResetAmount == amount ? Color.green : Color(UIColor.tertiarySystemGroupedBackground))
                                            .foregroundColor(selectedResetAmount == amount ? .white : .primary)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)

                    Button(role: .destructive) {
                        showResetConfirmAlert = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Reset Portfolio to $\(formatCurrency(selectedResetAmount))")
                                .fontWeight(.bold)
                            Spacer()
                        }
                    }
                }

                // User Preferences
                Section("Preferences") {
                    Toggle("Tactile Haptic Feedback", isOn: $hapticsEnabled)
                }

                // Legal & App Store Compliance
                Section("Legal & Compliance") {
                    Button {
                        selectedLegalSheet = .disclaimer
                    } label: {
                        HStack {
                            Label("Regulatory Disclaimer", systemImage: "exclamationmark.shield")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }

                    Button {
                        selectedLegalSheet = .privacyPolicy
                    } label: {
                        HStack {
                            Label("Privacy Policy", systemImage: "hand.raised")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }

                    Button {
                        selectedLegalSheet = .termsOfService
                    } label: {
                        HStack {
                            Label("Terms of Service", systemImage: "doc.text")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                } footer: {
                    Text("Paper Money is strictly an educational simulator. Real money is never used or required.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                // Monetization & App Notice
                Section("About PaperMoneyApp") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0 (Build 1)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Monetization Policy")
                        Spacer()
                        Text("1 Launch Ad Overlay Only")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Target Platform")
                        Spacer()
                        Text("iOS Exclusive (SwiftUI)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } footer: {
                    Text("Designed with zero-friction principles: no account creation, no subscriptions, and zero trade interruptions.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Reset Account?", isPresented: $showResetConfirmAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Confirm Reset", role: .destructive) {
                    viewModel.resetAccount(startingDeposit: selectedResetAmount)
                    HapticsService.shared.notification(type: .success)
                    dismiss()
                }
            } message: {
                Text("This will wipe all active positions, pending orders, and history, starting you fresh with $\(formatCurrency(selectedResetAmount)) in paper funds.")
            }
            .sheet(item: $selectedLegalSheet) { type in
                LegalSheetView(type: type)
            }
        }
    }

    private func forceSync() {
        isSyncing = true
        HapticsService.shared.impact(style: .medium)
        NSUbiquitousKeyValueStore.default.synchronize()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isSyncing = false
            self.viewModel.showNotification(message: "☁️ iCloud sync synchronized successfully.")
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }

    private func formatCompact(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "%.0fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.0fK", value / 1_000)
        } else {
            return String(format: "%.0f", value)
        }
    }
}
