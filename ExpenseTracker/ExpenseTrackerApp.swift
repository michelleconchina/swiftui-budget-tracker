import SwiftUI
import SwiftData

@main
struct ExpenseTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                ExpenseListView()
                    .tabItem {
                        Label("Expenses", systemImage: "list.bullet")
                    }
                SummaryView()
                    .tabItem {
                        Label("Summary", systemImage: "chart.pie")
                    }
            }
        }
        .modelContainer(for: Expense.self)
    }
}
