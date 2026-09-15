import SwiftUI
import FirebaseCore

@main
struct ExpenseTrackerApp: App {
    @State private var store = ExpenseStore()

    init() {
        FirebaseApp.configure()
    }

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
            .environment(store)
            .onAppear { store.start() }
        }
    }
}
