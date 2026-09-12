import SwiftUI
import FirebaseCore
import FirebaseAuth

@main
struct ExpenseTrackerApp: App {
    @State private var store = ExpenseStore()
    @State private var isSignedIn: Bool

    init() {
        FirebaseApp.configure()
        _isSignedIn = State(initialValue: Auth.auth().currentUser != nil)
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if isSignedIn {
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
                } else {
                    SignInView {
                        isSignedIn = true
                        store.start()
                    }
                }
            }
        }
    }
}
