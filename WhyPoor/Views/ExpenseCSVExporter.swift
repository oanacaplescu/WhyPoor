import Foundation

enum ExpenseCSVExporter {
    static func generateCSV(expenses: [Expense]) -> String {
        var rows = ["Date,Category,Amount,Description"]

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let sorted = expenses.sorted { $0.date > $1.date }

        for expense in sorted {
            let date = formatter.string(from: expense.date)
            let category = escape(expense.category)
            let amount = NSDecimalNumber(decimal: expense.amount).stringValue
            let description = escape(expense.expenseDescription ?? "")
            rows.append("\(date),\(category),\(amount),\(description)")
        }

        return rows.joined(separator: "\n")
    }

    /// Wraps a field in quotes and escapes internal quotes if it contains a comma, quote, or newline.
    private static func escape(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }

    /// Writes the CSV to a temporary file and returns its URL, ready to share.
    static func writeToTempFile(expenses: [Expense]) -> URL? {
        let csv = generateCSV(expenses: expenses)
        let fileName = "iWallet-Export-\(Int(Date().timeIntervalSince1970)).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            print("⚠️ Failed to write CSV: \(error)")
            return nil
        }
    }
}
