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

This repo doesn't check in an `.xcodeproj` (generated files are noisy in git diffs).
Instead it uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate one from `project.yml`:

```bash
brew install xcodegen
cd ExpenseTracker   # repo root, where project.yml lives
xcodegen generate
open ExpenseTracker.xcodeproj
```

Then build & run on an iOS 17+ simulator.

## Current features

- Add, edit, delete expenses (title, amount, category, date, optional note)
- List sorted by date, with running total
- Empty state

## Roadmap

- Unit tests for `ExpenseFormViewModel` (validation) and `ExpenseListViewModel`
- Budgets per category
- Monthly summary / charts
- Recurring expenses
