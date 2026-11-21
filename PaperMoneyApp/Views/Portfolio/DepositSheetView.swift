import SwiftUI

public struct DepositSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: PortfolioViewModel

    @State private var inputAmountText: String = ""
    @State private var depositNote: String = ""

    private let presetAmounts: [Double] = [1_000, 5_000, 10_000, 50_000, 100_000, 1_000_000]

    public init(viewModel: PortfolioViewModel) {
        self.viewModel = viewModel
    }

    private var parsedAmount: Double {
        let cleaned = inputAmountText.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(cleaned) ?? 0.0
    }

    public var body: some View {
        NavigationStack {
            Form {
                // Current Balance Section
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Current Paper Cash Available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("$\(formatCurrency(viewModel.cashBalance))")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundColor(.green)
                    }
                    .padding(.vertical, 4)
                }

                // Custom Deposit Input
                Section("Deposit Custom Paper Cash") {
                    HStack {
                        Text("$")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        TextField("Enter any amount (e.g. 25,000)", text: $inputAmountText)
                            .keyboardType(.decimalPad)
                            .font(.system(.title3, design: .rounded, weight: .semibold))
                    }

                    TextField("Optional Note (e.g. Paycheck, Bonus)", text: $depositNote)
                        .font(.subheadline)
                }

                // Quick Presets
                Section("Quick Preset Amounts") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(presetAmounts, id: \.self) { amount in
                            Button {
                                inputAmountText = String(format: "%.0f", amount)
                            } label: {
                                Text("+$\(formatCompact(amount))")
                                    .font(.system(.footnote, design: .rounded, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color(UIColor.secondarySystemGroupedBackground))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(parsedAmount == amount ? Color.green : Color.clear, lineWidth: 1.5)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Submit Button
                Section {
                    Button {
                        if parsedAmount > 0 {
                            let note = depositNote.isEmpty ? "Paper Cash Deposit" : depositNote
                            viewModel.depositCash(amount: parsedAmount, note: note)
                            dismiss()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                            Text("Deposit Paper Cash")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .disabled(parsedAmount <= 0)
                } footer: {
                    Text("100% simulated paper money. Deposits immediately reflect in your trading purchasing power and sync across your Apple devices via iCloud.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Deposit Paper Money")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .font(.body.weight(.semibold))
                    .foregroundColor(.green)
                }
            }
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
            return "\(Int(value / 1_000_000))M"
        } else if value >= 1_000 {
            return "\(Int(value / 1_000))K"
        } else {
            return "\(Int(value))"
        }
    }
}
