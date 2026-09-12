import Foundation
import Observation

enum ExpenseFormError: LocalizedError, Equatable {
    case emptyTitle
    case invalidAmount

    var errorDescription: String? {
        switch self {
        case .emptyTitle: return "Please enter a title."
        case .invalidAmount: return "Please enter an amount greater than zero."
        }
    }
}

@Observable
final class ExpenseFormViewModel {
    var title: String
    var amountText: String
    var category: ExpenseCategory
    var date: Date
    var note: String

    private let editingExpenseID: String?

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

    func makeUpdatedExpense(from original: Expense) throws -> Expense {
        let fields = try validate()
        var updated = original
        updated.title = fields.title
        updated.amount = fields.amount
        updated.category = fields.category
        updated.date = fields.date
        updated.note = fields.note
        return updated
    }

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
