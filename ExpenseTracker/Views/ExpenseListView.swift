import SwiftUI

struct ExpenseListView: View {
    @Environment(ExpenseStore.self) private var store

    @State private var isPresentingAdd = false
    @State private var expenseToEdit: Expense?
    @State private var searchText = ""
    @State private var selectedCategory: ExpenseCategory?
    @State private var pendingDelete: PendingDelete?
    @State private var toastMessage: String?
    @State private var isRepeatBarDismissed = false

    private struct PendingDelete {
        let expense: Expense
        let task: Task<Void, Never>
    }

    private var expenses: [Expense] {
        store.expenses.filter { $0.id != pendingDelete?.expense.id }
    }

    private var lastCommuteExpense: Expense? {
        store.expenses.first { $0.category == .commute }
    }

    /// The commute expense (title + amount) repeated most often in the last 7 days,
    /// falling back to the single most recent commute if nothing repeats this week.
    private var suggestedCommuteExpense: Expense? {
        let calendar = Calendar.current
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: .now) else {
            return lastCommuteExpense
        }

        let recentCommutes = store.expenses.filter { $0.category == .commute && $0.date >= weekAgo }
        guard !recentCommutes.isEmpty else { return lastCommuteExpense }

        struct Key: Hashable {
            let title: String
            let amount: Double
        }

        let grouped = Dictionary(grouping: recentCommutes) { Key(title: $0.title, amount: $0.amount) }
        let mostFrequent = grouped.values.max { lhs, rhs in
            if lhs.count != rhs.count {
                return lhs.count < rhs.count
            }
            let lhsLatest = lhs.map(\.date).max() ?? .distantPast
            let rhsLatest = rhs.map(\.date).max() ?? .distantPast
            return lhsLatest < rhsLatest
        }

        return mostFrequent?.max { $0.date < $1.date }
    }

    private func isAlreadyLoggedToday(_ expense: Expense) -> Bool {
        store.expenses.contains { candidate in
            Calendar.current.isDateInToday(candidate.date)
                && candidate.category == .commute
                && candidate.title == expense.title
                && candidate.amount == expense.amount
        }
    }

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
                if store.isLoading {
                    ProgressView()
                } else if filteredExpenses.isEmpty {
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
                                            scheduleDelete(expense)
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
                                    Text(group.day, format: .dateTime.weekday(.wide).month().day().year())
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
        .safeAreaInset(edge: .bottom) {
            if pendingDelete == nil, toastMessage == nil, !isRepeatBarDismissed,
               let suggestedCommuteExpense, !isAlreadyLoggedToday(suggestedCommuteExpense) {
                RepeatCommuteBar(
                    expense: suggestedCommuteExpense,
                    currencyCode: currencyCode,
                    action: { repeatCommute(suggestedCommuteExpense) },
                    onDismiss: { isRepeatBarDismissed = true }
                )
            }
        }
        .overlay(alignment: .bottom) {
            if let pendingDelete {
                UndoBanner(title: pendingDelete.expense.title, onUndo: undoDelete)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else if let toastMessage {
                ToastBanner(message: toastMessage)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.snappy(duration: 0.25), value: pendingDelete?.expense.id)
        .animation(.snappy(duration: 0.25), value: toastMessage)
    }

    private func scheduleDelete(_ expense: Expense) {
        if let existing = pendingDelete {
            existing.task.cancel()
            store.delete([existing.expense])
        }
        let task = Task {
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                store.delete([expense])
                pendingDelete = nil
            }
        }
        pendingDelete = PendingDelete(expense: expense, task: task)
    }

    private func undoDelete() {
        pendingDelete?.task.cancel()
        pendingDelete = nil
    }

    private func repeatCommute(_ last: Expense) {
        let expense = Expense(title: last.title, amount: last.amount, category: .commute)
        do {
            try store.add(expense)
            isRepeatBarDismissed = true
            showToast("Logged \(expense.amount.formatted(.currency(code: currencyCode))) for Commute")
        } catch {
            showToast("Couldn't log commute. Try again.")
        }
    }

    private func showToast(_ message: String) {
        toastMessage = message
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            await MainActor.run {
                if toastMessage == message {
                    toastMessage = nil
                }
            }
        }
    }
}

private struct RepeatCommuteBar: View {
    let expense: Expense
    let currencyCode: String
    let action: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: action) {
                HStack(spacing: 14) {
                    Image(systemName: ExpenseCategory.commute.systemImage)
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(ExpenseCategory.commute.color, in: Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Repeat Commute")
                            .font(.headline)
                        Text(expense.amount, format: .currency(code: currencyCode))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Repeat commute, \(expense.amount.formatted(.currency(code: currencyCode)))")
            .accessibilityHint("Adds a new commute expense dated today")

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss repeat commute suggestion")
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal)
        .padding(.bottom, 4)
    }
}

private struct UndoBanner: View {
    let title: String
    let onUndo: () -> Void

    var body: some View {
        HStack {
            Text("Deleted \"\(title)\"")
                .font(.subheadline)
                .lineLimit(1)
            Spacer()
            Button("Undo", action: onUndo)
                .font(.subheadline.weight(.semibold))
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

private struct ToastBanner: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.subheadline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    ExpenseListView()
        .environment(ExpenseStore())
}
