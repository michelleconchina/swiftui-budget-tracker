import Foundation
import FirebaseFirestore

struct Expense: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var title: String
    var amount: Double
    var category: ExpenseCategory
    var date: Date
    var note: String?

    init(
        id: String? = nil,
        title: String,
        amount: Double,
        category: ExpenseCategory,
        date: Date = .now,
        note: String? = nil
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.category = category
        self.date = date
        self.note = note
    }
}
