import SwiftUI
import Charts

struct SummaryView: View {
    @Environment(ExpenseStore.self) private var store

    private var monthExpenses: [Expense] {
        let calendar = Calendar.current
        return store.expenses.filter { calendar.isDate($0.date, equalTo: .now, toGranularity: .month) }
    }

    private var monthTotal: Double {
        monthExpenses.reduce(0) { $0 + $1.amount }
    }

    private struct CategoryTotal: Identifiable {
        let category: ExpenseCategory
        let total: Double
        var id: ExpenseCategory { category }
    }

    private var categoryTotals: [CategoryTotal] {
        let grouped = Dictionary(grouping: monthExpenses, by: \.category)
        return grouped
            .map { CategoryTotal(category: $0.key, total: $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.total > $1.total }
    }

    private var currencyCode: String { AppCurrency.code }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("This Month")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(monthTotal, format: .currency(code: currencyCode))
                            .font(.largeTitle.bold())
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                }

                if categoryTotals.isEmpty {
                    Section {
                        ContentUnavailableView(
                            "No Expenses This Month",
                            systemImage: "chart.pie",
                            description: Text("Add an expense to see your breakdown.")
                        )
                    }
                } else {
                    Section("By Category") {
                        Chart(categoryTotals) { item in
                            SectorMark(
                                angle: .value("Amount", item.total),
                                innerRadius: .ratio(0.6),
                                angularInset: 1.5
                            )
                            .foregroundStyle(by: .value("Category", item.category.displayName))
                            .cornerRadius(4)
                        }
                        .frame(height: 220)
                        .padding(.vertical, 8)

                        ForEach(categoryTotals) { item in
                            HStack {
                                Image(systemName: item.category.systemImage)
                                    .foregroundStyle(.white)
                                    .frame(width: 28, height: 28)
                                    .background(.tint, in: Circle())
                                Text(item.category.displayName)
                                Spacer()
                                Text(item.total, format: .currency(code: currencyCode))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Summary")
        }
    }
}

#Preview {
    SummaryView()
        .environment(ExpenseStore())
}
