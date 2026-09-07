import SwiftUI
import SwiftData

struct AddEditExpenseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var formViewModel: ExpenseFormViewModel
    @State private var errorMessage: String?

    private let expenseToEdit: Expense?

    init(editing expense: Expense? = nil) {
        self.expenseToEdit = expense
        _formViewModel = State(initialValue: ExpenseFormViewModel(editing: expense))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $formViewModel.title)
                    TextField("Amount", text: $formViewModel.amountText)
                        .keyboardType(.decimalPad)
                    Picker("Category", selection: $formViewModel.category) {
                        ForEach(ExpenseCategory.allCases) { category in
                            Label(category.displayName, systemImage: category.systemImage)
                                .tag(category)
                        }
                    }
                    DatePicker("Date", selection: $formViewModel.date, displayedComponents: .date)
                }

                Section("Note") {
                    TextField("Optional note", text: $formViewModel.note, axis: .vertical)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(formViewModel.isEditing ? "Edit Expense" : "Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                }
            }
        }
    }

    private func save() {
        do {
            if let expenseToEdit {
                try formViewModel.apply(to: expenseToEdit)
            } else {
                let expense = try formViewModel.makeExpense()
                modelContext.insert(expense)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    AddEditExpenseView()
        .modelContainer(for: Expense.self, inMemory: true)
}
