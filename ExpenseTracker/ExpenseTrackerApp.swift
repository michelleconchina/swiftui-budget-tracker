import SwiftUI
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

@main
struct ExpenseTrackerApp: App {
    @State private var store = ExpenseStore()
    @State private var isSignedIn: Bool

    init() {
        FirebaseApp.configure()
        if let clientID = FirebaseApp.app()?.options.clientID {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }
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
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
        }
    }
}
