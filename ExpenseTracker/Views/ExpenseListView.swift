import SwiftUI

struct ExpenseListView: View {
    @Environment(ExpenseStore.self) private var store

    @State private var isPresentingAdd = false
    @State private var expenseToEdit: Expense?
    @State private var searchText = ""
    @State private var selectedCategory: ExpenseCategory?

    private var expenses: [Expense] { store.expenses }

    private var todayTotal: Double {
        store.total(of: expenses.filter { Calendar.current.isDateInToday($0.date) })
    }

    private var isFiltering: Bool {
        !searchText.isEmpty || selectedCategory != nil
    }

    private var filteredExpenses: [Expense] {
        expenses.filter { expense in
            let matchesCategory = selectedCategory == nil || expense.category == selectedCategory
            let matchesSearch = searchText.isEmpty
                || expense.title.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }

    private var dayGroups: [(day: Date, expenses: [Expense])] {
        let groups = Dictionary(grouping: filteredExpenses) { Calendar.current.startOfDay(for: $0.date) }
        return groups
            .sorted { $0.key > $1.key }
            .map { (day: $0.key, expenses: $0.value) }
    }

    private var currencyCode: String {
        AppCurrency.code
    }

    private static let csvDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private var csvExportURL: URL? {
        var csv = "Date,Title,Category,Amount\n"
        for expense in filteredExpenses.sorted(by: { $0.date < $1.date }) {
            let dateString = Self.csvDateFormatter.string(from: expense.date)
            let escapedTitle = expense.title.replacingOccurrences(of: "\"", with: "\"\"")
            let amountString = String(format: "%.2f", expense.amount)
            csv += "\(dateString),\"\(escapedTitle)\",\(expense.category.displayName),\(amountString)\n"
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Expenses.csv")
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredExpenses.isEmpty {
                    ContentUnavailableView(
                        expenses.isEmpty ? "No Expenses" : "No Matching Expenses",
                        systemImage: expenses.isEmpty ? "creditcard" : "magnifyingglass",
                        description: Text(expenses.isEmpty ? "Tap + to add your first expense." : "Try a different search or category.")
                    )
                } else {
                    List {
                        Section {
                            EmptyView()
                        } header: {
                            if isFiltering {
                                Label("Filter active — showing \(filteredExpenses.count) of \(expenses.count)", systemImage: "line.3.horizontal.decrease.circle.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .textCase(nil)
                            } else {
                                Text("Today: \(todayTotal, format: .currency(code: currencyCode))")
                                    .font(.headline)
                                    .foregroundStyle(.green)
                                    .textCase(nil)
                            }
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
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            store.delete([expense])
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }

                                        Button {
                                            expenseToEdit = expense
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        .tint(.blue)
                                    }
                                }
                            } header: {
                                HStack {
                                    Text(group.day, format: .dateTime.year().month().day())
                                    Spacer()
                                    Text(store.total(of: group.expenses), format: .currency(code: currencyCode))
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Expenses")
            .searchable(text: $searchText, prompt: "Search expenses")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button {
                            selectedCategory = nil
                        } label: {
                            if selectedCategory == nil {
                                Label("All Categories", systemImage: "checkmark")
                            } else {
                                Text("All Categories")
                            }
                        }
                        Divider()
                        ForEach(ExpenseCategory.allCases) { category in
                            Button {
                                selectedCategory = category
                            } label: {
                                if selectedCategory == category {
                                    Label(category.displayName, systemImage: "checkmark")
                                } else {
                                    Text(category.displayName)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: selectedCategory == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                    }
                    .accessibilityLabel(selectedCategory == nil ? "Filter by category" : "Filtering by \(selectedCategory!.displayName)")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if let csvExportURL {
                        ShareLink(item: csvExportURL) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .accessibilityLabel("Export as CSV")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Expense")
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
        .environment(ExpenseStore())
}
