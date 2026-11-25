import SwiftUI

struct ExpenseRowView: View {
    let expense: Expense
    var currencyCode: String = AppCurrency.code
    /// Shown under the amount when the log isn't in pesos.
    var pesoAmount: Double? = nil

    private var formattedPeso: String? {
        pesoAmount.map { "≈ " + $0.formatted(.currency(code: AppCurrency.code).precision(.fractionLength(0))) }
    }

    private var formattedAmount: String {
        expense.amount.formatted(.currency(code: currencyCode))
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: expense.category.systemImage)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(expense.category.color, in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.title)
                    .font(.body)
                    .lineLimit(1)
                    .truncationMode(.tail)
                if let note = expense.note {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(expense.date, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day().year())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(formattedAmount)
                    .font(.body.monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if let formattedPeso {
                    Text(formattedPeso)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .layoutPriority(1)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(expense.category.displayName), \(expense.title), \(expense.date.formatted(date: .abbreviated, time: .omitted)), \(formattedAmount)\(formattedPeso.map { ", about \($0.dropFirst(2)) pesos" } ?? "")")
    }
}

#Preview {
    List {
        ExpenseRowView(expense: Expense(title: "Groceries", amount: 42.5, category: .food))
        ExpenseRowView(expense: Expense(title: "Bus pass", amount: 20, category: .commute))
    }
}
