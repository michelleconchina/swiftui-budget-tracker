import Foundation

enum ExpenseCategory: String, Codable, CaseIterable, Identifiable {
    case food
    case transport
    case shopping
    case entertainment
    case bills
    case health
    case other

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var systemImage: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "car.fill"
        case .shopping: return "bag.fill"
        case .entertainment: return "film.fill"
        case .bills: return "doc.text.fill"
        case .health: return "heart.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}
