# Expense Tracker

A SwiftUI + SwiftData expense tracker, structured with MVVM. iOS 17+.

## Structure

```
ExpenseTracker/
  ExpenseTrackerApp.swift        App entry point, sets up the SwiftData container
  Models/
    Expense.swift                @Model persisted entity
    ExpenseCategory.swift        Category enum
  ViewModels/
    ExpenseFormViewModel.swift   Add/edit form state + validation (unit-testable, no SwiftData dependency)
    ExpenseListViewModel.swift   List-level operations (delete, totals)
  Views/
    ExpenseListView.swift        Main list, uses @Query for live SwiftData results
    AddEditExpenseView.swift     Add/edit form sheet
    Components/
      ExpenseRowView.swift
```

## Opening in Xcode

1. Clone the repo.
2. Open `ExpenseTracker.xcodeproj` (double-click it, or `open ExpenseTracker.xcodeproj`).
3. Pick an iOS 17+ simulator (or a device) and hit Run (⌘R).

No extra tooling required — the project file is checked in directly.

## Current features

- Add, edit, delete expenses (title, amount, category, date, optional note)
- List sorted by date, with running total
- Empty state

## Roadmap

- Unit tests for `ExpenseFormViewModel` (validation) and `ExpenseListViewModel`
- Budgets per category
- Monthly summary / charts
- Recurring expenses
