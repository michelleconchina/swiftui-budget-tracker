import SwiftUI

struct ExpenseRowView: View {
    let expense: Expense

    private var formattedAmount: String {
        expense.amount.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: expense.category.systemImage)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(.tint, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.title)
                    .font(.body)
                Text(expense.date, format: .dateTime.day().month().year())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(formattedAmount)
                .font(.body.monospacedDigit())
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        ExpenseRowView(expense: Expense(title: "Groceries", amount: 42.5, category: .food))
        ExpenseRowView(expense: Expense(title: "Bus pass", amount: 20, category: .transport))
    }
}
