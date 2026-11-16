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

/// Logs an expense from the text of a card purchase alert (e.g. a bank SMS),
/// so a Shortcuts "Message" automation can pass incoming alerts straight in.
struct LogExpenseFromMessageIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Expense from Message"
    static var description = IntentDescription("Reads a card purchase alert and logs it as an expense. Messages that aren't purchases are skipped.")

    @Parameter(title: "Message")
    var message: String

    @Parameter(title: "Category", default: .other)
    var category: ExpenseCategory

    static var parameterSummary: some ParameterSummary {
        Summary("Log expense from \(\.$message)") {
            \.$category
        }
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let purchase = TransactionMessageParser.parse(message) else {
            return .result(dialog: "Not a purchase alert. Nothing logged.")
        }

        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        let title = purchase.merchant ?? category.displayName
        let expense = Expense(
            title: title,
            amount: purchase.amount,
            category: category,
            note: message.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        let store = ExpenseStore()
        try store.add(expense)

        return .result(dialog: "Logged ₱\(purchase.amount.formatted()) for \(title).")
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
        AppShortcut(
            intent: LogExpenseFromMessageIntent(),
            phrases: [
                "Log an expense from a message in \(.applicationName)"
            ],
            shortTitle: "Log from Message",
            systemImageName: "message"
        )
    }
}
