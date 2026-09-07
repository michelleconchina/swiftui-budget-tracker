import Foundation
import Observation

enum ExpenseFormError: LocalizedError {
    case emptyTitle
    case invalidAmount

    var errorDescription: String? {
        switch self {
        case .emptyTitle: return "Please enter a title."
        case .invalidAmount: return "Please enter an amount greater than zero."
        }
    }
}

/// Owns the editable state for the add/edit expense form and validates it
/// independently of SwiftData, so it can be unit tested without a ModelContext.
@Observable
final class ExpenseFormViewModel {
    var title: String
    var amountText: String
    var category: ExpenseCategory
    var date: Date
    var note: String

    private let editingExpenseID: UUID?

    var isEditing: Bool { editingExpenseID != nil }

    init(editing expense: Expense? = nil) {
        self.editingExpenseID = expense?.id
        self.title = expense?.title ?? ""
        self.amountText = expense.map { String($0.amount) } ?? ""
        self.category = expense?.category ?? .other
        self.date = expense?.date ?? .now
        self.note = expense?.note ?? ""
    }

    func validate() throws -> (title: String, amount: Double, category: ExpenseCategory, date: Date, note: String?) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            throw ExpenseFormError.emptyTitle
        }
        guard let amount = Double(amountText), amount > 0 else {
            throw ExpenseFormError.invalidAmount
        }
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        return (trimmedTitle, amount, category, date, trimmedNote.isEmpty ? nil : trimmedNote)
    }

    /// Applies the validated fields onto an existing expense (edit flow).
    func apply(to expense: Expense) throws {
        let fields = try validate()
        expense.title = fields.title
        expense.amount = fields.amount
        expense.category = fields.category
        expense.date = fields.date
        expense.note = fields.note
    }

    /// Builds a new expense from the validated fields (add flow).
    func makeExpense() throws -> Expense {
        let fields = try validate()
        return Expense(
            title: fields.title,
            amount: fields.amount,
            category: fields.category,
            date: fields.date,
            note: fields.note
        )
    }
}
