import SwiftData
import Foundation

@Model
final class Expense {
    var amount: Decimal
    var category: String
    var expenseDescription: String?
    var date: Date

    init(amount: Decimal, category: String, expenseDescription: String? = nil, date: Date = .now) {
        self.amount = amount
        self.category = category
        self.expenseDescription = expenseDescription
        self.date = date
    }
}
