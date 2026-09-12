import XCTest
@testable import ExpenseTracker

final class ExpenseFormViewModelTests: XCTestCase {

    func test_newForm_defaultsToOtherCategoryAndNotEditing() {
        let sut = ExpenseFormViewModel()

        XCTAssertFalse(sut.isEditing)
        XCTAssertEqual(sut.category, .other)
        XCTAssertEqual(sut.title, "")
        XCTAssertEqual(sut.amountText, "")
    }

    func test_editingForm_prefillsFieldsFromExpense() {
        let expense = Expense(title: "Coffee", amount: 100, category: .food, note: "Iced")

        let sut = ExpenseFormViewModel(editing: expense)

        XCTAssertTrue(sut.isEditing)
        XCTAssertEqual(sut.title, "Coffee")
        XCTAssertEqual(sut.amountText, "100.0")
        XCTAssertEqual(sut.category, .food)
        XCTAssertEqual(sut.note, "Iced")
    }

    func test_validate_throwsOnEmptyTitle() {
        let sut = ExpenseFormViewModel()
        sut.title = "   "
        sut.amountText = "10"

        XCTAssertThrowsError(try sut.validate()) { error in
            XCTAssertEqual(error as? ExpenseFormError, .emptyTitle)
        }
    }

    func test_validate_throwsOnNonPositiveAmount() {
        let sut = ExpenseFormViewModel()
        sut.title = "Snacks"
        sut.amountText = "0"

        XCTAssertThrowsError(try sut.validate()) { error in
            XCTAssertEqual(error as? ExpenseFormError, .invalidAmount)
        }
    }

    func test_validate_throwsOnUnparseableAmount() {
        let sut = ExpenseFormViewModel()
        sut.title = "Snacks"
        sut.amountText = "not a number"

        XCTAssertThrowsError(try sut.validate()) { error in
            XCTAssertEqual(error as? ExpenseFormError, .invalidAmount)
        }
    }

    func test_validate_trimsTitleAndNote() throws {
        let sut = ExpenseFormViewModel()
        sut.title = "  Lunch  "
        sut.amountText = "12.5"
        sut.note = "   "

        let fields = try sut.validate()

        XCTAssertEqual(fields.title, "Lunch")
        XCTAssertEqual(fields.amount, 12.5)
        XCTAssertNil(fields.note)
    }

    func test_makeExpense_buildsExpenseFromValidatedFields() throws {
        let sut = ExpenseFormViewModel()
        sut.title = "Groceries"
        sut.amountText = "42.5"
        sut.category = .food

        let expense = try sut.makeExpense()

        XCTAssertEqual(expense.title, "Groceries")
        XCTAssertEqual(expense.amount, 42.5)
        XCTAssertEqual(expense.category, .food)
    }

    func test_makeUpdatedExpense_returnsCopyWithNewFields() throws {
        let original = Expense(id: "abc123", title: "Old Title", amount: 1, category: .other)
        let sut = ExpenseFormViewModel(editing: original)
        sut.title = "New Title"
        sut.amountText = "99"
        sut.category = .transport

        let updated = try sut.makeUpdatedExpense(from: original)

        XCTAssertEqual(updated.id, "abc123")
        XCTAssertEqual(updated.title, "New Title")
        XCTAssertEqual(updated.amount, 99)
        XCTAssertEqual(updated.category, .transport)
    }

    func test_makeUpdatedExpense_throwsWithoutMutatingOriginal() {
        let original = Expense(id: "abc123", title: "Old Title", amount: 1, category: .other)
        let sut = ExpenseFormViewModel(editing: original)
        sut.title = ""

        XCTAssertThrowsError(try sut.makeUpdatedExpense(from: original))
        XCTAssertEqual(original.title, "Old Title")
    }
}
