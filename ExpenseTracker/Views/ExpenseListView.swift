import SwiftUI
import SwiftData

struct ExpenseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]

    @State private var isPresentingAdd = false
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

    private var currencyCode: String {
        AppCurrency.code
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
                            EmptyView()
                        } header: {
                            Text("Today: \(todayTotal, format: .currency(code: currencyCode))")
                                .font(.headline)
                                .foregroundStyle(.green)
                                .textCase(nil)
                        }

                        ForEach(dayGroups, id: \.day) { group in
                            Section {
                                ForEach(group.expenses) { expense in
                                    Button {
                                        expenseToEdit = expense
                                    } label: {
                                        ExpenseRowView(expense: expense)
                                    }
                                    .buttonStyle(.plain)
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
                }
            }
            .navigationTitle("Expenses")
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        isPresentingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $isPresentingAdd) {
            AddEditExpenseView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $expenseToEdit) { expense in
            AddEditExpenseView(editing: expense)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    ExpenseListView()
        .modelContainer(for: Expense.self, inMemory: true)
}
