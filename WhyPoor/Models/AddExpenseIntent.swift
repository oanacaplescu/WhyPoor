import AppIntents
import SwiftData
import Foundation

struct AddExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Expense"
    static var description = IntentDescription("Add a new expense to iWallet.")

    @Parameter(title: "Amount")
    var amountText: String

    @Parameter(title: "Category")
    var category: CategoryEntity

    @Parameter(title: "Date")
    var date: Date?

    @Parameter(title: "Note", default: nil)
    var note: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$amountText) expense for \(\.$category) on \(\.$date)") {
            \.$note
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let amount = Self.extractAmount(from: amountText) else {
            throw $amountText.needsValueError("What's the amount? Just say a number, like \"fifty\".")
        }

        let context = ModelContext(SharedModelContainer.container)

        let expenseDate = date ?? .now
        let expense = Expense(
            amount: amount,
            category: category.name,
            expenseDescription: note?.isEmpty == true ? nil : note,
            date: expenseDate
        )
        context.insert(expense)
        try context.save()

        let currencyCode = AppGroup.sharedDefaults.string(forKey: "currencyCode") ?? "USD"
        let amountDouble = NSDecimalNumber(decimal: amount).doubleValue
        let formattedAmount = amountDouble.formatted(.currency(code: currencyCode))

        let dayPhrase: String
        if Calendar.current.isDateInToday(expenseDate) {
            dayPhrase = ""
        } else if Calendar.current.isDateInYesterday(expenseDate) {
            dayPhrase = " for yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            dayPhrase = " for \(formatter.string(from: expenseDate))"
        }

        return .result(dialog: "Added \(formattedAmount) to \(category.name)\(dayPhrase).")
    }

    /// Pulls the first valid decimal number out of whatever Siri heard,
    /// ignoring trailing currency words like "lei" or "dollars".
    private static func extractAmount(from text: String) -> Decimal? {
        let cleaned = text.replacingOccurrences(of: ",", with: ".")
        var numberString = ""
        var seenDecimalPoint = false

        for char in cleaned {
            if char.isNumber {
                numberString.append(char)
            } else if char == ".", !seenDecimalPoint {
                numberString.append(char)
                seenDecimalPoint = true
            } else if !numberString.isEmpty {
                break
            }
        }

        guard !numberString.isEmpty else { return nil }
        return Decimal(string: numberString)
    }
}
