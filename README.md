# Expense Tracker

A SwiftUI expense tracker for logging daily/commute expenses, synced across devices via Firestore. iOS 17+, MVVM.

## Structure

```
ExpenseTracker/
  ExpenseTrackerApp.swift          App entry point: configures Firebase, launches straight into the TabView (no sign-in)
  AppCurrency.swift                Hardcoded currency code (PHP)
  GoogleService-Info.plist         Firebase project config (not a secret credential by itself - see Firestore rules below)
  Models/
    Expense.swift                  Codable struct, mapped to/from Firestore documents (@DocumentID for the doc id)
    ExpenseCategory.swift          Category enum
  ViewModels/
    ExpenseFormViewModel.swift     Add/edit form state + validation (unit-testable, no Firestore dependency)
    ExpenseStore.swift             Live Firestore listener + add/update/delete/total, shared via @Environment
  Views/
    ExpenseListView.swift          Main list: search, category filter, swipe actions, CSV export, day grouping
    AddEditExpenseView.swift       Add/edit form sheet, presented as a bottom sheet
    SummaryView.swift              Monthly total + category breakdown (Swift Charts donut)
    Components/
      ExpenseRowView.swift
```

## Data & sync

Expenses live in Firestore under `users/<fixed-id>/expenses`, where `<fixed-id>` is a constant baked into `ExpenseStore.swift` (not a real user account) — there's no sign-in screen. Since every device runs the same app build, they all resolve to the same path automatically, so installing the app on another device and running it is the entire "sync setup."

This means the fixed id is the only thing standing between your data and anyone else's request — Firestore's security rules enforce that a write/read must specify that exact id:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/expenses/{expenseId} {
      allow read, write: if userId == "<the fixed id from ExpenseStore.swift>";
    }
  }
}
```

Set in Firebase console → Firestore Database → Rules. This is intentionally simpler than real authentication — appropriate for a single-person personal tool, not a multi-user app.

## Setup

1. Create a Firebase project (console.firebase.google.com), enable **Firestore Database**, and set the rule above.
2. Download `GoogleService-Info.plist` for an iOS app registered with bundle id `com.michelleconchina.ExpenseTracker`, and place it at `ExpenseTracker/GoogleService-Info.plist`.
3. Open `ExpenseTracker.xcodeproj` in Xcode — first open resolves the Firebase SPM package (Firestore only).
4. Run (⌘R) on a simulator or device.

## Running without a paid Apple Developer account

Free-tier signing certificates expire after 7 days — after that the app just won't launch until re-signed. `redeploy.sh` in the repo root builds, installs, and launches the app on a connected device from the command line in one step (fill in your device id first, via `xcrun devicectl list devices`), which resets that clock without opening Xcode's UI each time.

## Current features

- Add, edit, delete expenses (title, amount, category, date, optional note), synced across devices via Firestore
- Search and filter by category
- Swipe-to-edit / swipe-to-delete
- CSV export (respects the active search/filter) via the share sheet
- Monthly summary: total + category breakdown chart
- PHP currency throughout
- VoiceOver labels, Dynamic Type-safe amount/title text, Dark Mode-safe colors
- Unit tests for `ExpenseFormViewModel` (validation logic)

## Notes on scope

Budgets, recurring expenses, and multi-user accounts were considered and deliberately left out — this is a single-person daily-log tool, not a shared budgeting app. A home screen widget or Shortcuts/Siri integration for near-instant logging is the most likely next addition if this keeps getting used daily.
