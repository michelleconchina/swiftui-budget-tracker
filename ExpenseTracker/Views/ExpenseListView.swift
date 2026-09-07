import SwiftUI
import SwiftData

struct ExpenseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]

    @State private var isPresentingAddExpense = false
    @State private var expenseToEdit: Expense?

    private var listViewModel: ExpenseListViewModel {
        ExpenseListViewModel(modelContext: modelContext)
    }

    var body: some View {
        NavigationStack {
            Group {
                if expenses.isEmpty {
                    ContentUnavailableView(
                        "No Expenses",
                        systemImage: "creditcard",
                        description: Text("Tap + to add your first expense.")
                    )
                } else {
                    List {
                        Section {
                            ForEach(expenses) { expense in
                                ExpenseRowView(expense: expense)
                                    .contentShape(Rectangle())
                                    .onTapGesture { expenseToEdit = expense }
                            }
                            .onDelete { offsets in
                                listViewModel.delete(at: offsets, from: expenses)
                            }
                        } footer: {
                            Text("Total: \(listViewModel.total(of: expenses).formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")))")
                        }
                    }
                }
            }
            .navigationTitle("Expenses")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingAddExpense = true
                    } label: {
                        Label("Add Expense", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingAddExpense) {
                AddEditExpenseView()
            }
            .sheet(item: $expenseToEdit) { expense in
                AddEditExpenseView(editing: expense)
            }
        }
    }
}

#Preview {
    ExpenseListView()
        .modelContainer(for: Expense.self, inMemory: true)
}
