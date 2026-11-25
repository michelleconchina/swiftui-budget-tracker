import Foundation
import FirebaseFirestore

private enum AppUser {
    static let id = "7f3a9c2e-4b81-4f6d-9a02-e15c8d7b3f41"
}

/// Which set of expenses is shown: the everyday log, or a separate trip log
/// kept in its own collection so it doesn't mix into the regular totals.
enum Ledger: String, CaseIterable, Identifiable {
    case main
    case thailand

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .main: return "Everyday"
        case .thailand: return "Thailand Trip"
        }
    }

    var currencyCode: String {
        switch self {
        case .main: return AppCurrency.code
        case .thailand: return "THB"
        }
    }

    var systemImage: String {
        switch self {
        case .main: return "house"
        case .thailand: return "airplane"
        }
    }
}

@Observable
final class ExpenseStore {
    private static let ledgerKey = "selectedLedger"

    private(set) var expenses: [Expense] = []
    private(set) var isLoading = true
    private var listener: ListenerRegistration?

    /// Switching ledgers re-subscribes to the other collection.
    var ledger: Ledger {
        didSet {
            guard ledger != oldValue else { return }
            UserDefaults.standard.set(ledger.rawValue, forKey: Self.ledgerKey)
            if listener != nil { start() }
        }
    }

    var currencyCode: String { ledger.currencyCode }

    /// Pass a ledger to pin it (e.g. intents always log to `.main`);
    /// otherwise the last ledger picked in the app is used.
    init(ledger: Ledger? = nil) {
        self.ledger = ledger
            ?? UserDefaults.standard.string(forKey: Self.ledgerKey).flatMap(Ledger.init(rawValue:))
            ?? .main
    }

    private var db: Firestore { Firestore.firestore() }

    private var collection: CollectionReference {
        let user = db.collection("users").document(AppUser.id)
        switch ledger {
        case .main:
            return user.collection("expenses")
        case .thailand:
            return user.collection("trips").document("thailand").collection("expenses")
        }
    }

    func start() {
        stop()
        isLoading = true
        listener = collection
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self, let snapshot else { return }
                self.expenses = snapshot.documents.compactMap { try? $0.data(as: Expense.self) }
                self.isLoading = false
            }
    }

    func stop() {
        listener?.remove()
        listener = nil
        expenses = []
        isLoading = true
    }

    func add(_ expense: Expense) throws {
        _ = try collection.addDocument(from: expense)
    }

    func update(_ expense: Expense) throws {
        guard let id = expense.id else { return }
        try collection.document(id).setData(from: expense)
    }

    func delete(_ expenses: [Expense]) async throws {
        for expense in expenses {
            guard let id = expense.id else { continue }
            try await collection.document(id).delete()
        }
    }

    func total(of expenses: [Expense]) -> Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
}
