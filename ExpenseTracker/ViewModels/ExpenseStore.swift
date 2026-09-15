import Foundation
import FirebaseFirestore

private enum AppUser {
    static let id = "7f3a9c2e-4b81-4f6d-9a02-e15c8d7b3f41"
}

@Observable
final class ExpenseStore {
    private(set) var expenses: [Expense] = []
    private var listener: ListenerRegistration?

    private var db: Firestore { Firestore.firestore() }

    private var collection: CollectionReference {
        db.collection("users").document(AppUser.id).collection("expenses")
    }

    func start() {
        stop()
        listener = collection
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self, let snapshot else { return }
                self.expenses = snapshot.documents.compactMap { try? $0.data(as: Expense.self) }
            }
    }

    func stop() {
        listener?.remove()
        listener = nil
        expenses = []
    }

    func add(_ expense: Expense) throws {
        _ = try collection.addDocument(from: expense)
    }

    func update(_ expense: Expense) throws {
        guard let id = expense.id else { return }
        try collection.document(id).setData(from: expense)
    }

    func delete(_ expenses: [Expense]) {
        for expense in expenses {
            guard let id = expense.id else { continue }
            collection.document(id).delete()
        }
    }

    func total(of expenses: [Expense]) -> Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
}
