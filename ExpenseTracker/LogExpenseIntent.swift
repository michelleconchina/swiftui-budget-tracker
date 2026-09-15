import AppIntents
import FirebaseCore

struct LogExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Expense"
    static var description = IntentDescription("Log a new expense in Expense Tracker.")

    @Parameter(title: "Amount")
    var amount: Double

    @Parameter(title: "Category")
    var category: ExpenseCategory

    @Parameter(title: "Title", default: "")
    var expenseTitle: String

    static var parameterSummary: some ParameterSummary {
        Summary("Log ₱\(\.$amount) for \(\.$category)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        let title = expenseTitle.isEmpty ? category.displayName : expenseTitle
        let expense = Expense(title: title, amount: amount, category: category)

        let store = ExpenseStore()
        try store.add(expense)

        return .result(dialog: "Logged ₱\(amount.formatted()) for \(category.displayName).")
    }
}

struct ExpenseTrackerShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogExpenseIntent(),
            phrases: [
                "Log an expense in \(.applicationName)",
                "Add an expense to \(.applicationName)"
            ],
            shortTitle: "Log Expense",
            systemImageName: "plus.circle"
        )
    }
}
