import SwiftUI

struct ExpenseRowView: View {
    let expense: Expense

    private var formattedAmount: String {
        expense.amount.formatted(.currency(code: AppCurrency.code))
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: expense.category.systemImage)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(.tint, in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.title)
                    .font(.body)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(expense.date, format: .dateTime.day().month().year())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(formattedAmount)
                .font(.body.monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .layoutPriority(1)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(expense.category.displayName), \(expense.title), \(expense.date.formatted(date: .abbreviated, time: .omitted)), \(formattedAmount)")
    }
}

#Preview {
    List {
        ExpenseRowView(expense: Expense(title: "Groceries", amount: 42.5, category: .food))
        ExpenseRowView(expense: Expense(title: "Bus pass", amount: 20, category: .transport))
    }
}
