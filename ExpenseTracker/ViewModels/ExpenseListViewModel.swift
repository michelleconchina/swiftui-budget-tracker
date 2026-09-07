import Foundation
import Observation
import SwiftData

/// Thin wrapper around ModelContext for list-level operations (delete, totals),
/// kept separate from SwiftUI's @Query so the intent (why/what) stays testable
/// even though @Query itself needs a live context to exercise in tests.
@Observable
final class ExpenseListViewModel {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func delete(_ expenses: [Expense]) {
        for expense in expenses {
            modelContext.delete(expense)
        }
    }

    func delete(at offsets: IndexSet, from expenses: [Expense]) {
        delete(offsets.map { expenses[$0] })
    }

    func total(of expenses: [Expense]) -> Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
}
