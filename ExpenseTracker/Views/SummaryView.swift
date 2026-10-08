import SwiftUI
import Charts

struct SummaryView: View {
    @Environment(ExpenseStore.self) private var store

    @State private var selectedMonth: Date = .now

    private var calendar: Calendar { .current }

    private var monthExpenses: [Expense] {
        store.expenses.filter { calendar.isDate($0.date, equalTo: selectedMonth, toGranularity: .month) }
    }

    private var monthTotal: Double {
        monthExpenses.reduce(0) { $0 + $1.amount }
    }

    private var isCurrentMonth: Bool {
        calendar.isDate(selectedMonth, equalTo: .now, toGranularity: .month)
    }

    private var monthTitle: String {
        selectedMonth.formatted(.dateTime.month(.wide).year())
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

    private var summaryText: String {
        var lines = ["\(monthTitle) Expense Summary", "Total: \(monthTotal.formatted(.currency(code: currencyCode)))", ""]
        for item in categoryTotals {
            lines.append("\(item.category.displayName): \(item.total.formatted(.currency(code: currencyCode)))")
        }
        return lines.joined(separator: "\n")
    }

    private func changeMonth(by value: Int) {
        guard let newMonth = calendar.date(byAdding: .month, value: value, to: selectedMonth) else { return }
        selectedMonth = newMonth
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Button {
                            changeMonth(by: -1)
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                        .accessibilityLabel("Previous month")

                        Spacer()

                        Text(monthTitle)
                            .font(.subheadline.weight(.semibold))

                        Spacer()

                        Button {
                            changeMonth(by: 1)
                        } label: {
                            Image(systemName: "chevron.right")
                        }
                        .disabled(isCurrentMonth)
                        .accessibilityLabel("Next month")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(isCurrentMonth ? "This Month" : monthTitle)
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
                            "No Expenses in \(monthTitle)",
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
                            .foregroundStyle(item.category.color)
                            .cornerRadius(4)
                        }
                        .frame(height: 220)
                        .padding(.vertical, 8)
                        .accessibilityLabel("Spending by category for \(monthTitle)")
                        .accessibilityValue(categoryTotals.map { "\($0.category.displayName): \($0.total.formatted(.currency(code: currencyCode)))" }.joined(separator: ", "))

                        ForEach(categoryTotals) { item in
                            HStack {
                                Image(systemName: item.category.systemImage)
                                    .foregroundStyle(.white)
                                    .frame(width: 28, height: 28)
                                    .background(item.category.color, in: Circle())
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: summaryText) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Share summary as text")
                }
            }
        }
    }
}

#Preview {
    SummaryView()
        .environment(ExpenseStore())
}
