import SwiftUI

struct AddEditExpenseView: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var formViewModel: ExpenseFormViewModel
    @State private var formError: ExpenseFormError?
    @State private var saveErrorMessage: String?
    @FocusState private var focusedField: Field?

    private let expenseToEdit: Expense?

    private enum Field {
        case title, amount
    }

    init(editing expense: Expense? = nil) {
        self.expenseToEdit = expense
        _formViewModel = State(initialValue: ExpenseFormViewModel(editing: expense))
    }

    var body: some View {
        NavigationStack {
            Form {
                if let formError {
                    Section {
                        Label(formError.errorDescription ?? "Something went wrong.", systemImage: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.red)
                            .listRowBackground(Color.red.opacity(0.12))
                    }
                }

                if let saveErrorMessage {
                    Section {
                        Label(saveErrorMessage, systemImage: "wifi.exclamationmark")
                            .font(.subheadline)
                            .foregroundStyle(.red)
                            .listRowBackground(Color.red.opacity(0.12))
                    }
                }

                Section("Details") {
                    HStack(spacing: 12) {
                        Image(systemName: "text.alignleft")
                            .foregroundStyle(.secondary)
                            .frame(width: 20)
                        TextField("Title", text: $formViewModel.title)
                            .focused($focusedField, equals: .title)
                            .fieldErrorStyle(isInvalid: formError == .emptyTitle)
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "banknote")
                            .foregroundStyle(.secondary)
                            .frame(width: 20)
                        TextField("Amount", text: $formViewModel.amountText)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .amount)
                            .fieldErrorStyle(isInvalid: formError == .invalidAmount)
                    }

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
            .onChange(of: formViewModel.title) { formError = nil }
            .onChange(of: formViewModel.amountText) { formError = nil }
        }
    }

    private func save() {
        formError = nil
        saveErrorMessage = nil
        do {
            if let expenseToEdit {
                let updated = try formViewModel.makeUpdatedExpense(from: expenseToEdit)
                try store.update(updated)
            } else {
                let expense = try formViewModel.makeExpense()
                try store.add(expense)
            }
            dismiss()
        } catch let error as ExpenseFormError {
            formError = error
            focusedField = error == .emptyTitle ? .title : .amount
        } catch {
            saveErrorMessage = "Couldn't save this expense. Check your connection and try again."
        }
    }
}

private extension View {
    @ViewBuilder
    func fieldErrorStyle(isInvalid: Bool) -> some View {
        if isInvalid {
            self.foregroundStyle(.red)
        } else {
            self
        }
    }
}

#Preview {
    AddEditExpenseView()
        .environment(ExpenseStore())
}
