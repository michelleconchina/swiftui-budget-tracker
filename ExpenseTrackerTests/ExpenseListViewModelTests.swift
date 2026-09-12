import XCTest
import SwiftData
@testable import ExpenseTracker

final class ExpenseListViewModelTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        let schema = Schema([Expense.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [configuration])
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
    }

    func test_total_sumsAmounts() {
        let sut = ExpenseListViewModel(modelContext: context)
        let expenses = [
            Expense(title: "A", amount: 10, category: .food),
            Expense(title: "B", amount: 5.5, category: .transport)
        ]

        XCTAssertEqual(sut.total(of: expenses), 15.5)
    }

    func test_total_ofEmptyList_isZero() {
        let sut = ExpenseListViewModel(modelContext: context)

        XCTAssertEqual(sut.total(of: []), 0)
    }

    func test_delete_removesExpensesFromContext() throws {
        let keep = Expense(title: "Keep", amount: 1, category: .other)
        let remove = Expense(title: "Remove", amount: 2, category: .other)
        context.insert(keep)
        context.insert(remove)

        let sut = ExpenseListViewModel(modelContext: context)
        sut.delete([remove])

        let remaining = try context.fetch(FetchDescriptor<Expense>())
        XCTAssertEqual(remaining.map(\.title), ["Keep"])
    }

    func test_deleteAtOffsets_removesMatchingExpenses() throws {
        let first = Expense(title: "First", amount: 1, category: .other)
        let second = Expense(title: "Second", amount: 2, category: .other)
        let third = Expense(title: "Third", amount: 3, category: .other)
        [first, second, third].forEach(context.insert)

        let sut = ExpenseListViewModel(modelContext: context)
        sut.delete(at: IndexSet(integer: 1), from: [first, second, third])

        let remaining = try context.fetch(FetchDescriptor<Expense>())
        XCTAssertEqual(Set(remaining.map(\.title)), ["First", "Third"])
    }
}
