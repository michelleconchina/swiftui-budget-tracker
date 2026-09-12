import Foundation
import FirebaseFirestore
import FirebaseAuth

@Observable
final class ExpenseStore {
    private(set) var expenses: [Expense] = []
    private var listener: ListenerRegistration?

    private var db: Firestore { Firestore.firestore() }

    private var collection: CollectionReference? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        return db.collection("users").document(uid).collection("expenses")
    }

    func start() {
        stop()
        guard let collection else { return }
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
        guard let collection else { return }
        _ = try collection.addDocument(from: expense)
    }

    func update(_ expense: Expense) throws {
        guard let collection, let id = expense.id else { return }
        try collection.document(id).setData(from: expense)
    }

    func delete(_ expenses: [Expense]) {
        guard let collection else { return }
        for expense in expenses {
            guard let id = expense.id else { continue }
            collection.document(id).delete()
        }
    }

    func total(of expenses: [Expense]) -> Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
}
