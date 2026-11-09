import SwiftUI

/// Expense entry form for a selected credit card.
struct AddExpenseView: View {

    let card: WatchCard
    @StateObject private var connector = PhoneConnector.shared

    @State private var amountText  = ""
    @State private var spentFor    = ""
    @State private var personIndex = 0
    @Environment(\.dismiss) private var dismiss

    private var canSave: Bool {
        Double(amountText) != nil && !amountText.isEmpty && !spentFor.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {

                // ── Card header ──────────────────────────────────
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(hex: card.color))
                        .frame(width: 8, height: 8)
                    Text(card.name)
                        .font(.headline)
                        .lineLimit(1)
                }

                Divider()

                // ── Amount ───────────────────────────────────────
                VStack(alignment: .leading, spacing: 2) {
                    Text("Amount (₹)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    TextField("0", text: $amountText)
                        .keyboardType(.decimalPad)
                        .font(.title3.monospacedDigit())
                        .padding(6)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(8)
                }

                // ── Spent For ────────────────────────────────────
                VStack(alignment: .leading, spacing: 2) {
                    Text("Spent For")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    TextField("e.g. Groceries", text: $spentFor)
                        .font(.body)
                        .padding(6)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(8)
                }

                // ── Spent By ─────────────────────────────────────
                if connector.people.count > 1 {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Spent By")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Picker("", selection: $personIndex) {
                            ForEach(connector.people.indices, id: \.self) { i in
                                Text(connector.people[i]).tag(i)
                            }
                        }
                        .labelsHidden()
                    }
                }

                // ── Save / status ─────────────────────────────────
                sendButton
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
        }
        .navigationTitle("New Expense")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: connector.sendState) { state in
            if case .success = state {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Save button / status display

    @ViewBuilder
    private var sendButton: some View {
        switch connector.sendState {

        case .idle:
            Button(action: save) {
                Label("Save", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled(!canSave)

        case .failure(let msg):
            VStack(spacing: 6) {
                Text(msg)
                    .font(.caption2)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                Button(action: save) {
                    Label("Retry", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(!canSave)
            }

        case .sending:
            HStack(spacing: 8) {
                ProgressView()
                Text("Saving…")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

        case .success:
            Label("Saved!", systemImage: "checkmark.seal.fill")
                .foregroundColor(.green)
                .font(.body.bold())
        }
    }

    // MARK: - Save action

    private func save() {
        guard let amount = Double(amountText) else { return }
        let spentBy = connector.people.isEmpty ? "Me" : connector.people[personIndex]
        connector.sendState = .idle
        connector.sendTransaction(
            cardId:   card.id,
            spentFor: spentFor.trimmingCharacters(in: .whitespaces),
            spentBy:  spentBy,
            amount:   amount
        )
    }
}
