import SwiftUI

enum ExpenseCategory: String, Codable, CaseIterable, Identifiable {
    case food
    case commute
    case shopping
    case other

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var systemImage: String {
        switch self {
        case .food: return "fork.knife"
        case .commute: return "car.fill"
        case .shopping: return "bag.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .food: return .orange
        case .commute: return .blue
        case .shopping: return .pink
        case .other: return .gray
        }
    }

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = ExpenseCategory(rawValue: raw) ?? .other
    }
}

import AppIntents

extension ExpenseCategory: AppEnum {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Expense Category"
    static var caseDisplayRepresentations: [ExpenseCategory: DisplayRepresentation] = [
        .food: "Food",
        .commute: "Commute",
        .shopping: "Shopping",
        .other: "Other"
    ]
}
