import SwiftUI
import SwiftData

struct ExpenseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]

    @State private var quickAddViewModel = ExpenseFormViewModel()
    @State private var quickAddError: String?
    @State private var expenseToEdit: Expense?

    private var listViewModel: ExpenseListViewModel {
        ExpenseListViewModel(modelContext: modelContext)
    }

    private var todayTotal: Double {
        listViewModel.total(of: expenses.filter { Calendar.current.isDateInToday($0.date) })
    }

    private var dayGroups: [(day: Date, expenses: [Expense])] {
        let groups = Dictionary(grouping: expenses) { Calendar.current.startOfDay(for: $0.date) }
        return groups
            .sorted { $0.key > $1.key }
            .map { (day: $0.key, expenses: $0.value) }
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            quickAddRow

            if expenses.isEmpty {
                ContentUnavailableView(
                    "No Expenses",
                    systemImage: "creditcard",
                    description: Text("Add your first expense above.")
                )
            } else {
                List {
                    ForEach(dayGroups, id: \.day) { group in
                        Section {
                            ForEach(group.expenses) { expense in
                                ExpenseRowView(expense: expense)
                                    .contentShape(Rectangle())
                                    .onTapGesture { expenseToEdit = expense }
                            }
                            .onDelete { offsets in
                                listViewModel.delete(at: offsets, from: group.expenses)
                            }
                        } header: {
                            HStack {
                                Text(group.day, format: .dateTime.year().month().day())
                                Spacer()
                                Text(listViewModel.total(of: group.expenses), format: .currency(code: currencyCode))
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .sheet(item: $expenseToEdit) { expense in
            AddEditExpenseView(editing: expense)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Expenses")
                .font(.largeTitle.bold())
            Text("Today: \(todayTotal, format: .currency(code: currencyCode))")
                .font(.headline)
                .foregroundStyle(.green)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }

    private var quickAddRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                TextField("Amount", text: $quickAddViewModel.amountText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 90)

                TextField("Description", text: $quickAddViewModel.title)
                    .textFieldStyle(.roundedBorder)

                Menu(quickAddViewModel.category.displayName) {
                    ForEach(ExpenseCategory.allCases) { category in
                        Button(category.displayName) { quickAddViewModel.category = category }
                    }
                }
                .font(.subheadline)

                Button("Add", action: addQuickExpense)
                    .buttonStyle(.borderedProminent)
            }

            if let quickAddError {
                Text(quickAddError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private var currencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }

    private func addQuickExpense() {
        do {
            let expense = try quickAddViewModel.makeExpense()
            modelContext.insert(expense)
            quickAddViewModel = ExpenseFormViewModel()
            quickAddError = nil
        } catch {
            quickAddError = error.localizedDescription
        }
    }
}

#Preview {
    ExpenseListView()
        .modelContainer(for: Expense.self, inMemory: true)
}
